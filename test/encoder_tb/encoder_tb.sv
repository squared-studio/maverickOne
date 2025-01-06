/*
Description
The encoder module is designed to determine the position of the highest priority active signal among
multiple input wires. It encodes this position into an output index. This type of module is commonly
used in digital systems where it is necessary to identify which of several input signals is active
and assign a corresponding binary code to that signal. This functionality is crucial for
applications like priority encoders and resource arbitration.
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module encoder_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int NumWire = 16;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // apply typedef to repetitive code for readability
  typedef logic [NumWire-1:0] n_input;
  typedef logic [$clog2(NumWire)-1:0] n_output;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  n_input wire_in;  // encoder input bus
  n_output index_o;  // encoder output bus
  logic index_valid_o;  // output index is valid

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  int tx_total = 0;  // records total number of executions
  int ms_time_var = 1;  // records time elapsed

  bit in_out_ok;
  int tx_success = 0;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // assign buses to the correct encoder ports
  encoder #(
      .NUM_WIRE(NumWire)
  ) u_encoder (
      .wire_in,
      .index_o,
      .index_valid_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // monitor the changes in input and output
  task automatic start_in_out_mon();
    in_out_ok = 1;
    fork
      forever begin
        logic valid;
        @(posedge clk_i);
        valid = |wire_in;
        if (valid === '1) begin
          if ((index_valid_o === valid) && $clog2(wire_in) === index_o) begin
            tx_success++;
          end else begin
            in_out_ok = 0;
            $display("wire_in:0b%b EXP/GOT: index_valid_o:%0d/%0d index_o:%0d/%0d", wire_in, valid,
                     index_valid_o, $clog2(wire_in), index_o);
          end
        end
      end
    join_none
  endtask

  // drive the rtl module with random input values
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        wire_in <= ($urandom_range(0, 1) << $urandom_range(0, NumWire - 1));
        tx_total++;
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin
    forever begin
      @(posedge clk_i);
      if (tx_total == 100 * NumWire) begin
        $display("END OF SIMULATION B8TCH");
        $display("Number of total runs: %d", tx_total);
        result_print(in_out_ok, "Data Encoding");
        $display("Number of valid runs: %d", tx_success);
        $finish;
      end
    end
  end

  initial begin
    #1ms;
    result_print(0, "SOMETHING WENT WRONG");
    $fatal(1, "FATAL TIMEOUT B8TCH");
  end

  initial begin  // main initial
    start_clk_i();
    start_random_drive();
    start_in_out_mon();
  end

endmodule
