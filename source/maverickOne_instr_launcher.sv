/*
The maverickOne_instr_launcher module manages the instructions heading for execution. It temporarily store
instructions, checks register availability, and launches them for execution avoiding hazzards.

Author: Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module maverickOne_instr_launcher #(
    // Type for decoded instructions
    localparam type decoded_instr_t = maverickOne_pkg::decoded_instr_t,
    // Number of registers
    localparam int NR = maverickOne_pkg::NUM_REGS,
    // Type for lock signals
    localparam type locks_t = logic [NR-1:0]
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input
    input logic clear_i,  // Synchronous clear signal

    input  decoded_instr_t instr_in_i,        // Incoming decoded instruction
    input  logic           instr_in_valid_i,  // Valid signal for incoming instruction
    output logic           instr_in_ready_o,  // Ready signal for incoming instruction

    input locks_t locks_i,  // Input lock signals for registers from regfile

    output decoded_instr_t instr_out_o,        // Outgoing decoded instruction
    output logic           instr_out_valid_o,  // Valid signal for outgoing instruction
    input  logic           instr_out_ready_i   // Ready signal for outgoing instruction
);

  import maverickOne_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Maximum Number of outstanding instructions
  localparam int NOS = maverickOne_pkg::NUM_OUTSTANDING;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NOS:0] clears;  // Clear signals for pipelines

  decoded_instr_t [NOS:0] pl_ins;  // Pipeline inputs
  logic [NOS:0] pl_ins_valid;  // Valid signals for pipeline inputs
  logic [NOS:0] pl_ins_ready;  // Ready signals for pipeline inputs
  decoded_instr_t [NOS:0] pl_outs;  // Pipeline outputs
  logic [NOS:0] pl_outs_valid;  // Valid signals for pipeline outputs
  logic [NOS:0] pl_outs_ready;  // Ready signals for pipeline outputs

  locks_t locks[NOS+2];  // Lock signals propagating between reg_gnt_ckr

  logic [NOS:0] arb_req;  // Arbitration request signals
  logic [NOS:0] arb_gnt;  // Arbitration grant signals

  logic [$clog2(NOS+1)-1:0] gnt_idx;  // Index of granted request

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Assign input instruction to the first pipeline stage
  assign pl_ins[0]        = instr_in_i;
  assign pl_ins_valid[0]  = instr_in_valid_i;
  assign instr_in_ready_o = pl_ins_ready[0];

  // Initialize lock signals
  assign locks[0]         = locks_i;

  // Assign output instruction and valid signal based on granted request index
  assign instr_out_o      = pl_outs[gnt_idx];

  assign pl_outs_ready    = arb_gnt;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate pipeline
  for (genvar i = 0; i < NOS; i++) begin : g_splits
    pipeline_split #(
        .DW($bits(instr_in_i))
    ) u_pipeline_split (
        .arst_ni,
        .clk_i,
        .clear_i(clears[NOS-1]),
        .data_in_i(pl_ins[i]),
        .data_in_valid_i(pl_ins_valid[i]),
        .data_in_ready_o(pl_ins_ready[i]),
        .data_out_main_o(pl_outs[NOS-i]),
        .data_out_main_valid_o(pl_outs_valid[NOS-i]),
        .data_out_main_ready_i(pl_outs_ready[NOS-i]),
        .data_out_secondary_o(pl_ins[i+1]),
        .data_out_secondary_valid_o(pl_ins_valid[i+1]),
        .data_out_secondary_ready_i(pl_ins_ready[i+1])
    );
  end

  // Final pipeline stage
  pipeline #(
      .DW($bits(instr_in_i))
  ) u_pipeline_split (
      .arst_ni,
      .clk_i,
      .clear_i         (clears[0]),
      .data_in_i       (pl_ins[NOS]),
      .data_in_valid_i (pl_ins_valid[NOS]),
      .data_in_ready_o (pl_ins_ready[NOS]),
      .data_out_o      (pl_outs[0]),
      .data_out_valid_o(pl_outs_valid[0]),
      .data_out_ready_i(pl_outs_ready[0])
  );

  // Generate grant checkers for each pipeline
  for (genvar i = 0; i < NOS + 1; i++) begin : g_ckeckers
    reg_gnt_ckr #() u_reg_gnt_ckr (
        .pl_valid_i(pl_outs_valid[i]),
        .blocking_i(pl_outs[i].blocking),
        .rd_i(pl_outs[i].rd),
        .reg_req_i(pl_outs[i].reg_req),
        .locks_i(locks[i]),
        .locks_o(locks[i+1]),
        .arb_req_o(arb_req[i])
    );
  end

  // Fixed priority arbiter for arbitration among pipeline
  fixed_priority_arbiter #(
      .NUM_REQ(NOS + 1)
  ) u_fixed_priority_arbiter (
      .allow_i(instr_out_ready_i),
      .req_i  (arb_req),
      .gnt_o  (arb_gnt)
  );

  // Encoder for determining the granted request index
  encoder #(
      .NUM_WIRE(NOS + 1)
  ) u_encoder (
      .wire_in(arb_gnt),
      .index_o(gnt_idx),
      .index_valid_o(instr_out_valid_o)
  );

  // Generate clear signals for pipeline
  for (genvar i = 0; i < NOS; i++) begin : g_clears
    assign clears[i] = clears[i+1] & (gnt_idx != (i + 1));
  end
  assign clears[NOS] = clear_i;

endmodule
