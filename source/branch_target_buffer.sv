/*
Write a markdown documentation for this systemverilog module:
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module branch_target_buffer #(
    localparam type addr_t = logic [63:0]
) (
    input logic clk_i,   // Clock input
    input logic arst_ni, // Asynchronous Reset input

    input addr_t current_addr_i,  // Current address (EXEC) input
    input addr_t next_addr_i,     // Next address (EXEC) input
    input addr_t pc_i,            // pc (IF) input
    input logic  is_jump_i,       // Is Jump/Branch (IF) input

    output logic  found_o,         // Found match in buffer output
    output logic  table_update_o,  // Table update event output
    output addr_t next_pc_o        // Next pc (in case of jump) output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NUMREG = 256;  // 256 buffer rows

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam type reduced_addr_t = logic [63:2];  // Won't store last 2 addr bits

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  reduced_addr_t buffer_current[NUMREG];  // SHOULD I MAKE THESE 2 PACKED?
  reduced_addr_t buffer_next[NUMREG];
  logic [NUMREG-1:0] buffer_valid;

  logic naddr_neq_caddr_plus4;

  logic [NUMREG-1:0] pc_caddr_match;
  logic [$clog2(NUMREG)-1:0] match_row_ind;
  logic [$clog2(NUMREG)-1:0] empty_row_ind;
  logic [$clog2(NUMREG)-1:0] write_row_ind;

  logic empty_row_found;
  logic found;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i = 0; i < NUMREG; i++) begin : g_pc_caddr_match
    always_comb pc_caddr_match[i] = buffer_valid[i] & (pc_i == buffer_current[i]);
  end

  assign found_o = found | table_update_o;

  priority_encoder #(
      .NUM_WIRE(NUMREG)
  ) pc_caddr_match_find (
      .wire_in(pc_caddr_match),
      .index_o(match_row_ind),
      .index_o(found)
  );

  priority_encoder #(
      .NUM_WIRE(NUMREG)
  ) empty_row_find (
      .wire_in(~buffer_valid),
      .index_o(empty_row_ind),
      .index_o(empty_row_found)
  );

  always_comb next_pc_o = table_update_o ? next_addr_i : {buffer_next[match_row_ind], 2'b00};

  always_comb naddr_neq_caddr_plus4 = (current_addr_i + 4 != next_addr_i);

  always_comb table_update_o = is_jump_i & (naddr_neq_caddr_plus4 ^ found);

  always_comb write_row_ind = naddr_neq_caddr_plus4 ? empty_row_ind : match_row_ind;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i) begin
    BUFFER_LIMIT :
    assert (~(table_update_o & ~empty_row_found))
    else $error("Buffer limit reached with all valid");  // For now. Might change to FIFO later

    if (table_update_o) begin
      buffer_current[write_row_ind] <= current_addr_i[63:2];
      buffer_next[write_row_ind] <= next_addr_i[63:2];
    end
  end

  always @(posedge clk_i, negedge arst_ni) begin
    if (~arst_ni) begin
      buffer_valid = '0;
    end else if (table_update_o) begin
      buffer_valid[write_row_ind] <= naddr_neq_caddr_plus4;
    end
  end

endmodule
