/*
The purpose of this module is to ensure reliable data transfer by prioritizing the main output path
while providing a fallback to the secondary path if the main path is unavailable. This allows for
efficient handling of data in scenarios where data must be directed to different paths based on
readiness, ensuring no data loss or delay in processing.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module pipeline_split #(
    parameter int DW = 8  // Data width parameter
) (
    input logic arst_ni,  // Asynchronous reset, active low
    input logic clk_i,    // Clock input
    input logic clear_i,  // Synchronous clear signal

    input  logic [DW-1:0] data_in_i,        // Input data
    input  logic          data_in_valid_i,  // Input data valid signal
    output logic          data_in_ready_o,  // Input data ready signal

    output logic [DW-1:0] data_out_main_o,        // Main output data
    output logic          data_out_main_valid_o,  // Main output data valid signal
    input  logic          data_out_main_ready_i,  // Main output data ready signal

    output logic [DW-1:0] data_out_secondary_o,        // Secondary output data
    output logic          data_out_secondary_valid_o,  // Secondary output data valid signal
    input  logic          data_out_secondary_ready_i   // Secondary output data ready signal
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Internal signals for data and handshake between pipeline stages
  logic [DW-1:0] data_out_o;  // Data output from the internal pipeline
  logic          data_out_valid_o;  // Valid signal for data output from the internal pipeline
  logic          data_out_ready_i;  // Ready signal input for the internal pipeline

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Assign internal pipeline outputs to the main and secondary outputs
  always_comb data_out_main_o = data_out_o;
  always_comb data_out_secondary_o = data_out_o;

  // Determine if main or secondary output is valid
  always_comb data_out_main_valid_o = data_out_valid_o;
  always_comb data_out_secondary_valid_o = data_out_main_ready_i ? '0 : data_out_valid_o;

  // Combine ready signals from both outputs
  always_comb data_out_ready_i = data_out_main_ready_i | data_out_secondary_ready_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the internal pipeline module
  pipeline #(
      .DW(DW)
  ) u_pipeline (
      .arst_ni,  // Connect asynchronous reset
      .clk_i,  // Connect clock
      .clear_i,  // Connect synchronous clear
      .data_in_i,  // Connect input data
      .data_in_valid_i,  // Connect input data valid signal
      .data_in_ready_o,  // Connect input data ready signal
      .data_out_o,  // Connect data output from pipeline
      .data_out_valid_o,  // Connect data valid output from pipeline
      .data_out_ready_i  // Connect ready input to pipeline
  );

endmodule
