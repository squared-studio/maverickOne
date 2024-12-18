/*
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module demux #(
    parameter int NUM_ELEM   = 4,  // Number of elements in the demux
    parameter int ELEM_WIDTH = 1   // Width of each element
) (
    input  logic [$clog2(NUM_ELEM)-1:0]                 index_i,  // Input index for selection
    input  logic [      ELEM_WIDTH-1:0]                 data_i,   // Input data to be demultiplexed
    output logic [        NUM_ELEM-1:0][ELEM_WIDTH-1:0] out_o     // Output array for demuxed data
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NUM_ELEM-1:0] gnt;  // Grant signal for selecting the output element

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar elem = 0; elem < NUM_ELEM; elem++) begin : g_elem
    for (genvar bits = 0; bits < ELEM_WIDTH; bits++) begin : g_bits
      always_comb
        out_o[elem][bits] = gnt[elem] & data_i[bits];  // Assign data to output if granted
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  decoder_no_valid #(
      .NUM_WIRE(NUM_ELEM)  // Number of wires for the decoder
  ) u_decoder_no_valid (
      .index_i(index_i),  // Input index for the decoder
      .wire_o (gnt)       // Output grant signals from the decoder
  );

endmodule
