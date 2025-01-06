/*
The purpose of the pipeline module is to manage data flow in a pipelined system. It handles data
input and output through handshaking signals, ensuring proper synchronization and data integrity.
The module is parameterizable for different data widths and includes mechanisms to reset and clear
internal states, making it a flexible component for various hardware designs. Its main
functionalities include:
- Accepting input data when valid and ready
- Transferring data to output when conditions are met
- Managing internal state with flags to indicate if the pipeline stage is full or ready

This ensures efficient and controlled data processing within the pipeline.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module pipeline #(
    parameter int DW = 8  // Data width parameter
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input
    input logic clear_i,  // Synchronous clear signal

    input  logic [DW-1:0] data_in_i,        // Input data
    input  logic          data_in_valid_i,  // Input data valid signal
    output logic          data_in_ready_o,  // Input data ready signal

    output logic [DW-1:0] data_out_o,        // Output data
    output logic          data_out_valid_o,  // Output data valid signal
    input  logic          data_out_ready_i   // Output data ready signal
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Flag to indicate if the pipeline stage is full
  logic is_full;
  // Handshake signal for input data
  logic input_handshake;
  // Handshake signal for output data
  logic output_handshake;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Ready if not reset/clear and either not full or output is ready
  always_comb data_in_ready_o = arst_ni & ~clear_i & ((is_full) ? data_out_ready_i : '1);
  // Output is valid if the stage is full and is not reset/clear
  always_comb data_out_valid_o = is_full & arst_ni & ~clear_i;
  // Handshake condition for input data
  always_comb input_handshake = data_in_valid_i & data_in_ready_o;
  // Handshake condition for output data
  always_comb output_handshake = data_out_valid_o & data_out_ready_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Latch input data to output on positive clock edge if handshake is successful
  always_ff @(posedge clk_i) begin
    if (input_handshake) begin
      data_out_o <= data_in_i;
    end
  end

  // Control the is_full flag based on reset, clear, input, and output handshake signals
  always_ff @(posedge clk_i or negedge arst_ni) begin : main_block
    if (~arst_ni) begin
      is_full <= '0;  // Reset the is_full flag when asynchronous reset is active
    end else begin
      // Determine the next state of is_full based on the current clear, input handshake, and
      // output handshake signals
      casex ({
        clear_i, input_handshake, output_handshake
      })
        3'b1xx, 3'b001: is_full <= '0;
        3'b010, 3'b011: is_full <= '1;
        default: is_full <= is_full;
      endcase
    end
  end

endmodule
