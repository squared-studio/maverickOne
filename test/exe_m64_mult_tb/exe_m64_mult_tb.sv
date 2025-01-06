/*
Description
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module exe_m64_mult_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 4ns, 6ns)

  logic        arst_ni = 1;

  // DUT signals
  logic        MUL_i;
  logic        MULH_i;
  logic        MULHSU_i;
  logic        MULHU_i;
  logic        MULW_i;
  logic [63:0] rs1_i;
  logic [63:0] rs2_i;
  logic [ 5:0] rd_i;
  logic        valid_i;
  logic        ready_o;
  logic [63:0] wr_data_o;
  logic [ 1:0] wr_size_o;
  logic [ 5:0] wr_addr_o;
  logic        valid_o;
  logic        ready_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit          test_failed = 0;
  event        e_mul;
  event        e_mulh;
  event        e_mulhsu;
  event        e_mulhu;
  event        e_mulw;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Instantiate the DUT
  exe_m64_mult dut (
      .clk_i(clk_i),
      .arst_ni(arst_ni),
      .MUL_i(MUL_i),
      .MULH_i(MULH_i),
      .MULHSU_i(MULHSU_i),
      .MULHU_i(MULHU_i),
      .MULW_i(MULW_i),
      .rs1_i(rs1_i),
      .rs2_i(rs2_i),
      .rd_i(rd_i),
      .valid_i(valid_i),
      .ready_o(ready_o),
      .wr_data_o(wr_data_o),
      .wr_size_o(wr_size_o),
      .wr_addr_o(wr_addr_o),
      .valid_o(valid_o),
      .ready_i(ready_i)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  task static apply_reset();
    #100ns;
    clk_i    <= '0;
    arst_ni  <= '0;
    MUL_i    <= '0;
    MULH_i   <= '0;
    MULHSU_i <= '0;
    MULHU_i  <= '0;
    MULW_i   <= '0;
    rs1_i    <= '0;
    rs2_i    <= '0;
    rd_i     <= '0;
    valid_i  <= '0;
    ready_i  <= '0;
    #100ns;
    arst_ni <= '1;
    #100ns;
  endtask

  task static drive_random();
    fork
      forever begin
        @(posedge clk_i);
        randcase
          1: begin
            MUL_i <= '1;
            MULH_i <= '0;
            MULHSU_i <= '0;
            MULHU_i <= '0;
            MULW_i <= '0;
          end
          1: begin
            MUL_i <= '0;
            MULH_i <= '1;
            MULHSU_i <= '0;
            MULHU_i <= '0;
            MULW_i <= '0;
          end
          1: begin
            MUL_i <= '0;
            MULH_i <= '0;
            MULHSU_i <= '1;
            MULHU_i <= '0;
            MULW_i <= '0;
          end
          1: begin
            MUL_i <= '0;
            MULH_i <= '0;
            MULHSU_i <= '0;
            MULHU_i <= '1;
            MULW_i <= '0;
          end
          1: begin
            MUL_i <= '0;
            MULH_i <= '0;
            MULHSU_i <= '0;
            MULHU_i <= '0;
            MULW_i <= '1;
          end
        endcase
        rs1_i   <= {$urandom, $urandom};
        rs2_i   <= {$urandom, $urandom};
        rd_i    <= $urandom;
        valid_i <= $urandom;
        ready_i <= $urandom;
      end
    join_none
  endtask

  task static start_checking();
    mailbox #(logic [ 5:0]) wr_addr_mbx = new();
    mailbox #(logic [63:0]) res_mbx = new();
    mailbox #(logic [ 1:0]) size_mbx = new();
    fork
      forever begin
        @(posedge clk_i);
        if (valid_i && ready_o) begin
          logic [ 63:0] multiplicand;
          logic [ 63:0] multiplier;
          logic [127:0] result;
          logic         negate;
          wr_addr_mbx.put(rd_i);
          multiplicand = '0;
          multiplier   = '0;
          result       = '0;
          negate       = '0;
          multiplicand = rs1_i;
          multiplier   = rs2_i;
          if (MULW_i) begin
            multiplicand = {{32{multiplicand[31]}}, multiplicand};
            multiplier   = {{32{multiplier[31]}}, multiplier};
          end
          if (MULW_i | MUL_i | MULH_i) begin
            negate = multiplier[63] ^ multiplicand[63];
            if (multiplicand[63]) multiplicand = ~multiplicand + 1;
            if (multiplier[63]) multiplier = ~multiplier + 1;
          end else if (MULHSU_i) begin
            negate = multiplicand[63];
            if (multiplicand[63]) multiplicand = ~multiplicand + 1;
          end
          result = multiplicand * multiplier;
          if (negate) result = ~result + 1;
          if (MULW_i) begin
            res_mbx.put({{32{result[31]}}, result[31:0]});
          end else if (MUL_i) begin
            res_mbx.put(result[63:0]);
          end else begin
            res_mbx.put(result[127:64]);
          end
          if (MULW_i) begin
            size_mbx.put(2);
          end else begin
            size_mbx.put(3);
          end
        end
        if (valid_o && ready_i) begin
          logic [ 5:0] wr_addr;
          logic [63:0] res;
          logic [ 1:0] size;
          wr_addr_mbx.get(wr_addr);
          res_mbx.get(res);
          size_mbx.get(size);
          if (wr_addr !== wr_addr_o) begin
            $display("%0t ADDR ERROR. EXP:0x%h GOT:0x%h", $realtime, wr_addr, wr_addr_o);
            test_failed = 1;
          end
          if (size === 2) begin
            if (res[31:0] !== wr_data_o[31:0]) begin
              $display("%0t DATA ERROR. EXP:0x%h GOT:0x%h", $realtime, res, wr_data_o);
              test_failed = 1;
            end
          end else begin
            if (res !== wr_data_o) begin
              $display("%0t DATA ERROR. EXP:0x%h GOT:0x%h", $realtime, res, wr_data_o);
              test_failed = 1;
            end
          end
          if (size !== wr_size_o) begin
            $display("%0t SIZE ERROR. EXP:0x%h GOT:0x%h", $realtime, size, wr_size_o);
            test_failed = 1;
          end
        end
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always @(posedge clk_i iff arst_ni) begin
    if (valid_i & ready_o & MUL_i)->e_mul;
    if (valid_i & ready_o & MULH_i)->e_mulh;
    if (valid_i & ready_o & MULHSU_i)->e_mulhsu;
    if (valid_i & ready_o & MULHU_i)->e_mulhu;
    if (valid_i & ready_o & MULW_i)->e_mulw;
  end

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  initial begin  // main initial

    apply_reset();
    start_clk_i();

    start_checking();
    drive_random();

    fork
      begin
        repeat (10000) @(e_mul);
        repeat (100) @(posedge clk_i);
      end
      begin
        repeat (10000) @(e_mulh);
        repeat (100) @(posedge clk_i);
      end
      begin
        repeat (10000) @(e_mulhsu);
        repeat (100) @(posedge clk_i);
      end
      begin
        repeat (10000) @(e_mulhu);
        repeat (100) @(posedge clk_i);
      end
      begin
        repeat (10000) @(e_mulw);
        repeat (100) @(posedge clk_i);
      end
    join

    result_print(!test_failed, "Multiplication");

    $finish;

  end

endmodule
