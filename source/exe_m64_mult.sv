/*
Write a markdown documentation for this systemverilog module:
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module exe_m64_mult #(
) (
    input logic clk_i,
    input logic arst_ni,

    input  logic        MUL_i,
    input  logic        MULH_i,
    input  logic        MULHSU_i,
    input  logic        MULHU_i,
    input  logic        MULW_i,
    input  logic [63:0] rs1_i,
    input  logic [63:0] rs2_i,
    input  logic [5:0]  rd_i,
    input  logic        valid_i,
    output logic        ready_o,

    output logic [63:0] wr_data_o,
    output logic [ 1:0] wr_sig_ext_o,
    output logic [ 5:0] wr_addr_o,
    output logic        valid_o,
    input  logic        ready_i
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic q0_valid;
  logic q0_ready;

  logic q0_q1_valid;
  logic q0_q1_ready;

  logic q1_q2_valid;
  logic q1_q2_ready;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //        _            _ _                       ___
  //  _ __ (_)_ __   ___| (_)_ __   ___      __ _ / _ \
  // | '_ \| | '_ \ / _ \ | | '_ \ / _ \    / _` | | | |
  // | |_) | | |_) |  __/ | | | | |  __/   | (_| | |_| |
  // | .__/|_| .__/ \___|_|_|_| |_|\___|    \__, |\___/
  // |_|     |_|                               |_|
  //
  //////////////////////////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////
  // FUNC IDENTIFY
  ////////////////////////////////////////////////

  wor   this_module;

  assign this_module = MUL_i;
  assign this_module = MULH_i;
  assign this_module = MULHSU_i;
  assign this_module = MULHU_i;
  assign this_module = MULW_i;

  ////////////////////////////////////////////////
  // INITIAL VALID READY
  ////////////////////////////////////////////////

  assign q0_valid = this_module & valid_i;
  assign ready_o = this_module & q0_ready;

  ////////////////////////////////////////////////
  // MULTIPLIER, MULTIPLICAND, SIGN, WORD, RD
  ////////////////////////////////////////////////

  logic [63:0] multiplier;
  logic [63:0] multiplicand;
  logic [ 1:0] sign;  // {signed, negative}

  always_comb begin
    multiplier   = rs2_i;
    multiplicand = rs1_i;
    sign         = '0;

    if (MULW_i) begin
      multiplier   = {{32{rs2_i[31]}}, rs2_i[31:0]};
      multiplicand = {{32{rs1_i[31]}}, rs1_i[31:0]};
    end

    if (MUL_i | MULH_i | MULW_i) begin
      sign[0] = multiplier[63] ^ multiplicand[63];
      if (multiplier[63]) multiplier = ~multiplier + 1;
      multiplier[63] = '0;
      if (multiplicand[63]) multiplicand = ~multiplicand + 1;
      multiplicand[63] = '0;

    end else if (MULHSU_i) begin
      sign[0] = multiplicand[63];
      if (multiplicand[63]) multiplicand = ~multiplicand + 1;
      multiplicand[63] = '0;

    end

  end

  logic upper;
  always_comb upper = MULH_i | MULHSU_i | MULHU_i;

  logic word;
  always_comb word = MULW_i;

  logic [63:0] res_0001;
  logic [64:0] res_0011;
  logic [65:0] res_0111;
  logic [65:0] res_0101;
  logic [66:0] res_1001;
  logic [66:0] res_1011;
  logic [66:0] res_1101;
  logic [66:0] res_1111;

  always_comb res_0001 = multiplicand;
  always_comb res_0011 = {res_0001, 1'b0} + res_0001;
  always_comb res_0111 = {res_0001, 2'b0} + res_0011;
  always_comb res_0101 = {res_0001, 2'b0} + res_0001;
  always_comb res_1001 = {res_0001, 3'b0} + res_0001;
  always_comb res_1011 = {res_0001, 1'b0} + res_1001;
  always_comb res_1101 = {res_0001, 2'b0} + res_1001;
  always_comb res_1111 = {res_0011, 2'b0} + res_0011;

  logic [5:0]  rd_q0;
  logic        word_q0;
  logic        upper_q0;
  logic [ 1:0] sign_q0;
  logic [63:0] res_0001_q0;
  logic [64:0] res_0011_q0;
  logic [65:0] res_0111_q0;
  logic [65:0] res_0101_q0;
  logic [66:0] res_1001_q0;
  logic [66:0] res_1011_q0;
  logic [66:0] res_1101_q0;
  logic [66:0] res_1111_q0;
  logic [63:0] multiplier_q0;

  pipeline #(
      .DW($bits({rd_q0, word_q0, upper_q0, sign_q0,
                 res_0001_q0, res_0011_q0, res_0111_q0, res_0101_q0,
                 res_1001_q0, res_1011_q0, res_1101_q0, res_1111_q0,
                 multiplier_q0}))
  ) u_q0 (
      .arst_ni, .clk_i, .clear_i('0),

      .data_in_i({rd_i, word, upper, sign,
                  res_0001, res_0011, res_0111, res_0101,
                  res_1001, res_1011, res_1101, res_1111,
                  multiplier}),
      .data_in_valid_i(q0_valid), .data_in_ready_o(q0_ready),

      .data_out_o({rd_q0, word_q0, upper_q0, sign_q0,
                   res_0001_q0, res_0011_q0, res_0111_q0, res_0101_q0,
                   res_1001_q0, res_1011_q0, res_1101_q0, res_1111_q0,
                   multiplier_q0}),
      .data_out_valid_o(q0_q1_valid), .data_out_ready_i(q0_q1_ready)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //        _            _ _                      _
  //  _ __ (_)_ __   ___| (_)_ __   ___      __ _/ |
  // | '_ \| | '_ \ / _ \ | | '_ \ / _ \    / _` | |
  // | |_) | | |_) |  __/ | | | | |  __/   | (_| | |
  // | .__/|_| .__/ \___|_|_|_| |_|\___|    \__, |_|
  // |_|     |_|                               |_|
  //
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [15:0][66:0] ext67_res;
  logic [15:0][66:0] xbar_out;

  always_comb ext67_res['b0000] = '0;
  always_comb ext67_res['b0001] = res_0001_q0;
  always_comb ext67_res['b0010] = {res_0001_q0, 1'b0};
  always_comb ext67_res['b0011] = res_0011_q0;
  always_comb ext67_res['b0100] = {res_0001_q0, 2'b0};
  always_comb ext67_res['b0101] = res_0101_q0;
  always_comb ext67_res['b0110] = {res_0011_q0, 1'b0};
  always_comb ext67_res['b0111] = res_0111_q0;
  always_comb ext67_res['b1000] = {res_0001_q0, 3'b0};
  always_comb ext67_res['b1001] = res_1001_q0;
  always_comb ext67_res['b1010] = {res_0101_q0, 1'b0};
  always_comb ext67_res['b1011] = res_1011_q0;
  always_comb ext67_res['b1100] = {res_0011_q0, 2'b0};
  always_comb ext67_res['b1101] = res_1101_q0;
  always_comb ext67_res['b1110] = {res_0111_q0, 1'b0};
  always_comb ext67_res['b1111] = res_1111_q0;

  xbar #(
      .NUM_INPUT (16),
      .NUM_OUTPUT(16),
      .DATA_WIDTH(67)
  ) u_xbar (
      .input_vector_i(ext67_res),
      .output_vector_o(xbar_out),
      .select_vector_i(multiplier_q0)
  );

  logic [15:0][78:0] ext79;

  always_comb begin
    for (int i = 0; i < 16; i++) begin
      ext79['b0000] = xbar_out['b0000];
    end
  end

  logic [3:0][78:0] res79;

  always_comb begin
    for (int i = 0; i < 4; i++) begin
      res79[i] = ext79[i+3] + ext79[i+2] + ext79[i+1] + ext79[i+0];
    end
  end

  logic [5:0]  rd_q1;
  logic        word_q1;
  logic        upper_q1;
  logic [ 1:0] sign_q1;
  logic [3:0][78:0] res79_q1;

  pipeline #(
      .DW($bits({rd_q1, word_q1, upper_q1, sign_q1, res79_q1}))
  ) u_q1 (
      .arst_ni, .clk_i, .clear_i('0),

      .data_in_i({rd_q0, word_q0, upper_q0, sign_q0, res79}),
      .data_in_valid_i(q0_q1_valid), .data_in_ready_o(q0_q1_ready),

      .data_out_o({rd_q1, word_q1, upper_q1, sign_q1, res79_q1}),
      .data_out_valid_o(q1_q2_valid), .data_out_ready_i(q1_q2_ready)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //        _            _ _                      ____
  //  _ __ (_)_ __   ___| (_)_ __   ___      __ _|___ \
  // | '_ \| | '_ \ / _ \ | | '_ \ / _ \    / _` | __) |
  // | |_) | | |_) |  __/ | | | | |  __/   | (_| |/ __/
  // | .__/|_| .__/ \___|_|_|_| |_|\___|    \__, |_____|
  // |_|     |_|                               |_|
  //
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // TODO

`ifdef SIMULATION
  initial begin
    if (64 != 64) begin
      $fatal("\033[1;33m%m Unsupported XLEN\033[0m");
    end
  end
`endif  // SIMULATION

endmodule
