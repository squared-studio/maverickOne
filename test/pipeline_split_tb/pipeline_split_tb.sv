/*
Description
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module pipeline_split_tb;

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

  logic  arst_ni;  // Asynchronous reset

  logic  clear_i;  // Clear signal
  data_t data_in_i;  // Data input
  logic  data_in_valid_i;  // Data input valid signal
  logic  data_in_ready_o;  // Data input ready signal
  data_t data_out_main_o;  // Main Data output
  logic  data_out_main_valid_o;  // Main Data output valid signal
  logic  data_out_main_ready_i;  // Main Data output ready signal
  data_t data_out_secondary_o;  // Secondary Data output
  logic  data_out_secondary_valid_o;  // Secondary Data output valid signal
  logic  data_out_secondary_ready_i;  // Secondary Data output ready signal

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  event  e_buffer_clear;  // Event for buffer clear
  event  e_push_only;  // Event for push only

  event  e_main_pop_only;  // Event for main pop only
  event  e_secondary_pop_only;  // Event for secondary pop only

  event  e_push_main_pop;  // Event for push and main-only pop
  event  e_push_secondary_pop;  // Event for push and secondary-only pop

  event  e_both_pop;  // Event for both main AND secondary pop only - should NOT happen

  bit    in_out_ok;  // Flag to check input-output match
  int    tx_success;  // Counter for successful transfers

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the pipeline_split module with specified parameters
  pipeline_split #(
      .DW(DW)
  ) u_pipeline_split (
      .arst_ni,
      .clk_i,
      .clear_i,
      .data_in_i,
      .data_in_valid_i,
      .data_in_ready_o,
      .data_out_main_o,
      .data_out_main_valid_o,
      .data_out_main_ready_i,
      .data_out_secondary_o,
      .data_out_secondary_valid_o,
      .data_out_secondary_ready_i
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Task to apply reset to the module
  task static apply_reset();
    result_print((data_in_ready_o === 'x), "data_in_ready_o X at before reset");
    result_print((data_out_main_valid_o === 'x), "data_out_main_valid_o X at before reset");
    result_print((data_out_secondary_valid_o === 'x),
                 "data_out_secondary_valid_o X at before reset");
    #100ns;
    arst_ni                    <= '0;
    clk_i                      <= '0;
    clear_i                    <= '0;
    data_in_i                  <= '0;
    data_in_valid_i            <= '0;
    data_out_main_ready_i      <= '0;
    data_out_secondary_ready_i <= '0;
    #100ns;
    result_print((data_in_ready_o === '0), "data_in_ready_o 0 during reset");
    result_print((data_out_main_valid_o === '0), "data_out_main_valid_o 0 during reset");
    result_print((data_out_secondary_valid_o === '0), "data_out_secondary_valid_o 0 during reset");
    arst_ni <= 1;
    #100ns;
    result_print((data_in_ready_o === '1), "data_in_ready_o 1 after reset");
    result_print((data_out_main_valid_o === '0), "data_out_main_valid_o 0 after reset");
    result_print((data_out_secondary_valid_o === '0), "data_out_secondary_valid_o 0 after reset");
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
    data_t main_out__;
    data_t secondary_out__;
    mailbox #(data_t) in_mbx = new();
    mailbox #(data_t) main_out_mbx = new();
    mailbox #(data_t) secondary_out_mbx = new();
    in_out_ok  = 1;
    tx_success = 0;
    fork
      forever begin
        @(posedge clk_i or negedge arst_ni);

        if (arst_ni && ~clear_i) begin  // Not reset or clear
          if (data_in_valid_i === 1 && data_in_ready_o === 1) in_mbx.put(data_in_i);

          if (data_out_main_valid_o === 1 && data_out_main_ready_i === 1)
            main_out_mbx.put(data_out_main_o);
          if (data_out_secondary_valid_o === 1 && data_out_secondary_ready_i === 1)
            secondary_out_mbx.put(data_out_secondary_o);

          if (in_mbx.num() && (main_out_mbx.num() || secondary_out_mbx.num())) begin
            in_mbx.get(in__);

            if (main_out_mbx.num()) begin
              main_out_mbx.get(main_out__);
              if (in__ !== main_out__) in_out_ok = 0;
              else tx_success++;
            end
            if (secondary_out_mbx.num()) begin
              secondary_out_mbx.get(secondary_out__);
              if (in__ !== secondary_out__) in_out_ok = 0;
              else tx_success++;
            end
          end
        end else begin
          while (in_mbx.num()) in_mbx.get(in__);
          while (main_out_mbx.num()) main_out_mbx.get(main_out__);
          while (secondary_out_mbx.num()) secondary_out_mbx.get(secondary_out__);
        end
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        clear_i                    <= ($urandom_range(0, 99) < 2);  // 2% odds of getting 1
        data_in_i                  <= $urandom;
        data_in_valid_i            <= ($urandom_range(0, 99) < 50);  // 50% odds of getting 1
        data_out_main_ready_i      <= ($urandom_range(0, 99) < 50);  // 50% odds of getting 1
        data_out_secondary_ready_i <= ($urandom_range(0, 99) < 75);  // 75% odds of getting 1
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////


  always @(posedge clk_i iff arst_ni) begin
    // Sequential block to trigger buffer clear event
    if (clear_i === 1) begin
      ->e_buffer_clear;
    end else begin
      // Sequential block to trigger push only event
      if ((data_in_valid_i
          & data_in_ready_o
          & ~data_out_main_valid_o
          & ~data_out_secondary_valid_o) === 1)
      begin
        ->e_push_only;
      end

      // Sequential block to trigger main output pop only event
      if ((~data_in_valid_i
          & data_out_main_valid_o
          & data_out_main_ready_i
          & ~data_out_secondary_valid_o) === 1)
      begin
        ->e_main_pop_only;
      end

      // Sequential block to trigger secondary output pop only event
      if ((~data_in_valid_i
          & data_out_secondary_valid_o
          & data_out_secondary_ready_i
          & ~data_out_main_ready_i) === 1)
      begin
        ->e_secondary_pop_only;
      end

      // Sequential block to trigger both output pop event
      if ((data_out_main_ready_i
          & data_out_secondary_valid_o) === 1)
      begin
        ->e_both_pop;
      end

      // Sequential block to trigger push and main-pop-only event
      if ((data_in_valid_i
          & data_in_ready_o
          & data_out_main_valid_o
          & data_out_main_ready_i
          & ~data_out_secondary_valid_o) === 1)
      begin
        ->e_push_main_pop;
      end

      // Sequential block to trigger push and secondary-pop-only event
      if ((data_in_valid_i
          & data_in_ready_o
          & data_out_secondary_valid_o
          & data_out_secondary_ready_i
          & ~data_out_main_ready_i) === 1) begin
        ->e_push_secondary_pop;
      end
    end
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Initial block to handle fatal timeout
  initial begin
    #5ms;
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

  initial begin
    @(e_both_pop);
    result_print(0, "Both main and secondary popped!");
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
        repeat (100) @(e_main_pop_only);
        $display("Pipeline main Pop only - applied");
      end
      begin
        repeat (100) @(e_secondary_pop_only);
        $display("Pipeline secondary Pop only - applied");
      end
      begin
        repeat (100) @(e_push_main_pop);
        $display("Pipeline Push main-Pop-only - applied");
      end
      begin
        repeat (100) @(e_push_secondary_pop);
        $display("Pipeline Push secondary-Pop-only - applied");
      end
    join

    result_print(in_out_ok && tx_success, $sformatf("Data integrity. %0d transfers", tx_success));

    $finish;

  end

endmodule
