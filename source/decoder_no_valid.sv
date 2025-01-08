/*
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module decoder_no_valid #(
    parameter int NUM_WIRE = 4  // Number of output wires
) (
    input  logic [$clog2(NUM_WIRE)-1:0] index_i,  // Input index
    output logic [        NUM_WIRE-1:0] wire_o    // Output wires
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generate constant compare instances for each wire
  for (genvar i = 0; i < NUM_WIRE; i++) begin : g_const_comp
    constant_compare #(
        .IP_WIDTH   ($clog2(NUM_WIRE)),  // Width of the input index
        .CMP_ENABLES('1),                 // Enable comparison
        .EXP_RESULT (i),                  // Expected result for comparison
        .OP_WIDTH   (1),                  // Output width
        .MATCH_TRUE ('1),                 // Output value when match is true
        .MATCH_FALSE('0)                  // Output value when match is false
    ) u_constant_compare (
        .in_i (index_i),                  // Input index
        .out_o(wire_o[i])                // Output wire
    );
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

`ifdef SIMULATION
  initial begin
    if (NUM_WIRE < 2) begin
      $fatal(1, "\033[1;33m%m is unnecessary\033[0m");  // Fatal error if NUM_WIRE is less than 2
    end
  end
`endif  // SIMULATION

endmodule
