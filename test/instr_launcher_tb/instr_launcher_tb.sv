/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module instr_launcher_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  import maverickOne_pkg::decoded_instr_t;  // Type for decoded instructions
  import maverickOne_pkg::NUM_REGS;  // Number of registers

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam type locks_t = logic [NUM_REGS-1:0];  // Type for lock signals

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  // RTL Inputs
  logic arst_ni = 1;
  logic clear_i = 0;
  decoded_instr_t instr_in_i;
  logic instr_in_valid_i;
  locks_t locks_i;
  logic instr_out_ready_i;

  // RTL Outputs
  logic instr_in_ready_o;
  decoded_instr_t instr_out_o;
  logic instr_out_valid_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  decoded_instr_t __instr_out__;
  logic instr_mismatch_flag;
  const int NO_max = maverickOne_pkg::NUM_OUTSTANDING + 1;
  decoded_instr_t pipeline_stage[maverickOne_pkg::NUM_OUTSTANDING + 1];
  bit [maverickOne_pkg::NUM_OUTSTANDING:0] instr_validity;
  logic [maverickOne_pkg::NUM_OUTSTANDING:0] instr_wren;
  bit instr_readyness;
  int pipeline_fullness;
  logic pipeline_full;
  logic memory_blocked;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  instr_launcher #() u_instr_lnchr_1 (
      .arst_ni,
      .clk_i,
      .clear_i,
      .instr_in_i,
      .instr_in_valid_i,
      .instr_in_ready_o,
      .locks_i,
      .instr_out_o,
      .instr_out_valid_o,
      .instr_out_ready_i
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_areset();
    result_print((instr_in_ready_o === 'x), "data_in_ready_o X at before reset");
    result_print((instr_out_valid_o === 'x), "data_out_valid_o X at before reset");
    #100ns;
    arst_ni           <= '0;
    clk_i             <= '0;
    clear_i           <= '0;
    locks_i           <= '0;
    instr_in_i        <= '0;
    instr_in_valid_i  <= '0;
    instr_out_ready_i <= '0;
    #100ns;
    result_print((instr_in_ready_o === '0), "data_in_ready_o 0 during reset");
    result_print((instr_out_valid_o === '0), "data_out_valid_o 0 during reset");
    arst_ni <= 1;
    #100ns;
    result_print((instr_in_ready_o === '1), "data_in_ready_o 1 after reset");
    result_print((instr_out_valid_o === '0), "data_out_valid_o 0 after reset");
  endtask

  task automatic start_random_driver();
    fork
      forever begin
        @(posedge clk_i);
        // clear_i <= $urandom_range(0, 99) < 2;  // 2% chance of clear
        clear_i <= '0;  // 2% chance of clear
        instr_in_valid_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
        instr_out_ready_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
        locks_i <= $urandom;  // register locks profile input
        instr_in_i.func <= 1 << $urandom_range(0, maverickOne_pkg::TOTAL_FUNCS - 1);
        instr_in_i.rd <= $urandom_range(0, NUM_REGS - 1);
        instr_in_i.imm <= $urandom_range(0, NUM_REGS - 1);
        instr_in_i.pc <= $urandom_range(0, NUM_REGS - 1);
        instr_in_i.blocking <= $urandom;
        instr_in_i.mem_op <= $urandom & ~instr_in_i.blocking;
        instr_in_i.reg_req <= (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        ));

        // Display Driver Outputs
        $write("[%.3t] Driver time\n", $realtime);
        // // $write("clear_i: 0b%b\n", clear_i);
        // $write("instr_in_i: %p\n", instr_in_i);
        $write("instr_in_valid_i: 0b%b\n", instr_in_valid_i);
        $write("instr_in_ready_o: 0b%b\n", instr_in_ready_o);
        // $write("instr_out_o: %p\n", instr_out_o);
        $write("instr_out_valid_o 0b%b\n", instr_out_valid_o);
        $write("instr_out_ready_i: 0b%b\n", instr_out_ready_i);
        $write("\n");
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    instr_validity = '0;
    instr_readyness = '0;
    instr_wren = '1;
    instr_mismatch_flag = '0;
    pipeline_fullness = 0;
    pipeline_full = '0;
    fork
      forever begin
        @(posedge clk_i);
        memory_blocked = '0;

        $write("[%.3t] Monitor time\n", $realtime);

        if (~arst_ni | clear_i) begin
          // __instr_out__ <= 'x;
          instr_validity <= '0;
          instr_wren <= '1;
        end else if (arst_ni & ~clear_i) begin

          for (int i = NO_max - 1; i >= 0; i--) begin
            $write(
                // "pipeline%02d:\n%p\nreg_req: 0b%b\n", i, pipeline_stage[i], pipeline_stage[i].reg_req
                "pipeline%02d:\treg_req: 0b%0d\tmem_op: 0b%b\tblocking: 0b%b\t", i,
                pipeline_stage[i].reg_req, pipeline_stage[i].mem_op, pipeline_stage[i].blocking);
            $write("writable: 0b%b\n", instr_wren[i]);
          end

          for (int i = NO_max - 1; i >= 0; i--) begin
            if (~instr_wren[i]) begin

              instr_validity[i] = bit'(~|(pipeline_stage[i].reg_req & locks_i));

              if (pipeline_stage[i].blocking) begin

                if (instr_validity[i] && instr_out_ready_i) begin
                  __instr_out__ = pipeline_stage[i];
                  instr_wren[i] = '1;
                  pipeline_fullness--;
                  break;
                end else begin
                  __instr_out__ = pipeline_stage[NO_max-1];
                  if (i < NO_max - 1) begin
                    if (instr_wren[i+1]) begin
                      pipeline_stage[i+1] <= pipeline_stage[i];
                      instr_wren[i+1] <= instr_wren[i];
                      instr_wren[i] = '1;
                    end
                  end
                  locks_i = '1;
                  break;
                end

              end else if (pipeline_stage[i].mem_op) begin

                if (instr_validity[i] && instr_out_ready_i && ~memory_blocked) begin
                  __instr_out__ = pipeline_stage[i];
                  instr_wren[i] = '1;
                  pipeline_fullness--;
                  break;
                end else begin
                  __instr_out__  = pipeline_stage[NO_max-1];
                  memory_blocked = '1;
                  if (i < NO_max - 1) begin
                    if (instr_wren[i+1]) begin
                      pipeline_stage[i+1] <= pipeline_stage[i];
                      instr_wren[i+1] <= instr_wren[i];
                      instr_wren[i] = '1;
                    end
                  end
                  locks_i = (1 << pipeline_stage[i].rd) | locks_i;
                  continue;
                end

              end else if (pipeline_stage[i] !== 'x) begin

                if (instr_validity[i] && instr_out_ready_i) begin
                  __instr_out__ = pipeline_stage[i];
                  instr_wren[i] = '1;
                  pipeline_fullness--;
                  break;
                end else begin
                  __instr_out__ = pipeline_stage[NO_max-1];
                  if (i < NO_max - 1) begin
                    if (instr_wren[i+1]) begin
                      pipeline_stage[i+1] <= pipeline_stage[i];
                      instr_wren[i+1] <= instr_wren[i];
                      instr_wren[i] = '1;
                    end
                  end
                  locks_i = (1 << pipeline_stage[i].rd) | locks_i;
                  continue;
                end

              end

            end
          end

          if (pipeline_fullness == NO_max) pipeline_full = '1;
          else pipeline_full = '0;

          instr_readyness = ~pipeline_full;
          // if (instr_in_valid_i && (instr_in_ready_o && instr_readyness)) begin
          if (instr_in_valid_i && instr_readyness && instr_wren[0]) begin
            pipeline_stage[0] <= instr_in_i;
            instr_wren[0] <= '0;
            pipeline_fullness++;
          end

          if (instr_out_valid_o && instr_out_ready_i && (__instr_out__ !== instr_out_o)) begin
            instr_mismatch_flag = '1;
            $write("[%.3t] Mismatch: 0b%b\n", $realtime, instr_mismatch_flag);
            $write("instr_out_tb : %p\nValid: 0b%b\tmem_op: 0b%b\tblocking: 0b%b\n",
                   __instr_out__.reg_req, instr_validity, __instr_out__.mem_op,
                   __instr_out__.blocking);
            $write("instr_out_rtl: %p\nValid: 0b%b\tmem_op: 0b%b\tblocking: 0b%b\n",
                   instr_out_o.reg_req, instr_out_valid_o, instr_out_o.mem_op,
                   instr_out_o.blocking);
            // $fatal(1, "Mismatch found");
          end

          // $write("instr_out_tb : %p\n", __instr_out__);
          // $write("instr_out_rtl: %p\n", instr_out_o);
          $write("instr_out_tb : %0d\n", __instr_out__.reg_req);
          $write("instr_out_rtl: %0d\n", instr_out_o.reg_req);

        end else if (clear_i) begin
          for (int i = NO_max - 1; i >= 0; i--) begin
            pipeline_stage[i] = 'x;
          end
          pipeline_full = '0;
          instr_wren = '1;
          instr_validity = '1;
        end
        $write("\n");
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    apply_areset();
    start_clk_i();
    start_random_driver();
    start_in_out_monitor();
  end

  initial begin
    repeat (51) @(posedge clk_i);
    result_print(~instr_mismatch_flag, "Expected instruction launched");
    $finish;
  end

  initial begin
    // #1ms;
    repeat (150001) @(posedge clk_i);
    result_print(0, "FATAL TIMEOUT");
    $finish;
  end

endmodule
