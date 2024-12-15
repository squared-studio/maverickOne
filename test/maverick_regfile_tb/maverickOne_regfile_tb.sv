/*
Description
Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module maverickOne_regfile_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"
  import maverickOne_pkg::NUM_REGS;
  import maverickOne_pkg::XLEN;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int AW = $clog2(NUM_REGS);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef logic [AW-1:0] addr_t;
  typedef logic [XLEN-1:0] data_t;
  typedef logic [NUM_REGS-1:0] num_reg_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic           arst_ni = 1;

  // RTL inputs
  addr_t          wr_unlock_addr_i;
  data_t          wr_unlock_data_i;
  logic           wr_unlock_en_i;
  logic           wr_lock_en_i;
  addr_t          wr_lock_addr_i;

  addr_t          rs1_addr_i;
  addr_t          rs2_addr_i;
  addr_t          rs3_addr_i;

  // RTL outputs
  num_reg_t       locks_o;
  data_t          rs1_data_o;
  data_t          rs2_data_o;
  data_t          rs3_data_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  data_t          ref_mem          [NUM_REGS];
  num_reg_t       lock_profile;
  logic           lock_at_reset;
  logic           lock_violation_n;
  logic     [2:0] read_error_n;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  maverickOne_regfile #() u_regfile (
      .arst_ni,
      .clk_i,
      .wr_unlock_addr_i,
      .wr_unlock_data_i,
      .wr_unlock_en_i,
      .wr_lock_en_i,
      .wr_lock_addr_i,
      .rs1_addr_i,
      .rs2_addr_i,
      .rs3_addr_i,
      .locks_o,
      .rs1_data_o,
      .rs2_data_o,
      .rs3_data_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_reset();
    lock_at_reset = 1;
    #100ns;
    arst_ni <= 0;
    #100ns;
    if (~(&(locks_o))) lock_at_reset = 0;
    foreach (ref_mem[i]) ref_mem[i] <= '0;
    lock_profile <= '0;
    arst_ni <= 1;
    #100ns;
  endtask

  task automatic start_random_drive();
    fork
      begin
        forever begin
          @(posedge clk_i);
          wr_lock_en_i <= $urandom_range(0, 99) < 50;
          wr_lock_addr_i <= $urandom;

          wr_unlock_en_i <= $urandom_range(0, 99) < 50;
          wr_unlock_addr_i <= $urandom;
          wr_unlock_data_i <= $urandom;

          rs1_addr_i <= $urandom;
          rs2_addr_i <= $urandom;
          rs3_addr_i <= $urandom;
        end
      end
    join_none
  endtask  // random drive task

  task automatic start_in_out_monitor();
    lock_violation_n <= '1;
    read_error_n <= '1;
    fork
      begin
        forever begin
          @(posedge clk_i);
          if (arst_ni) begin
            if (wr_unlock_en_i && (wr_unlock_addr_i !== 0)) begin
              ref_mem[wr_unlock_addr_i] <= wr_unlock_data_i;
              lock_profile[wr_unlock_addr_i] <= ~wr_unlock_en_i;
            end

            if (wr_lock_en_i && (wr_lock_addr_i !== 0)) begin
              lock_profile[wr_lock_addr_i] <= wr_lock_en_i;
            end

            if (locks_o !== lock_profile) begin
              lock_violation_n = 'b0;
            end
          end

          if (rs1_addr_i !== 'x) begin
            if (rs1_data_o !== ref_mem[rs1_addr_i]) begin
              read_error_n[0] = 'b0;
            end
          end
          if (rs2_addr_i !== 'x) begin
            if (rs2_data_o !== ref_mem[rs2_addr_i]) begin
              read_error_n[1] = 'b0;
            end
          end
          if (rs3_addr_i !== 'x) begin
            if (rs3_data_o !== ref_mem[rs3_addr_i]) begin
              read_error_n[2] = 'b0;
            end
          end
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial
    apply_reset();
    start_clk_i();
    start_random_drive();
    start_in_out_monitor();
  end

  initial begin
    repeat (1000001) @(posedge clk_i);
    result_print(lock_at_reset, "Reset Lockdown Check");
    result_print(lock_violation_n, "Lock Violation Check");
    result_print(read_error_n[0], "Rs1 Read Error Check");
    result_print(read_error_n[1], "Rs2 Read Error Check");
    result_print(read_error_n[2], "Rs3 Read Error Check");
    $finish;
  end

endmodule
