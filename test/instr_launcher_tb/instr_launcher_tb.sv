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

  event           locked_register_access_violation;
  event           mem_op_priority_violation;
  event           blocking_priority_violation;
  int             full_mailbox = 0;
  decoded_instr_t temp_instr;
  decoded_instr_t temp_q                           [$];

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
        locks_i <= $urandom_range(0, (2 ** (NUM_REGS) - 1));  // register locks profile input

        // instr_in_i.func <= maverickOne_pkg::func_t'($urandom);
        instr_in_i.rd <= $urandom_range(0, NUM_REGS - 1);
        // instr_in_i.rs1 <= $urandom_range(0, NUM_REGS-1);
        // instr_in_i.rs2 <= $urandom_range(0, NUM_REGS-1);
        // instr_in_i.rs3 <= $urandom_range(0, NUM_REGS-1);
        // instr_in_i.imm <= $urandom;
        // instr_in_i.pc <= $urandom;
        instr_in_i.blocking <= $urandom;
        instr_in_i.reg_req <= (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        )) | (1 << $urandom_range(
            0, NUM_REGS - 1
        ));

        clear_i <= $urandom_range(0, 99) < 2;  // 2% chance of clear

        instr_in_valid_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
        instr_out_ready_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    decoded_instr_t __instr_in__;
    decoded_instr_t __instr_out__;

    mailbox #(decoded_instr_t) in_mbx = new(maverickOne_pkg::NUM_OUTSTANDING);
    mailbox #(decoded_instr_t) out_mbx = new();
    fork
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni & ~clear_i) begin
            if (instr_in_valid_i === 1 & instr_in_ready_o === 1) in_mbx.put(instr_in_i);
          // end else begin
          //   while (in_mbx.num()) in_mbx.get(__instr_in__);
          //   while (out_mbx.num()) out_mbx.get(__instr_out__);
          end
        end
      end
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni & ~clear_i) begin
            if (instr_out_valid_o === 1 & instr_out_ready_i === 1) out_mbx.put(instr_out_o);

            if (out_mbx.num()) begin
              out_mbx.get(__instr_out__);
              if (in_mbx.num()) begin
                verify_mem_op(in_mbx, __instr_out__); // in_mbx remains unchanged
                verify_blocking(in_mbx, __instr_out__); // in_mbx remains unchanged
                cascaded_locks(in_mbx, __instr_out__, locks_i); // redundant instr popped out
              end
              if (|(__instr_out__.reg_req & locks_i))->locked_register_access_violation;
            end

          // end else begin
          //   while (in_mbx.num()) in_mbx.get(__instr_in__);
          //   while (out_mbx.num()) out_mbx.get(__instr_out__);
          end
        end
      end
    join_none
  endtask

  task automatic cascaded_locks(mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__,
                                inout locks_t locks_i);
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end

    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) break;
      locks_i |= (1 << temp_q[i].rd);
    end

    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) continue;
      in_mbx.put(temp_q[i]);
    end

  endtask

  task automatic verify_mem_op (mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__);
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end

    foreach(temp_q[i]) begin
      if (temp_q[i] === __instr_out__) break;
      if (temp_q[i].mem_op) ->mem_op_priority_violation;
    end

    foreach (temp_q[i]) begin
      in_mbx.put(temp_q[i]);
    end
  endtask

  task automatic verify_blocking (mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__);
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end

    foreach(temp_q[i]) begin
      if (temp_q[i] === __instr_out__) break;
      if (temp_q[i].blocking) ->blocking_priority_violation;
    end

    foreach (temp_q[i]) begin
      in_mbx.put(temp_q[i]);
    end
  endtask
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(locked_register_access_violation) begin
    result_print(0, "Locked Registers Access Denied");
  end

  always @(mem_op_priority_violation) begin
    result_print(0, "Memory Operation Instruction Prioritization");
  end

  always @(blocking_priority_violation) begin
    result_print(0, "Blocking Instruction Prioritization");
  end

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
    repeat (1000000) @(posedge clk_i);
    result_print(1, "Locked Registers Access Denied");
    result_print(1, "Memory Operation Instruction Prioritization");
    result_print(1, "Blocking Instruction Prioritization");
    $finish;
  end

endmodule
