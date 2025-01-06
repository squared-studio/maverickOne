/*
This module generates simple AND gate for comparing a number with a constant expression. The output
of match is also predefined for both true and false.
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module constant_compare #(
    parameter int                IP_WIDTH    = 10,     // Width of the input signal
    parameter bit [IP_WIDTH-1:0] CMP_ENABLES = 'h0C3,  // Bitmask to enable comparisons
    parameter bit [IP_WIDTH-1:0] EXP_RESULT  = 'h082,  // Expected result for comparison
    parameter int                OP_WIDTH    = 2,      // Width of the output signal
    parameter bit [OP_WIDTH-1:0] MATCH_TRUE  = 1,      // Output value when there is a match
    parameter bit [OP_WIDTH-1:0] MATCH_FALSE = 2       // Output value when there is no match
) (
    input  logic [IP_WIDTH-1:0] in_i,  // Input signal
    output logic [OP_WIDTH-1:0] out_o  // Output signal
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS GENERATED
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef bit [31:0] bit32_t;  // Type definition for a 32-bit integer

  // Function to count the number of ones in CMP_ENABLES
  function automatic bit32_t count_ones();
    bit32_t count = 0;
    // Increment count for each bit that is 1
    foreach (CMP_ENABLES[i]) if (CMP_ENABLES[i]) count++;
    return count;
  endfunction

  localparam bit32_t NumCompares = count_ones();  // Number of comparisons to perform

  typedef bit32_t [NumCompares-1:0] index_t;  // Type definition for an index array

  // Function to generate an index array based on CMP_ENABLES
  function automatic index_t gen_index();
    index_t idx;
    int j = 0;
    for (int i = 0; i < IP_WIDTH; i++) begin
      if (CMP_ENABLES[i]) begin
        idx[j] = i;  // Store index of enabled comparisons
        j++;
      end
    end
    return idx;
  endfunction

  localparam index_t AndIndex = gen_index();  // Index array for enabled comparisons

  typedef bit [NumCompares-1:0] pol_t;  // Type definition for polarity array

  // Function to generate a polarity array based on EXP_RESULT
  function automatic pol_t gen_pol();
    pol_t idx;
    int   j = 0;
    for (int i = 0; i < IP_WIDTH; i++) begin
      if (CMP_ENABLES[i]) begin
        idx[j] = EXP_RESULT[i];  // Store expected result for enabled comparisons
        j++;
      end
    end
    return idx;
  endfunction

  localparam pol_t AndPol = gen_pol();  // Polarity array for expected results

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NumCompares-1:0] and_array;  // Array to store ANDed results
  logic                   is_match;  // Flag to indicate if there's a match

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Assign values to and_array based on in_i and AndPol
  always_comb begin
    foreach (and_array[i]) and_array[i] = AndPol[i] ? in_i[AndIndex[i]] : ~in_i[AndIndex[i]];
  end

  // Determine if there is any match
  always_comb is_match = &and_array;

  // Assign output based on is_match
  if (OP_WIDTH > 1) begin : g_mux
    always_comb out_o = is_match ? MATCH_TRUE : MATCH_FALSE;
  end else begin : g_pass
    if (MATCH_TRUE == 1 && MATCH_FALSE == 0) begin : g_pass
      always_comb out_o = is_match;
    end else begin : g_inv
      always_comb out_o = ~is_match;
    end
  end

endmodule
