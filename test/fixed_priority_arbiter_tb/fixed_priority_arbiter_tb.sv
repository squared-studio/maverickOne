/*
Description
Author : S. M. Tahmeed Reza (tahmeedreza@gmail.com)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module fixed_priority_arbiter_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NumReq = 4;  // number of requests

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [NumReq-1:0] n_rqst_gnt;  // typedef for request_in and grant_out

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic allow_i;
  n_rqst_gnt req_i;  // arbiter requesters var
  n_rqst_gnt gnt_o;  // arbiter grants var

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit priority_violation_flag = 0;  // flag: check for priority violation
  int n_sent = 0;  // number of total requests
  event end_trigger;  // number of successful hand-offs
  int rqrd_transactions;  // define no. of simulation runs

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  fixed_priority_arbiter #(
      .NUM_REQ(NumReq)
  ) u_fpa_1 (
      .allow_i,
      .req_i,
      .gnt_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task automatic start_random_driver();
    fork
      forever begin
        @(posedge clk_i);
        allow_i <= $urandom();
        req_i   <= $urandom();
        n_sent++;
      end
    join_none
  endtask  // drives a random input into the RTL

  task automatic start_in_out_mon();
    priority_violation_flag = 0;
    fork
      forever begin
        @(posedge clk_i);
        if (allow_i) begin
          if ((priority_idx(req_i) === priority_idx(gnt_o))) begin
          end else begin
            priority_violation_flag = 1;
            ->end_trigger;
          end
        end else if (allow_i === 0 && gnt_o !== 0) begin
          priority_violation_flag = 1;
          ->end_trigger;
        end
      end
    join_none
  endtask  // monitors the input and output data in the mailbox for verification

  function automatic integer priority_idx(n_rqst_gnt data_x);
    for (integer i = 0; i < NumReq; i++) begin
      if (data_x[i] === 1) return i;
    end
  endfunction  // software function for returning index of msb

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    start_clk_i();
    start_random_driver();
    start_in_out_mon();
  end

  initial begin
    rqrd_transactions = 1000;
    fork
      begin
        forever begin
          @(posedge clk_i);
          #4ns;
          if (n_sent == rqrd_transactions) begin
            $display("Required Number of Transactions [%0d] Completed", n_sent);
            result_print(!priority_violation_flag, "Requester Priority Violation Check");
            $finish;
          end
        end
      end
      begin
        @(end_trigger);
        $display("Number of Transactions [%0d] Completed", n_sent);
        result_print(!priority_violation_flag, "Requester Priority Violation Check");
        $finish;
      end
    join
  end

endmodule
