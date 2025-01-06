/*
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module pipeline_tb;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Bring in the testbench essential functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int DW = 8;  // Data width

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [DW-1:0] data_t;  // Type definition for data

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic arst_ni;  // Asynchronous reset

  logic clear_i;  // Clear signal
  data_t data_in_i;  // Data input
  logic data_in_valid_i;  // Data input valid signal
  logic data_in_ready_o;  // Data input ready signal
  data_t data_out_o;  // Data output
  logic data_out_valid_o;  // Data output valid signal
  logic data_out_ready_i;  // Data output ready signal

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  event e_buffer_clear;  // Event for buffer clear
  event e_push_only;  // Event for push only
  event e_pop_only;  // Event for pop only
  event e_push_pop;  // Event for push and pop

  bit in_out_ok;  // Flag to check input-output match
  int tx_success;  // Counter for successful transfers

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the pipeline module with specified parameters
  pipeline #(
      .DW(DW)
  ) u_pipeline (
      .arst_ni,
      .clk_i,
      .clear_i,
      .data_in_i,
      .data_in_valid_i,
      .data_in_ready_o,
      .data_out_o,
      .data_out_valid_o,
      .data_out_ready_i
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to apply reset to the module
  task static apply_reset();
    result_print((data_in_ready_o === 'x), "data_in_ready_o X at before reset");
    result_print((data_out_valid_o === 'x), "data_out_valid_o X at before reset");
    #100ns;
    arst_ni          <= '0;
    clk_i            <= '0;
    clear_i          <= '0;
    data_in_i        <= '0;
    data_in_valid_i  <= '0;
    data_out_ready_i <= '0;
    #100ns;
    result_print((data_in_ready_o === '0), "data_in_ready_o 0 during reset");
    result_print((data_out_valid_o === '0), "data_out_valid_o 0 during reset");
    arst_ni <= 1;
    #100ns;
    result_print((data_in_ready_o === '1), "data_in_ready_o 1 after reset");
    result_print((data_out_valid_o === '0), "data_out_valid_o 0 after reset");
  endtask

  // Task to clear the pipeline
  task automatic clear();
    clear_i <= '1;
    @(posedge clk_i);
    clear_i <= '0;
  endtask

  // Task to start input-output monitoring
  task automatic start_in_out_mon();
    data_t in__;
    data_t out__;
    mailbox #(data_t) in_mbx = new();
    mailbox #(data_t) out_mbx = new();
    in_out_ok  = 1;
    tx_success = 0;
    fork
      forever begin
        @(posedge clk_i or negedge arst_ni);
        if (arst_ni && ~clear_i) begin
          if (data_in_valid_i === 1 && data_in_ready_o === 1) in_mbx.put(data_in_i);
          if (data_out_valid_o === 1 && data_out_ready_i === 1) out_mbx.put(data_out_o);
          if (in_mbx.num() && out_mbx.num()) begin
            in_mbx.get(in__);
            out_mbx.get(out__);
            if (in__ !== out__) in_out_ok = 0;
            else tx_success++;
          end
        end else begin
          while (in_mbx.num()) in_mbx.get(in__);
          while (out_mbx.num()) out_mbx.get(out__);
        end
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        clear_i          <= ($urandom_range(0, 99) < 2);  // 2% odds of getting 1
        data_in_i        <= $urandom;
        data_in_valid_i  <= ($urandom_range(0, 99) < 50);  // 50% odds of getting 1
        data_out_ready_i <= ($urandom_range(0, 99) < 50);  // 50% odds of getting 1
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Sequential block to trigger buffer clear event
  always @(posedge clk_i iff arst_ni) begin
    if (clear_i === 1) begin
      ->e_buffer_clear;
    end
  end

  // Sequential block to trigger push only event
  always @(posedge clk_i iff arst_ni) begin
    if ((data_in_valid_i & data_in_ready_o & ~data_out_valid_o & ~clear_i) === 1) begin
      ->e_push_only;
    end
  end

  // Sequential block to trigger pop only event
  always @(posedge clk_i iff arst_ni) begin
    if ((~data_in_valid_i & data_out_valid_o & data_out_ready_i & ~clear_i) === 1) begin
      ->e_pop_only;
    end
  end

  // Sequential block to trigger push and pop event
  always @(posedge clk_i iff arst_ni) begin
    if ((data_in_valid_i & data_in_ready_o & data_out_valid_o & data_out_ready_i & ~clear_i) === 1)
    begin
      ->e_push_pop;
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Initial block to handle fatal timeout
  initial begin
    #1ms;
    result_print(0, "FATAL TIMEOUT");
    $finish;
  end

  // Initial block to apply reset, start clock, monitor & drive
  initial begin
    apply_reset();
    start_clk_i();
    start_in_out_mon();
    start_random_drive();
  end

  // Initial block to handle events and display results
  initial begin
    fork
      begin
        repeat (100) @(e_buffer_clear);
        $display("Pipeline Clear - applied");
      end
      begin
        repeat (100) @(e_push_only);
        $display("Pipeline Push only - applied");
      end
      begin
        repeat (100) @(e_pop_only);
        $display("Pipeline Pop only - applied");
      end
      begin
        repeat (100) @(e_push_pop);
        $display("Pipeline Push Pop - applied");
      end
    join

    result_print(in_out_ok && tx_success, $sformatf("Data integrity. %0d transfers", tx_success));

    $finish;

  end

endmodule
