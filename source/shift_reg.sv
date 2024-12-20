/*
Shift Register with both Serial and Parallel input-output functionality.
Parallel loading feature can be enabled/disabled by setting PARALLEL_LOAD_ENABLE.
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module shift_reg #(
    parameter bit PARALLEL_LOAD_ENABLE = 1'b1,  // Enable for paprallel loading function
    parameter int NUM_STAGES = 4,               // Number of FF stages
    parameter int DATA_WIDTH = 8,               // Number of bits passing through the registers

    localparam type data_t = logic [DATA_WIDTH-1:0]
) (
    logic clk_i,    // Clock input
    logic arst_ni,  // Asynchronous Reset input

    input data_t serial_i,  // Serial Data input
    output data_t serial_o, // Serial Data Output

    input logic [NUM_STAGES-1:0] parallel_load_en_i,  // Parallel Load/Write Enables input
    input data_t [NUM_STAGES-1:0] parallel_loads_i,   // Parallel loads (values) input
    output data_t [NUM_STAGES-1:0] parallel_outs_o    // Parallel FF values output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_comb serial_o = parallel_outs_o[NUM_STAGES-1];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      parallel_outs_o <= '0;
    end
    else begin
      parallel_outs_o <= {parallel_outs_o[NUM_STAGES-2:0], serial_i};

      if (PARALLEL_LOAD_ENABLE) begin
        for (int i = 0; i < NUM_STAGES; i++) begin
          if (parallel_load_en_i[i]) parallel_outs_o[i] <= parallel_loads_i[i];
        end
      end
    end
  end

endmodule
