/*
The xbar (crossbar switch) module is designed to manage data routing between multiple input and
output ports. It allows each output port to independently select and receive data from any of the
input ports based on a selection vector. This module is useful in communication systems and digital
designs where flexible and efficient data routing is required, ensuring that data from any input can
be directed to any output based on specified criteria.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module xbar #(
    parameter int NUM_INPUT  = 4,  // Number of input ports
    parameter int NUM_OUTPUT = 4,  // Number of output ports
    parameter int DATA_WIDTH = 4   // Width of the data bus
) (
    // Input data vectors
    input logic [NUM_INPUT-1:0][DATA_WIDTH-1:0] input_vector_i,

    // Output data vectors
    output logic [NUM_OUTPUT-1:0][DATA_WIDTH-1:0] output_vector_o,
    // Selection vector for each output
    input logic [NUM_OUTPUT-1:0][$clog2(NUM_OUTPUT)-1:0] select_vector_i
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate MUX to route data
  for (genvar i = 0; i < NUM_OUTPUT; i++) begin : g_mux
    always_comb begin
      // For each output, select the corresponding input
      output_vector_o[i] = input_vector_i[select_vector_i[i]];
    end
  end

endmodule
