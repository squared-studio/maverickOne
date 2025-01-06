/*
The fixed_priority_arbiter module manages multiple request signals and grants access based on a
fixed priority system. It ensures that the highest priority request is serviced first by generating
grant signals for the active request with the highest priority. This is useful in systems where
certain tasks need to be prioritized over others to ensure efficient resource allocation and system
performance. The module is parameterized to handle a configurable number of request signals,
providing flexibility for various applications.

**req_i[0] has the highest priority**

Author: Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module fixed_priority_arbiter #(
    parameter int NUM_REQ = 4  // Number of requests
) (
    input logic               allow_i,  // Allow Request
    input logic [NUM_REQ-1:0] req_i,    // Request inputs

    output logic [NUM_REQ-1:0] gnt_o  // Grant outputs
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [NUM_REQ-1:0] req_found;  // Signals to track requests

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Calculate req_found, which indicates if any higher-priority request has been granted
  always_comb req_found[0] = req_i[0];  // First request signal
  for (genvar i = 1; i < NUM_REQ; i++) begin : g_msb_req_found
    always_comb req_found[i] = req_found[i-1] | req_i[i];  // OR operation to find requests
  end

  // Calculate grant outputs based on the req_found signals
  always_comb gnt_o[0] = req_i[0] & allow_i;  // Grant signal for the first request
  for (genvar i = 1; i < NUM_REQ; i++) begin : g_msb_gnt
    always_comb gnt_o[i] = req_i[i] & ~req_found[i-1] & allow_i;  // Generate grant signals
  end

endmodule
