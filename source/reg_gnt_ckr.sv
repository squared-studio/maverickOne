/*
It handles register locking and arbitration in a pipelined environment for a RISC-V core. The module
ensures that necessary registers are locked/unlocked based on the current pipeline state and the
requirements of instructions being executed.
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module reg_gnt_ckr #(
    parameter int NR = maverickOne_pkg::NUM_REGS  // Number of registers
) (
    // 1 for valid instruction from pipeline.
    input logic pl_valid_i,

    // For blocking instructions. If 1, lock all registers.
    input logic                  blocking_i,
    // Index of destination register.
    input logic [$clog2(NR)-1:0] rd_i,
    // Has 1s at the bits indicating required source registers by the current instruction.
    input logic [        NR-1:0] reg_req_i,

    // Input of locked registers.
    input  logic [NR-1:0] locks_i,
    // Output of locked registers. Note that when blocking_i = 0, rd_i = 0 register can never be locked
    // (only exception) - otherwise lock register indicated by rd_i.
    output logic [NR-1:0] locks_o,

    // 0/1 to arbiter based on locks_i and source registers required (all required source registers
    // must be un-locked to "pass").
    output logic arb_req_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb arb_req_o = pl_valid_i & ~(|(locks_i & reg_req_i));

  always_comb begin
    logic [NR-1:0] locks_mask;
    locks_mask = '0;
    locks_o = locks_i;
    if (pl_valid_i) begin
      if (blocking_i) begin
        locks_o = '1;
      end else begin
        locks_mask[rd_i] = |rd_i;
        locks_o |= locks_mask;
      end
    end
  end

endmodule
