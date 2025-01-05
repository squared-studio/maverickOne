/*
The `branch_target_buffer` is designed to store and manage branch target addresses for a processor,
helping to predict the next instruction address in case of a branch or jump.
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module branch_target_buffer #(
    parameter int NUM_BTBL = maverickOne_pkg::NUM_BTBL,  // Number of branch target buffer Lines
    parameter int XLEN     = maverickOne_pkg::XLEN       // integer register width
) (
    input logic clk_i,   // Clock input
    input logic arst_ni, // Asynchronous Reset input

    input logic [XLEN-1:0] current_addr_i,  // Current address (EXEC) input
    input logic [XLEN-1:0] next_addr_i,     // Next address (EXEC) input
    input logic [XLEN-1:0] pc_i,            // pc (IF) input
    input logic            is_jump_i,       // Is Jump/Branch (IF) input

    output logic            found_o,         // Found match in buffer output
    output logic            table_update_o,  // Table update event output
    output logic [XLEN-1:0] next_pc_o        // Next pc (in case of jump) output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [XLEN-1:2] reduced_addr_t;  // Won't store last 2 addr bits

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////
  // REGISTERS
  ///////////////////////////////////////////////

  reduced_addr_t buffer_current[NUM_BTBL];
  reduced_addr_t buffer_next[NUM_BTBL];
  logic [NUM_BTBL-1:0] buffer_valid;
  logic [$clog2(NUM_BTBL)-1:0] counter;

  ///////////////////////////////////////////////
  // WIRES
  ///////////////////////////////////////////////

  logic [NUM_BTBL-1:0] wr_en;

  logic naddr_neq_caddr_plus4;

  logic [NUM_BTBL-1:0] pc_caddr_match;
  logic [$clog2(NUM_BTBL)-1:0] match_row_ind;
  logic [$clog2(NUM_BTBL)-1:0] empty_row_ind;
  logic [$clog2(NUM_BTBL)-1:0] write_row_ind;

  logic empty_row_found;
  logic found;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i = 0; i < NUM_BTBL; i++) begin : g_pc_caddr_match
    always_comb pc_caddr_match[i] = buffer_valid[i] & (pc_i == buffer_current[i]);
  end

  always_comb found_o = found | table_update_o;

  always_comb next_pc_o = table_update_o ? next_addr_i : {buffer_next[match_row_ind], 2'b00};

  always_comb naddr_neq_caddr_plus4 = (current_addr_i + 4 != next_addr_i);

  always_comb table_update_o = is_jump_i & (naddr_neq_caddr_plus4 ^ found);

  always_comb
    write_row_ind = naddr_neq_caddr_plus4 ? (empty_row_found ? empty_row_ind : counter)
                  : match_row_ind;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instance of the demux module
  demux #(
      .NUM_ELEM  (NUM_BTBL),
      .ELEM_WIDTH(1)
  ) u_demux (
      .index_i(write_row_ind),
      .data_i (table_update_o),
      .out_o  (wr_en)
  );

  encoder #(
      .NUM_WIRE(NUM_BTBL)
  ) pc_caddr_match_find (
      .wire_in(pc_caddr_match),
      .index_o(match_row_ind),
      .index_valid_o(found)
  );

  priority_encoder #(
      .NUM_WIRE(NUM_BTBL)
  ) empty_row_find (
      .wire_in(~buffer_valid),
      .index_o(empty_row_ind),
      .index_valid_o(empty_row_found)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i = 0; i < NUM_BTBL; i++) begin : g_regs
    always @(posedge clk_i) begin
      if (wr_en[i]) begin
        buffer_current[i] <= current_addr_i[XLEN-1:2];
      end
    end

    always @(posedge clk_i) begin
      if (wr_en[i]) begin
        buffer_next[i] <= next_addr_i[XLEN-1:2];
      end
    end

    always_ff @(posedge clk_i or negedge arst_ni) begin
      if (~arst_ni) begin
        buffer_valid[i] <= '0;
      end else if (wr_en[i]) begin
        buffer_valid[i] <= naddr_neq_caddr_plus4;
      end
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      counter <= '0;
    end else begin
      if (~empty_row_found & is_jump_i) counter <= counter + 1;
    end
  end


endmodule
