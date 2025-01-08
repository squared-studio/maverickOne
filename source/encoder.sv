/*
The encoder module is designed to take a one-hot encoded input vector (wire_in) and generate a
binary index (index_o) corresponding to the position of the active input wire. It employs OR gates
to perform a hierarchical reduction of the input signals, ultimately determining the index of the
active wire. This module is intended to work with one-hot encoded inputs and will produce incorrect
results if multiple inputs are active simultaneously.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module encoder #(
    parameter int NUM_WIRE = 16  // Number of input wires
) (
    input logic [NUM_WIRE-1:0] wire_in,  // Input vector of wires

    output logic [$clog2(NUM_WIRE)-1:0] index_o,       // Output index of the highest priority wire
    output logic                        index_valid_o  // Output is valid
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Array to hold intermediate reduction results for each level
  logic [NUM_WIRE/2-1:0] index_or_red[$clog2(NUM_WIRE)];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate block to calculate reduction for each level
  for (genvar j = 0; j < $clog2(NUM_WIRE); j++) begin : g_addr_or_red
    always_comb begin
      int k;
      index_or_red[j] = '0;  // Initialize reduction array to 0
      k = 0;
      for (int i = 0; i < NUM_WIRE; i++) begin
        // Condition to include the wire in the current reduction level
        if (!((i % (2 ** (j + 1))) < ((2 ** (j + 1)) / 2))) begin
          index_or_red[j][k] = wire_in[i];  // Assign wire to reduction array
          k++;
        end
      end
    end
  end

  // Generate block to assign output index based on the reduction results
  for (genvar i = 0; i < $clog2(NUM_WIRE); i++) begin : g_addr_o
    always_comb index_o[i] = |index_or_red[i];  // OR reduction results to form the output index
  end

  // Determine if any input wire is active
  always_comb index_valid_o = |wire_in;

endmodule
