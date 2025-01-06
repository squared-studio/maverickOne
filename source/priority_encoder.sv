/*
The priority_encoder module's primary purpose is to encode an input vector of signals, determining
the index of the highest priority active input wire. It achieves this by first using a fixed
priority arbiter to generate a one-hot encoded signal of the highest priority request. This one-hot
encoded signal is then passed to a simple encoder module, which converts it into a binary index
representing the active input wire.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module priority_encoder #(
    parameter int NUM_WIRE = 16  // Number of input wires
) (
    input logic [NUM_WIRE-1:0] wire_in,  // Input vector of wires

    output logic [$clog2(NUM_WIRE)-1:0] index_o,       // Output index of the highest priority wire
    output logic                        index_valid_o  // Output is valid
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NUM_WIRE-1:0] one_hot_out;  // Intermediate one-hot encoded output

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the fixed_priority_arbiter module
  fixed_priority_arbiter #(
      .NUM_REQ(NUM_WIRE)  // Number of requests
  ) u_fixed_priority_arbiter (
      .allow_i('1),
      .req_i(wire_in),     // Input request signals
      .gnt_o(one_hot_out)  // One-hot encoded grant output
  );

  // Instantiate the encoder module
  encoder #(
      .NUM_WIRE(NUM_WIRE)  // Number of input wires for the encoder
  ) u_encoder (
      .wire_in      (one_hot_out),   // Input one-hot encoded signals
      .index_o      (index_o),       // Output index of the highest priority wire
      .index_valid_o(index_valid_o)
  );

endmodule
