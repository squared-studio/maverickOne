/*
Write a markdown documentation for this systemverilog module:
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module exe_mult #(
    localparam int XLEN = maverickOne_pkg::XLEN
) (
    input logic clk_i,
    input logic arst_ni,

    input  logic valid_i,
    output logic ready_o,

    input logic MUL_i,
    input logic MULH_i,
    input logic MULHSU_i,
    input logic MULHU_i,
    input logic MUW_i,

    output logic valid_o,
    input  logic ready_i,

    input logic [XLEN-1:0] rs1_i,

    output logic [1023:0] out
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  wor this_module;

  logic pipeline_init_ready;

  logic [XLEN-1:0] multiplicand_i;

  logic [XLEN-1:0] res_0001_d;
  logic [XLEN : 0] res_0011_d;
  logic [XLEN+1:0] res_0111_d;
  logic [XLEN+1:0] res_0101_d;
  logic [XLEN+2:0] res_1001_d;
  logic [XLEN+2:0] res_1011_d;
  logic [XLEN+2:0] res_1101_d;
  logic [XLEN+2:0] res_1111_d;

  logic [XLEN-1:0] res_0001_q;
  logic [XLEN : 0] res_0011_q;
  logic [XLEN+1:0] res_0111_q;
  logic [XLEN+1:0] res_0101_q;
  logic [XLEN+2:0] res_1001_q;
  logic [XLEN+2:0] res_1011_q;
  logic [XLEN+2:0] res_1101_q;
  logic [XLEN+2:0] res_1111_q;

  logic [XLEN+2:0] ext_res_0000_q;
  logic [XLEN+2:0] ext_res_0001_q;
  logic [XLEN+2:0] ext_res_0010_q;
  logic [XLEN+2:0] ext_res_0011_q;
  logic [XLEN+2:0] ext_res_0100_q;
  logic [XLEN+2:0] ext_res_0101_q;
  logic [XLEN+2:0] ext_res_0110_q;
  logic [XLEN+2:0] ext_res_0111_q;
  logic [XLEN+2:0] ext_res_1000_q;
  logic [XLEN+2:0] ext_res_1001_q;
  logic [XLEN+2:0] ext_res_1010_q;
  logic [XLEN+2:0] ext_res_1011_q;
  logic [XLEN+2:0] ext_res_1100_q;
  logic [XLEN+2:0] ext_res_1101_q;
  logic [XLEN+2:0] ext_res_1110_q;
  logic [XLEN+2:0] ext_res_1111_q;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign this_module = MUL_i;
  assign this_module = MULH_i;
  assign this_module = MULHSU_i;
  assign this_module = MULHU_i;
  assign this_module = MUW_i;

  assign ready_o = this_module & pipeline_init_ready;

  always_comb res_0001_d = multiplicand_i;
  always_comb res_0011_d = {res_0001_d, 1'b0} + res_0001_d;
  always_comb res_0111_d = {res_0001_d, 2'b0} + res_0011_d;
  always_comb res_0101_d = {res_0001_d, 2'b0} + res_0001_d;
  always_comb res_1001_d = {res_0001_d, 3'b0} + res_0001_d;
  always_comb res_1011_d = {res_0001_d, 1'b0} + res_1001_d;
  always_comb res_1101_d = {res_0001_d, 2'b0} + res_1001_d;
  always_comb res_1111_d = {res_0011_d, 2'b0} + res_0011_d;

  always_comb ext_res_0000_q = '0;
  always_comb ext_res_0001_q = res_0001_q;
  always_comb ext_res_0010_q = {res_0001_q, 1'b0};
  always_comb ext_res_0011_q = res_0011_q;
  always_comb ext_res_0100_q = {res_0001_q, 2'b0};
  always_comb ext_res_0101_q = res_0101_q;
  always_comb ext_res_0110_q = {res_0011_q, 1'b0};
  always_comb ext_res_0111_q = res_0111_q;
  always_comb ext_res_1000_q = {res_0001_q, 3'b0};
  always_comb ext_res_1001_q = res_1001_q;
  always_comb ext_res_1010_q = {res_0101_q, 1'b0};
  always_comb ext_res_1011_q = res_1011_q;
  always_comb ext_res_1100_q = {res_0011_q, 2'b0};
  always_comb ext_res_1101_q = res_1101_q;
  always_comb ext_res_1110_q = {res_0111_q, 1'b0};
  always_comb ext_res_1111_q = res_1111_q;

  assign out = {
    ext_res_0000_q,
    ext_res_0001_q,
    ext_res_0010_q,
    ext_res_0011_q,
    ext_res_0100_q,
    ext_res_0101_q,
    ext_res_0110_q,
    ext_res_0111_q,
    ext_res_1000_q,
    ext_res_1001_q,
    ext_res_1010_q,
    ext_res_1011_q,
    ext_res_1100_q,
    ext_res_1101_q,
    ext_res_1110_q,
    ext_res_1111_q
  };

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  pipeline #(
      .DW($bits(
          {
            res_0001_q,
            res_0011_q,
            res_0111_q,
            res_0101_q,
            res_1001_q,
            res_1011_q,
            res_1101_q,
            res_1111_q
          }
      ))
  ) u_pipeline_init (
      .arst_ni,
      .clk_i,
      .clear_i('0),
      .data_in_i({
        res_0001_d,
        res_0011_d,
        res_0111_d,
        res_0101_d,
        res_1001_d,
        res_1011_d,
        res_1101_d,
        res_1111_d
      }),
      .data_in_valid_i(valid_i & this_module),
      .data_in_ready_o(pipeline_init_ready),
      .data_out_o({
        res_0001_q,
        res_0011_q,
        res_0111_q,
        res_0101_q,
        res_1001_q,
        res_1011_q,
        res_1101_q,
        res_1111_q
      }),
      .data_out_valid_o(valid_o),
      .data_out_ready_i(ready_i)
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-INITIAL CHECKS
  //////////////////////////////////////////////////////////////////////////////////////////////////

`ifdef SIMULATION
  initial begin
    if (XLEN > 64) begin
      $display("\033[1;33m%m XLEN seems quite big\033[0m");
    end
  end
`endif  // SIMULATION

endmodule
