/*
The rotating_xbar module is designed to act as a rotating crossbar switch, enabling dynamic routing
of data from multiple input lines to multiple output lines. The key feature of this module is its
ability to cyclically rotate the selection of input sources for the outputs based on a specified
starting index (start_select_i). This rotation ensures balanced and efficient data distribution
among the outputs, making it useful in communication systems and digital designs that require
flexible and dynamic data routing. The module leverages an instantiated crossbar switch (xbar) and
calculates the selection indices dynamically to achieve the desired rotation.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module rotating_xbar #(
    parameter int NUM_DATA   = 4,  // Number of data lines
    parameter int DATA_WIDTH = 4   // Width of each data line
) (
    input logic [NUM_DATA-1:0][DATA_WIDTH-1:0] input_vector_i,  // Input data vectors

    output logic [        NUM_DATA-1:0][DATA_WIDTH-1:0] output_vector_o,  // Output data vectors
    input  logic [$clog2(NUM_DATA)-1:0]                 start_select_i    // Start selection index
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Internal vector to hold the calculated selection indices
  logic [NUM_DATA-1:0][$clog2(NUM_DATA)-1:0] select_vector_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate blocks to calculate the selection index for each output
  for (genvar i = 0; i < NUM_DATA; i++) begin : g_select_vector_i
    always_comb begin
      select_vector_i[i] = (start_select_i + i) % NUM_DATA;  // Calculate rotated index
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the xbar module, passing the calculated selection vector
  xbar #(
      .NUM_INPUT (NUM_DATA),
      .NUM_OUTPUT(NUM_DATA),
      .DATA_WIDTH(DATA_WIDTH)
  ) u_xbar (
      .input_vector_i,  // Connect input data vector
      .output_vector_o,  // Connect output data vector
      .select_vector_i  // Connect selection vector
  );

endmodule
