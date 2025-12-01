/*
This module handles register locking and arbitration in a pipelined environment for a RISC-V core.
It ensures that necessary registers are locked/unlocked based on the current pipeline state and the
requirements of instructions being executed.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module reg_gnt_ckr #(
    parameter int NR = maverickOne_pkg::NUM_REGS  // Number of registers
) (
    // Valid instruction signal from the pipeline.
    input logic pl_valid_i,

    // Signal to lock all registers for blocking instructions.
    input logic                  blocking_i,
    // Index of the destination register.
    input logic [$clog2(NR)-1:0] rd_i,
    // Bitmask indicating required source registers for the current instruction.
    input logic [        NR-1:0] reg_req_i,

    // Input bitmask of locked registers.
    input  logic [NR-1:0] locks_i,
    // Output bitmask of locked registers. When blocking_i = 0, register 0 (rd_i = 0) can never be
    // locked. Otherwise, lock the register indicated by rd_i.
    output logic [NR-1:0] locks_o,

    // Flag indicating if the current operation is a memory operation.
    input  logic mem_op_i,
    // Flag indicating if the memory is busy from the previous operation.
    input  logic mem_busy_i,
    // Flag indicating if the memory will be busy for the next operation.
    output logic mem_busy_o,

    // Request signal to the arbiter based on locks_i and required source registers. All required
    // source registers must be unlocked to assert this signal.
    output logic arb_req_o
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Update memory busy flag for the next operation.
  always_comb mem_busy_o = mem_busy_i | (mem_op_i && mem_busy_i); // Updated condition to avoid 'x

  // Generate arbiter request signal based on memory operation and locked registers.
  // always_comb arb_req_o = ~(mem_op_i & mem_busy_i) ? (pl_valid_i & ~(|(locks_i & reg_req_i))) : '0;
  always_comb
    arb_req_o = pl_valid_i ? ((mem_op_i & mem_busy_i) ? '0 :
  (pl_valid_i & ~(|(locks_i & reg_req_i)))) : '0; // TODO: OPTIMIZE

  // Update locked registers based on the current pipeline state and blocking signal.
  always_comb begin
    logic [NR-1:0] locks_mask;
    locks_mask = '0;
    locks_o = locks_i;
    if (pl_valid_i) begin
      if (blocking_i) begin
        locks_o = '1;
      end else begin
        // locks_mask[rd_i] = |rd_i;
        locks_mask[rd_i] = '1; // hardcoded this
        locks_o |= locks_mask;
      end
    end
  end

endmodule
