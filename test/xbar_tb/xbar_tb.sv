/*
Description
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module xbar_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NumInput = 4;  // Number of input ports
  localparam int NumOutput = 4;  // Number of output ports
  localparam int DataWidth = 4;  // Width of the data bus

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [DataWidth-1:0] data_t;  // Type definition for data
  typedef logic [NumOutput-1:0][$clog2(NumOutput)-1:0] select_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  data_t [NumInput-1:0] input_vector_i;
  data_t [NumOutput-1:0] output_vector_o;
  select_t select_vector_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  event e_out_success[NumOutput];

  bit in_out_ok;  // Flag to check input-output match
  int tx_success;  // Counter for successful transfers

  int count = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the pipeline module with specified parameters
  xbar #(
      .NUM_INPUT (NumInput),
      .NUM_OUTPUT(NumOutput),
      .DATA_WIDTH(DataWidth)
  ) u_xbar (
      .input_vector_i (input_vector_i),
      .output_vector_o(output_vector_o),
      .select_vector_i(select_vector_i)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to start input-output monitoring
  task automatic start_in_out_mon();
    in_out_ok  = 1;
    tx_success = 0;
    fork
      forever begin
        @(posedge clk_i);
        foreach (output_vector_o[i]) begin
          if (output_vector_o[i] !== input_vector_i[select_vector_i[i]]) begin
            in_out_ok = 0;
          end else begin
            ->e_out_success[i];
            tx_success += in_out_ok;
          end
        end
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        select_vector_i <= $urandom;
        input_vector_i  <= $urandom;
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i) begin
    if (count == NumOutput) begin
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
    $display("Success %d", tx_success);
    result_print(0, "FATAL TIMEOUT");
    $finish;
  end

  // Initial block to start clock, monitor & drive
  initial begin
    start_clk_i();
    start_in_out_mon();
    start_random_drive();
  end

  for (genvar i = 0; i < NumOutput; i++) begin : g_forks
    initial begin
      repeat (100) @(e_out_success[i]);
      result_print(1, $sformatf("Output mux %d cleared", i));
      count++;
    end
  end

endmodule
