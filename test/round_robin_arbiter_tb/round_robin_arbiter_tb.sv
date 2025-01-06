/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module round_robin_arbiter_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NumReq = 4;  // number of requesters

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [NumReq-1:0] n_req_gnt;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic arst_ni;  // asynchronous reset
  logic allow_i = '1;  // allow requests
  n_req_gnt req_i;  // input requests register
  n_req_gnt gnt_o;  // output grants register
  logic gnt_found_o;  // output grants found

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int tx_counter = 0;  // number of requests made
  event req_gnt_event[NumReq];  // requester request event
  int outage_counter;  // no. of times allow_i disabled
  int requester_threshold = 5000;  // requester grant quota
  bit [NumReq-1:0] req_satisfied = '0;  // requester grant quota met
  int rg_count[NumReq];  // no. of requests granted per requester

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  round_robin_arbiter #(
      .NUM_REQ(NumReq)
  ) u_rra_tb_1 (
      .arst_ni,
      .clk_i,
      .allow_i,
      .req_i,
      .gnt_o,
      .gnt_found_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic apply_reset();
    @(posedge clk_i);
    #1ns;
    arst_ni <= 0;
    @(posedge clk_i);
    #1ns;
    arst_ni <= 1;
  endtask

  task automatic start_random_driver();
    outage_counter = 0;
    @(posedge clk_i);
    fork
      begin
        forever begin
          @(posedge clk_i);
          allow_i <= $urandom_range(0, 99) > 2;  // 2% Outage Probability
          req_i   <= $urandom;
          @(negedge clk_i);
          tx_counter++;
        end
      end
    join_none
  endtask

  always @(posedge clk_i) begin
    if (arst_ni === '1 & allow_i === '1) begin
      if (gnt_found_o !== (|gnt_o))
        result_print(0, $sformatf(
                     "gnt_o:0b%b gnt_found_o:%0d arst_ni:%0d allow_i:%0d",
                     gnt_o,
                     gnt_found_o,
                     arst_ni,
                     allow_i
                     ));
    end
  end

  task automatic start_in_out_monitor();
    fork
      forever begin
        @(posedge clk_i);
        // $write("sim_time: [%.3t]\t", $realtime);
        // $write("requests allowed: %0d\t", allow_i);
        // $write("requests profile: 0b%b\t", req_i);
        // $write("grants profile: 0b%b \n", gnt_o);
        if (allow_i & arst_ni)->req_gnt_event[chk_req_gnt(gnt_o)];
        else if (~allow_i) outage_counter++;
      end
    join_none
  endtask

  function automatic int chk_req_gnt(n_req_gnt granted);
    for (int i = 0; i < NumReq; i++) begin
      if (granted[i] === 1) return i;
    end
  endfunction  // check which requester was granted

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  for (genvar i = 0; i < NumReq; i++) begin : g_req_gnt_count_forks
    always @(req_gnt_event[i]) begin
      rg_count[i] <= rg_count[i] + 1;
      if (rg_count[i] == requester_threshold) begin
        req_satisfied[i] <= 1;
        result_print(1, $sformatf("Requester %4d Grants Quota Met", i + 1));
      end
    end
  end  // check for no. requests granted per requester.
  // test passed when all requester quotas are met within time limit

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    start_clk_i();
    apply_reset();
    start_random_driver();
    start_in_out_monitor();
  end

  initial begin
    forever begin
      @(posedge clk_i);
      if (&req_satisfied) begin
        $write("Outage: %3d times\t", outage_counter);
        $write("total cycles ran: %3d\n", tx_counter);
        foreach (rg_count[i]) begin
          $write("Requester %3d called: %3d times\n", i, rg_count[i]);
        end
        $write("Simulation Done\n");
        result_print(&req_satisfied, "Preservation of Arbitration Fairness before timeout");
        $finish;
      end
    end
  end

  initial begin
    #1ms;
    $write("Outage: %3d times\t", outage_counter);
    $write("total cycles ran: %3d\n", tx_counter);
    foreach (rg_count[i]) begin
      $write("Requester %3d called: %3d times\n", i, rg_count[i]);
    end
    result_print(&req_satisfied, "Preservation of Arbitration Fairness before timeout");
    $fatal(0, "TIMEOUT");
    $finish;
  end

  initial begin
    foreach (rg_count[i]) begin
      rg_count[i] = 0;
    end
  end

endmodule
