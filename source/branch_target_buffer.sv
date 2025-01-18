/*
The `branch_target_buffer` is designed to store and manage branch target addresses for a processor,
helping to predict the next instruction address in case of a branch or jump.
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module branch_target_buffer #(
    parameter int NUM_BTBL = maverickOne_pkg::NUM_BTBL,  // Number of branch target buffer lines
    parameter int XLEN     = maverickOne_pkg::XLEN,       // Integer register width
    localparam type addr_t = logic [XLEN-1:0]  // Address type
) (
    input logic clk_i,   // Clock input
    input logic arst_ni, // Asynchronous reset input

    input addr_t current_addr_i,   // Current address (EXEC) input
    input addr_t next_addr_i,      // Next address (EXEC) input
    input addr_t pc_i,             // Program counter (IF) input
    input logic            is_jump_i,        // Is jump/branch (IF) input

    output logic            match_found_o,   // Found match in buffer output
    output logic            flush_o,         // Pipeline flush signal output
    output addr_t next_pc_o        // Next program counter (in case of jump) output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [XLEN-1:2] reduced_addr_t;  // Reduced address type (excluding last 2 bits)

  ///////////////////////////////////////////////
  // REGISTERS
  ///////////////////////////////////////////////

  // Buffer to store current addresses
  reduced_addr_t current_addr_buffer[NUM_BTBL];
  // Buffer to store next addresses
  reduced_addr_t next_addr_buffer[NUM_BTBL];
  // Valid bits for buffer entries
  logic [NUM_BTBL-1:0] valid_buffer;
  // Strength bits for buffer entries
  logic [NUM_BTBL-1:0] strength_buffer;
  // Valid + Strength bits for buffer entries
  logic [1:0] valid_strength [NUM_BTBL];
  // Counter for buffer entries
  logic [$clog2(NUM_BTBL)-1:0] buffer_counter;

  ///////////////////////////////////////////////
  // WIRES
  ///////////////////////////////////////////////

  // Write enable signals for buffer entries
  logic [NUM_BTBL-1:0] write_enable;

  // Flag to check if next address is not equal to current address + 4
  logic addr_mismatch;

  // Match signals for program counter and current address
  logic [NUM_BTBL-1:0] pc_addr_match;
  // Index of matching row in buffer
  logic [$clog2(NUM_BTBL)-1:0] match_index;
  // Index of empty row in buffer
  logic [$clog2(NUM_BTBL)-1:0] empty_index;
  // Index of row to write in buffer
  logic [$clog2(NUM_BTBL)-1:0] write_index;

  // Input and Output state for State Decider - {valid, strength}
  logic [1:0] input_state, output_state;
  //State Definitions
  parameter logic[1:0]  INVALID       = 2'b01,  // Invalid entry
                        VALID_WEAK    = 2'b10,  // Valid and weak strength
                        VALID_STRONG  = 2'b11;  // Valid and strong strength

  // Flag to indicate if an empty row is found
  logic empty_found;
  // Flag to indicate if a match is found
  logic match_found;
  // Table update event
  logic update_table;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Check for matches between program counter and current addresses in buffer
  for (genvar i = 0; i < NUM_BTBL; i++) begin : g_pc_addr_match
    always_comb pc_addr_match[i] = valid_buffer[i] & (pc_i == current_addr_buffer[i]);
  end

  // Output match_found signal if a match is found or table is updated
  always_comb match_found_o = match_found | flush_o;

  // Output next program counter based on table update or buffer content
  always_comb next_pc_o = flush_o ? next_addr_i : {next_addr_buffer[match_index], 2'b00};

  // Check if next address is not equal to current address + 4
  always_comb addr_mismatch = (current_addr_i + 4 != next_addr_i);

  // Flush buffer if there's a new jump or buffer entry is incorrect
  always_comb flush_o = is_jump_i & (addr_mismatch ^ match_found);

  // Update table if there's a flush EXCEPT when VALID_STRONG
  always_comb update_table = flush_o & ~(&input_state);

  // Determine the row index to write in buffer
  always_comb
    write_index = addr_mismatch ? (empty_found ? empty_index : buffer_counter) : match_index;

  for(genvar i = 0; i < NUM_BTBL; i++) begin : g_valid_strength
    assign valid_strength[i] = {valid_buffer[i], strength_buffer[i]};
  end

  // Multiplexer for choosing input state for FSM
  always_comb input_state = valid_strength[write_index];

  // State Decider
  always_comb begin
    case (input_state)
      INVALID:      output_state = addr_mismatch ? VALID_STRONG : INVALID;
      VALID_WEAK:   output_state = addr_mismatch ? VALID_STRONG : INVALID;
      VALID_STRONG: output_state = addr_mismatch ? VALID_STRONG : VALID_WEAK;
      default:      output_state = INVALID;
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instance of the demux module to generate write enable signals
  demux #(
      .NUM_ELEM  (NUM_BTBL),
      .ELEM_WIDTH(1)
  ) u_demux (
      .index_i(write_index),
      .data_i (update_table),
      .out_o  (write_enable)
  );

  // Instance of the encoder module to find matching row index
  encoder #(
      .NUM_WIRE(NUM_BTBL)
  ) pc_addr_match_find (
      .wire_in(pc_addr_match),
      .index_o(match_index),
      .index_valid_o(match_found)
  );

  // Instance of the priority encoder module to find empty row index
  priority_encoder #(
      .NUM_WIRE(NUM_BTBL)
  ) empty_row_find (
      .wire_in(~valid_buffer),
      .index_o(empty_index),
      .index_valid_o(empty_found)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Sequential logic to update buffer entries
  for (genvar i = 0; i < NUM_BTBL; i++) begin : g_regs
    always @(posedge clk_i) begin
      if (write_enable[i]) begin
        current_addr_buffer[i] <= current_addr_i[XLEN-1:2];
      end
    end

    always @(posedge clk_i) begin
      if (write_enable[i]) begin
        next_addr_buffer[i] <= next_addr_i[XLEN-1:2];
      end
    end

    // Sequential logic to update valid bits for buffer entries
    always_ff @(posedge clk_i or negedge arst_ni) begin
      if (~arst_ni) begin
        valid_buffer[i] <= '0;
      end else if (write_enable[i]) begin
        valid_buffer[i] <= output_state[1];
      end
    end

    // Sequential logic to update strength bits for buffer entries
    always_ff @(posedge clk_i or negedge arst_ni) begin
      if (~arst_ni) begin
        strength_buffer[i] <= '1;
      end else if (valid_buffer[i]) begin
        strength_buffer[i] <= output_state[0];
      end
    end
  end

  // Sequential logic to update counter
  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      buffer_counter <= '0;
    end else begin
      if (~empty_found & is_jump_i) buffer_counter <= buffer_counter + 1;
    end
  end

endmodule
