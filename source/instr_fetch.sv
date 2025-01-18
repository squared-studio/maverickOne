/*
This SystemVerilog module, instr_fetch, is responsible for fetching instructions in a processor
pipeline. It interfaces with an instruction cache and the execution stage, managing the flow of
instruction data and addresses.
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
This file is part of squared-studio:maverickOne
Copyright (c) 2024 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module instr_fetch #(
    parameter int XLEN = maverickOne_pkg::XLEN,  // Integer register width
    parameter int ILEN = maverickOne_pkg::ILEN,  // Instruction length
    localparam type addr_t = logic [XLEN-1:0],  // Address type
    localparam type instr_t = logic [ILEN-1:0]  // Instruction data type
) (
    input logic clk_i,   // Clock input
    input logic arst_ni, // Asynchronous reset input

    input logic icache_gnt_i,  // icache grant signal input
    input logic pipeline_ready_i,  // pipeline ready signal input
    output logic pipeline_valid_o,  // pipeline valid signal output
    output logic icache_req_o,  // icache request signal output

    input  instr_t icache_data_i,   // Instruction (cache) data input
    output instr_t pipeline_code_o, // Pipeline code (instruction) output

    input addr_t bootaddr_i,     // Boot address input
    output addr_t icache_addr_o,  // Instruction cache address output
    output addr_t pipeline_pc_o,  // Pipeline PC output

    input addr_t exe_curr_addr_i,         // Current address (EXEC) input
    input addr_t exe_next_addr_i,         // Next address (EXEC) input
    input logic  exe_direct_load_next_i,  // Is jump/branch (EXEC) input
    input logic  exe_is_jump_i,           // Is jump/branch (EXEC) input

    output logic pipeline_clear_o  // Pipeline clear signal output
);

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-WIRES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // PC
  addr_t pc;

  // Next PC output from BTB
  addr_t btb_next_pc;

  // Select for PC Register mux
  logic [1:0] pc_reg_mux_sel;

  // Output of PC Register mux
  addr_t pc_reg_mux_out;

  // PC Register output
  addr_t pc_reg_out;

  // Write enable signal for PC and PC mux-select registers
  logic reg_write_en;

  // Select for PC mux
  logic pc_mux_sel;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  assign pipeline_code_o = icache_data_i;

  assign icache_req_o = pipeline_ready_i;

  assign pipeline_pc_o = pc;
  assign icache_addr_o = pc;

  assign pc_reg_mux_sel[1] = exe_direct_load_next_i;

  always_comb pipeline_valid_o = icache_gnt_i & ~exe_direct_load_next_i;

  always_comb reg_write_en = icache_gnt_i & pipeline_ready_i;

  always_comb begin
    unique case (pc_reg_mux_sel)
      2'b00: pc_reg_mux_out = pc + 4;
      2'b01: pc_reg_mux_out = btb_next_pc;
      2'b10: pc_reg_mux_out = exe_next_addr_i;
      2'b11: pc_reg_mux_out = exe_next_addr_i;
    endcase
  end

  always_comb pc = pc_mux_sel ? pc_reg_out : bootaddr_i;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  branch_target_buffer #(
  ) u_btb (
    .clk_i,
    .arst_ni,
    .current_addr_i (exe_curr_addr_i),
    .next_addr_i (exe_next_addr_i),
    .pc_i (pc),
    .is_jump_i (exe_is_jump_i),
    .match_found_o (pc_reg_mux_sel[0]),
    .flush_o (pipeline_clear_o),
    .next_pc_o (btb_next_pc)
  );


  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SEQUENTIALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      pc_reg_out <= '0;
    end else if (reg_write_en) begin
      pc_reg_out <= pc_reg_mux_out;
    end
  end

  always_ff @(posedge clk_i or negedge arst_ni) begin
    if (~arst_ni) begin
      pc_mux_sel <= '0;
    end else if (reg_write_en) begin
      pc_mux_sel <= '1;
    end
  end

endmodule
