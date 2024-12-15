/*
Description
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module rotating_xbar_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NumData = 4;  // Number of input and output ports
  localparam int DataWidth = 4;  // Width of the data bus

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [DataWidth-1:0] data_t;  // Type definition for data
  typedef logic [$clog2(NumData)-1:0] select_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  data_t [NumData-1:0] input_vector_i;
  data_t [NumData-1:0] output_vector_o;
  select_t start_select_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  event e_select_success[NumData];

  bit in_out_ok;  // Flag to check input-output match
  int tx_success;  // Counter for successful transfers
  int count = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the pipeline module with specified parameters
  rotating_xbar #(
      .NUM_DATA  (NumData),
      .DATA_WIDTH(DataWidth)
  ) u_rotating_xbar (
      .input_vector_i (input_vector_i),
      .output_vector_o(output_vector_o),
      .start_select_i (start_select_i)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to start input-output monitoring
  task automatic start_in_out_mon();
    int j = 0;
    int sel;
    in_out_ok  = 1;
    tx_success = 0;

    fork
      forever begin
        @(posedge clk_i);
        j   = 0;
        sel = start_select_i;
        // Loop to check each output line
        for (j = 0; j < NumData; j++) begin
          if (output_vector_o[j] !== input_vector_i[(sel+j)%NumData]) begin
            break;
          end
        end

        if (j == NumData) begin
          ->e_select_success[sel];
          tx_success++;
        end else in_out_ok = 0;
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        start_select_i <= $urandom;
        input_vector_i <= $urandom;
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i) begin
    if (count == NumData) begin
      result_print(in_out_ok, $sformatf("Data integrity. %0d transfers", tx_success));
      $finish;
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Initial block to handle fatal timeout
  initial begin
    #1ms;
    $display("Success = %d", tx_success);
    result_print(0, "FATAL TIMEOUT");
    $finish;
  end

  // Initial block to start clock, monitor & drive
  initial begin
    start_clk_i();
    start_in_out_mon();
    start_random_drive();
  end

  for (genvar i = 0; i < NumData; i++) begin : g_forks
    initial begin
      repeat (100) @(e_select_success[i]);
      result_print(1, $sformatf("start_select = %d cleared", i));
      count++;
    end
  end

endmodule
