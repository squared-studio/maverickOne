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
  logic           arst_ni = 1;
  logic           clear_i = 0;
  decoded_instr_t instr_in_i;
  logic           instr_in_valid_i;
  locks_t         locks_i;
  logic           instr_out_ready_i;

  // RTL Outputs
  logic           instr_in_ready_o;
  decoded_instr_t instr_out_o;
  logic           instr_out_valid_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // event                 locked_register_access_violation;
  // event                 mem_op_priority_violation;
  // event                 blocking_priority_violation;
  // logic           [2:0] violation_flags = '0;
  logic           instr_mismatch_flag;
  decoded_instr_t pipeline_stage                                [$];
  // decoded_instr_t       __instr_in__;
  decoded_instr_t __instr_out__;
  int             NO_max = maverickOne_pkg::NUM_OUTSTANDING + 1;
  logic           memory_blocked;

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
        instr_in_i.mem_op <= $urandom;
        instr_in_i.reg_req <= (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        ));

        $write("[%.3t] Driver time\n", $realtime);
        $write("clear_i: 0b%b\n", clear_i);
        $write("instr_in_valid_i: 0b%b\n", instr_in_valid_i);
        $write("instr_in_ready_o: 0b%b\n", instr_in_ready_o);
        $write("instr_out_ready_i: 0b%b\n", instr_out_ready_i);
        $write("instr_out_valid_o 0b%b\n", instr_out_valid_o);
        $write("locks_i: 0b%b\n", locks_i);
        // $write("instr_in_i.func: 0b%b\n", instr_in_i.func);
        // $write("instr_in_i.rd: 0b%b\n", instr_in_i.rd);
        // $write("instr_in_i.blocking: 0b%b\n", instr_in_i.blocking);
        // $write("instr_in_i.reg_req: 0b%b\n", instr_in_i.reg_req);
        $write("instr_in_i: %p\n", instr_in_i);
        $write("\n");
        $write("instr_out_o: %p\n", instr_out_o);
        $write("\n");
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    instr_mismatch_flag = '0;
    fork
      forever begin
        memory_blocked = '0;
        @(posedge clk_i);

        $write("[%.3t] Monitor time\n", $realtime);

        if (~arst_ni | clear_i) __instr_out__ = '0;
        else if (arst_ni & ~clear_i) begin


          if (__instr_out__ !== instr_out_o) begin
            $write("instr_out_rtl: %p\n", instr_out_o);
            $write("instr_out_tb : %p\n", __instr_out__);
            instr_mismatch_flag = '1;
            $fatal(1, "sata");
          end

          if (instr_in_valid_i &
          instr_in_ready_o &
          (pipeline_stage.size() >= 0) &
          (pipeline_stage.size() < NO_max)) begin
            pipeline_stage.push_back(instr_in_i);
          end

          foreach (pipeline_stage[i])
          $write(
              "pipeline%02d:\n%p\nreg_req: 0b%b\n", i, pipeline_stage[i], pipeline_stage[i].reg_req
          );

          for (int i = 0; i < pipeline_stage.size(); i++) begin

            if (pipeline_stage[i].blocking) begin

              $write("Overlap at %03d: 0b%b\n", i, |(pipeline_stage[i].reg_req & locks_i));
              if (|(pipeline_stage[i].reg_req & locks_i)) begin
                __instr_out__ = 'x;
                break;
              end else if (instr_out_ready_i) begin
                __instr_out__ = pipeline_stage[i];
                pipeline_stage.delete(i);
                break;
              end

            end else if (pipeline_stage[i].mem_op) begin

              if (memory_blocked === '1) begin
                __instr_out__ = 'x;
                continue;
              end else begin
                if (~|(pipeline_stage[i].reg_req & locks_i)) begin
                  __instr_out__ = pipeline_stage[i];
                  pipeline_stage.delete(i);
                  break;
                end else begin
                  memory_blocked = '1;
                  __instr_out__  = 'x;
                  continue;
                end
              end

            end else begin

              if (~|(pipeline_stage[i].reg_req & locks_i)) begin
                __instr_out__ = pipeline_stage[i];
                pipeline_stage.delete(i);
                break;
              end else begin
                locks_i = (1 << pipeline_stage[i].rd) | locks_i;
                __instr_out__ = 'x;
                continue;
              end

            end

          end

          $write("instr_out_tb : %p\n", __instr_out__);

        end else if (clear_i) begin
          while (pipeline_stage.size()) begin
            pipeline_stage.pop_front();
          end
        end
        $write("\n");
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // always @(locked_register_access_violation) begin
  //   violation_flags[0] = 1;
  //   $write("Error 0\n");
  // end

  // always @(mem_op_priority_violation) begin
  //   violation_flags[1] = 1;
  //   $write("Error 1\n");
  // end

  // always @(blocking_priority_violation) begin
  //   violation_flags[2] = 1;
  //   $write("Error 2\n");
  // end

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
    if (instr_mismatch_flag) $finish;
    repeat (11) @(posedge clk_i);
    // result_print(~violation_flags[0], "Locked Registers Access Denied");
    // result_print(~violation_flags[1], "Memory Operation Instruction Prioritization");
    // result_print(~violation_flags[2], "Blocking Instruction Prioritization");
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
