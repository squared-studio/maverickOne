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
  logic                 arst_ni = 1;
  logic                 clear_i = 0;
  decoded_instr_t       instr_in_i;
  logic                 instr_in_valid_i;
  locks_t               locks_i;
  logic                 instr_out_ready_i;

  // RTL Outputs
  logic                 instr_in_ready_o;
  decoded_instr_t       instr_out_o;
  logic                 instr_out_valid_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  event                 locked_register_access_violation;
  event                 mem_op_priority_violation;
  event                 blocking_priority_violation;
  logic           [2:0] violation_flags = '0;
  int                   full_mailbox = 0;
  decoded_instr_t       temp_instr;
  decoded_instr_t       temp_q                           [$];

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
        // // $write("[%.3t]\n", $realtime);

        clear_i <= $urandom_range(0, 99) < 2;  // 2% chance of clear
        instr_in_valid_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
        instr_out_ready_i <= $urandom_range(0, 99) < 50;  // data input valid 50% times
        locks_i <= $urandom;  // register locks profile input

        // // $write("clear_i: 0b%b\n", clear_i);
        // // $write("instr_in_valid_i: 0b%b\n", instr_in_valid_i);
        // // $write("instr_out_ready_i: 0b%b\n", instr_out_ready_i);
        // // $write("locks_i: 0b%b\n", locks_i);

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
        // // $write("instr_in_i.func: 0b%b\n", instr_in_i.func);
        // // $write("instr_in_i.rd: 0b%b\n", instr_in_i.rd);
        // // $write("instr_in_i.blocking: 0b%b\n", instr_in_i.blocking);
        // // $write("instr_in_i.reg_req: 0b%b\n", instr_in_i.reg_req);
      end
    join_none
  endtask

  task automatic start_in_out_monitor();
    decoded_instr_t __instr_in__;
    decoded_instr_t __instr_out__;

    mailbox #(decoded_instr_t) in_mbx = new(maverickOne_pkg::NUM_OUTSTANDING);
    mailbox #(decoded_instr_t) out_mbx = new();
    fork
      forever begin
        @(posedge clk_i);
        #5ps;
        // $write("[%.3t]\n", $realtime);

        if (arst_ni && ~clear_i) begin
          // // $write("CLEAR and RESET disabled.\n");

          if ((instr_in_valid_i === 1) && (instr_in_ready_o === 1)) begin
            // // $write("Input Handshake VALID and READY\n");
            if ((in_mbx.num() >= 0) && (in_mbx.num() < maverickOne_pkg::NUM_OUTSTANDING))
              in_mbx.put(instr_in_i);
          end

          if (instr_out_valid_o === 1 && instr_out_ready_i === 1) begin
            // // $write("Output Handshake VALID and READY\n");
            out_mbx.put(instr_out_o);
          end

          if (out_mbx.num()) begin
            // // $write("Checking for violations...\n");
            out_mbx.get(__instr_out__);
            // $write("instr_out: %p\n", __instr_out__);
            // $write("out_box_n: %03d\n", out_mbx.num());
            // $write("in_box_n : %03d\n", in_mbx.num());
            if ((in_mbx.num() > 0) && (in_mbx.num() <= maverickOne_pkg::NUM_OUTSTANDING)) begin
              // verify_mem_op(in_mbx, __instr_out__);  // in_mbx remains unchanged
              // verify_blocking(in_mbx, __instr_out__);  // in_mbx remains unchanged
              cascaded_locks(in_mbx, __instr_out__, locks_i);  // redundant instr popped out
            end
            if (|(__instr_out__.reg_req & locks_i)) begin
              ->locked_register_access_violation;
              // $write("reg_req: 0b%b\n", __instr_out__.reg_req);
              // $write("locks_i: 0b%b\n", locks_i);
            end
            // $write("\n");
          end

        end else begin  // empty the mailboxes T-T
          // // $write("CLEAR or RESET enabled.\n");
          // // $write("\n");
          while (in_mbx.num()) in_mbx.get(__instr_in__);
          while (out_mbx.num()) out_mbx.get(__instr_out__);
        end

      end
    join_none
  endtask

  task automatic verify_mem_op(mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__);
    // // $write("Verifying memory operation.\n");
    // ->mem_op_priority_violation; // Intentional bug: PANICKING UNNECESSARY
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end
    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) begin
        // $write("Out at index: %03d\n", i);
        // $write("temp_q: %p\n", temp_q[i]);
        // $write("instr_out: %p\n", __instr_out__);
        break;
      end else if (temp_q[i].mem_op || temp_q[i].blocking) begin
        ->mem_op_priority_violation;
        // $write("Violation at: %03d\n", i);
        // $write("temp_q: %p\n", temp_q[i]);
      end
    end
    foreach (temp_q[i]) begin
      in_mbx.put(temp_q[i]);
    end
    while (temp_q.size() > 0) temp_q.pop_front();  // empty the temp_q T-T
  endtask

  task automatic verify_blocking(mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__);
    // // $write("Verifying blocking operation.\n");
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end
    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) begin
        // $write("Out at index: %03d\n", i);
        // $write("temp_q: %p\n", temp_q[i]);
        // $write("instr_out: %p\n", __instr_out__);
        break;
      end else if (temp_q[i].mem_op || temp_q[i].blocking) begin
        ->blocking_priority_violation;
        // $write("Violation at: %03d\n", i);
        // $write("temp_q: %p\n", temp_q[i]);
      end
    end
    foreach (temp_q[i]) begin
      in_mbx.put(temp_q[i]);
    end
    while (temp_q.size() > 0) temp_q.pop_front();  // empty the temp_q T-T
  endtask

  task automatic cascaded_locks(mailbox#(decoded_instr_t) in_mbx, decoded_instr_t __instr_out__,
                                inout locks_t locks_i);
    // // $write("Verifying locking preservation.\n");
    while (in_mbx.num()) begin
      in_mbx.get(temp_instr);
      temp_q.push_back(temp_instr);
    end
    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) begin
        // $write("Out at index: %03d\n", i);
        // $write("temp_q: %p\n", temp_q[i]);
        // $write("instr_out: %p\n", __instr_out__);
        break;
      end else begin
        locks_i |= (1 << temp_q[i].rd);
        if (temp_q[i].blocking) locks_i = '1;
      end
    end
    foreach (temp_q[i]) begin
      if (temp_q[i] === __instr_out__) continue;
      in_mbx.put(temp_q[i]);
    end
    while (temp_q.size() > 0) temp_q.pop_front();  // empty the temp_q T-T
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(locked_register_access_violation) begin
    violation_flags[0] = 1;
    $write("Error 0\n");
  end

  always @(mem_op_priority_violation) begin
    violation_flags[1] = 1;
    $write("Error 1\n");
  end

  always @(blocking_priority_violation) begin
    violation_flags[2] = 1;
    $write("Error 2\n");
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
    repeat (15000) @(posedge clk_i);
    result_print(~violation_flags[0], "Locked Registers Access Denied");
    result_print(~violation_flags[1], "Memory Operation Instruction Prioritization");
    result_print(~violation_flags[2], "Blocking Instruction Prioritization");
    $finish;
  end

  initial begin
    // #1ms;
    repeat (150001) @(posedge clk_i);
    result_print(0, "FATAL TIMEOUT");
    $finish;
  end

endmodule
