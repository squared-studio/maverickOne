/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module reg_gnt_ckr_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NR = maverickOne_pkg::NUM_REGS;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [NR-1:0] logicNR;
  typedef logic [$clog2(NR)-1:0] logicLogNR;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  // RTL Input
  logic pl_valid_i;  // pipeline instruction validity
  logic blocking_i;  // if 1, lock all registers
  logicLogNR rd_i;  // destination register index
  logicNR reg_req_i;  // instruction source register requirement
  logicNR locks_i;  // register locking status input
  logic mem_op_i;  // memory operation flag
  logic mem_busy_i;  // memory busy flag from previous operation

  // RTL Output
  logicNR locks_o;  // register locking status output
  logic arb_req_o;  // enable arbitration if all instruction source registers are unlocked
  logic mem_busy_o;  // memory busy flag for next operation

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int outage_counter;
  event blocking_violation;
  event arb_violation[2];
  event rd_locking_violation;
  event end_of_simulation;
  logic [3:0] violation_state;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  reg_gnt_ckr #(
      .NR(NR)
  ) urgckr_1 (
      .pl_valid_i,
      .blocking_i,
      .rd_i,
      .reg_req_i,
      .locks_i,
      .locks_o,
      .mem_op_i,
      .mem_busy_i,  // TODO UPDATE TB. WHY IS IT NOT FAILING AFTER NEW SIGNAL ADDITION
      .mem_busy_o,  // TODO UPDATE TB. WHY IS IT NOT FAILING AFTER NEW SIGNAL ADDITION
      .arb_req_o  // TODO UPDATE TB. WHY IS IT NOT FAILING AFTER NEW SIGNAL ADDITION
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_random_driver();
    fork
      forever begin
        @(posedge clk_i);
        pl_valid_i <= $urandom_range(0, 99) > 10;  // 10% instruction outage prob.
        blocking_i <= $urandom_range(0, 99) < 10;  // 10% blocking calls
        rd_i       <= $urandom;
        reg_req_i  <= 1 << $urandom_range(0, NR - 1) | 1 << $urandom_range(0, NR - 1);
        locks_i    <= {$urandom, $urandom};
        mem_op_i   <= $urandom;  // random memory operation flag
        mem_busy_i <= $urandom;  // random memory busy flag
      end
    join_none
  endtask

  task automatic start_in_out_mon();
    outage_counter = 0;
    fork
      forever begin
        @(posedge clk_i);

        if (~pl_valid_i) begin
          if (arb_req_o)->arb_violation[0];
          else outage_counter++;
        end else begin
          if (blocking_i) begin
            if (~(&locks_o))->blocking_violation;
          end
          if (|(reg_req_i & locks_i)) begin
            if (arb_req_o)->arb_violation[1];
          end
          if (rd_i > 0 && locks_o[rd_i] !== 1)->rd_locking_violation;
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    start_clk_i();
    start_random_driver();
    start_in_out_mon();
  end  // main initial

  initial begin
    repeat (1000000) @(posedge clk_i);
    ->end_of_simulation;
  end  // set simulation time...

  initial begin
    foreach (violation_state[i]) begin
      violation_state[i] = 'b1;
    end
    fork
      begin
        @(blocking_violation);
        $write("[%.3t] blocking case violation\n", $realtime);
        $write("reg_req_i: 0b%b\n", reg_req_i);
        $write("locks_i: 0b%b\n", locks_i);
        $write("rd_i: %03d\t pl_valid_i: 0b%b\t blocking_i: 0b%b\n", rd_i, pl_valid_i, blocking_i);
        $write("locks_o: 0b%b\t", locks_o);
        $write("arb_req_o: 0b%b\n\n", arb_req_o);
        violation_state[0] = 'b0;
      end
      begin
        @(arb_violation[0]);
        $write("[%.3t] Outage Arbitration violation\n", $realtime);
        $write("reg_req_i: 0b%b\n", reg_req_i);
        $write("locks_i: 0b%b\n", locks_i);
        $write("rd_i: %03d\t pl_valid_i: 0b%b\t blocking_i: 0b%b\n", rd_i, pl_valid_i, blocking_i);
        $write("locks_o: 0b%b\t", locks_o);
        $write("arb_req_o: 0b%b\n\n", arb_req_o);
        violation_state[1] = 'b0;
      end
      begin
        @(arb_violation[1]);
        $write("[%.3t] Locked Arbitration violation\n", $realtime);
        $write("reg_req_i: 0b%b\n", reg_req_i);
        $write("locks_i: 0b%b\n", locks_i);
        $write("rd_i: %03d\t pl_valid_i: 0b%b\t blocking_i: 0b%b\n", rd_i, pl_valid_i, blocking_i);
        $write("locks_o: 0b%b\t", locks_o);
        $write("arb_req_o: 0b%b\n\n", arb_req_o);
        violation_state[2] = 'b0;
      end
      begin
        @(rd_locking_violation);
        $write("[%.3t] Rd Locking violation\n", $realtime);
        $write("reg_req_i: 0b%b\n", reg_req_i);
        $write("locks_i: 0b%b\n", locks_i);
        $write("rd_i: %03d\t pl_valid_i: 0b%b\t blocking_i: 0b%b\n", rd_i, pl_valid_i, blocking_i);
        $write("locks_o: 0b%b\t", locks_o);
        $write("arb_req_o: 0b%b\n\n", arb_req_o);
        violation_state[3] = 'b0;
      end
    join_none
  end  // check for condition violations...

  initial begin
    @(end_of_simulation);
    result_print(violation_state[0], "Blocking Condition Violation Check");
    result_print(violation_state[1], "Arbitration During Outage Check");
    result_print(violation_state[2], "Arbitration Of Locked Registers Check");
    result_print(violation_state[3], "Destination Register Locking Check");
    $finish;
  end  // results of simulation...

endmodule
