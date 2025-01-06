/*
This module is mean to decode instruction into the decoded_instr_t as mentioned in the
[maverickOne_pkg](../../include/maverickOne_pkg.sv).
- The `func` field enumerates the function that the current instruction.
- The `rd` is the destination register ant the `rs1`, `rs2` & `rs3` are the source registers. An
  offset of 32 is added for the floating point registers' address.
- The `imm` has multi-purpose such signed/unsigned immediate, shift, csr_addr, etc. based on the
  `func`.
- The `pc` hold's the physical address of the current instruction.
- The `blocking` field is set high when the current instruction must block next instructions from
  execution.
- The `reg_req` field is a flag that indicates the registers that are required for the current
  instruction

[Click here to see the supported instruction](../supported_instructions.md)

See the [ISA Manual](https://riscv.org/wp-content/uploads/2019/12/riscv-spec-20191213.pdf)'s Chapter
24 (RV32/64G Instruction Set Listings) for the encoding.

Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of squared-studio:maverickOne
Copyright (c) 2025 squared-studio
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`include "maverickOne_pkg.sv"

module instr_decoder #(
    // interger register width
    localparam int  XLEN            = maverickOne_pkg::XLEN,
    // type definition of decoded instruction
    localparam type decoded_instr_t = maverickOne_pkg::decoded_instr_t
) (
    // 32-bit input instruction code
    input logic [XLEN-1:0] pc_i,

    // 32-bit input instruction code
    input logic [31:0] code_i,

    // Output decoded instruction
    output decoded_instr_t cmd_o
);

  import maverickOne_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  logic [4:0] rd;  // Destination register
  logic [4:0] rs1;  // Source register 1
  logic [4:0] rs2;  // Source register 2
  logic [4:0] rs3;  // Source register 3

  logic [XLEN-1:0] aimm;  // SHIFT AMOUNT
  logic [XLEN-1:0] bimm;  // BTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] cimm;  // CSR INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] iimm;  // ITYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] jimm;  // JTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] rimm;  // FLOATING ROUND MODE IMMEDIATE
  logic [XLEN-1:0] simm;  // RTYPE INSTRUCTION IMMEDIATE
  logic [XLEN-1:0] timm;  // ATOMICS IMMEDIATE
  logic [XLEN-1:0] uimm;  // UTYPE INSTRUCTION IMMEDIATE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // INSTRUCTION REGISTER INDEX
  always_comb rd = code_i[11:7];
  always_comb rs1 = code_i[19:15];
  always_comb rs2 = code_i[24:20];
  always_comb rs3 = code_i[31:27];

  // SHIFT AMOUNT
  always_comb begin
    aimm = '0;
    aimm[5:0] = code_i[25:20];
  end

  // BTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    bimm = '0;
    bimm[4:1] = code_i[11:8];
    bimm[10:5] = code_i[30:25];
    bimm[11] = code_i[7];
    bimm[12] = code_i[31];
    bimm[63:13] = {51{code_i[31]}};
  end

  // CSR INSTRUCTION IMMEDIATE
  always_comb begin
    cimm = '0;
    cimm[11:0] = code_i[31:20];
    cimm[16:12] = code_i[19:15];
  end

  // ITYPE INSTRUCTION IMMEDIATE
  always_comb begin
    iimm[11:0]  = code_i[31:20];
    iimm[63:12] = {52{code_i[31]}};
  end

  // JTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    jimm = '0;
    jimm[10:1] = code_i[30:21];
    jimm[19:12] = code_i[19:12];
    jimm[11] = code_i[20];
    jimm[20] = code_i[31];
    jimm[63:21] = {43{code_i[31]}};
  end

  // FLOATING ROUND MODE IMMEDIATE
  always_comb begin
    rimm = '0;
    rimm[2:0] = code_i[14:12];
  end

  // RTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    simm[4:0]   = code_i[11:7];
    simm[11:5]  = code_i[31:25];
    simm[63:12] = {52{code_i[31]}};
  end

  // ATOMICS IMMEDIATE
  always_comb begin
    timm = '0;
    timm[0] = code_i[25:25];
    timm[1] = code_i[26:26];
  end

  // UTYPE INSTRUCTION IMMEDIATE
  always_comb begin
    uimm = '0;
    uimm[31:12] = code_i[31:12];
  end

  `define INSTR_DECODER_CMP(__CMP__, __EXP__, __IDX__)                                \
    constant_compare #(                                                                           \
        .IP_WIDTH(32),                                                                            \
        .CMP_ENABLES(``__CMP__``),                                                                \
        .EXP_RESULT(``__EXP__``),                                                                 \
        .OP_WIDTH(1),                                                                             \
        .MATCH_TRUE('1),                                                                          \
        .MATCH_FALSE('0)                                                                          \
    ) u_constant_compare_``__IDX__`` (                                                            \
        .in_i (code_i),                                                                           \
        .out_o(cmd_o.func[``__IDX__``])                                                           \
    );                                                                                            \

  // Decode the instruction and set the intermediate function
  `INSTR_DECODER_CMP(32'h0000007F, 32'h00000017, AUIPC)
  `INSTR_DECODER_CMP(32'h0000007F, 32'h00000037, LUI)
  `INSTR_DECODER_CMP(32'h0000007F, 32'h0000006F, JAL)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00000067, JALR)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00000063, BEQ)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00001063, BNE)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00004063, BLT)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00005063, BGE)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00006063, BLTU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00007063, BGEU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00000003, LB)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00001003, LH)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002003, LW)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00004003, LBU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00005003, LHU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00000023, SB)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00001023, SH)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002023, SW)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00000013, ADDI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002013, SLTI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003013, SLTIU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00004013, XORI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00006013, ORI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00007013, ANDI)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00001013, SLLI)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00005013, SRLI)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h40005013, SRAI)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00000033, ADD)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h40000033, SUB)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00001033, SLL)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00002033, SLT)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00003033, SLTU)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00004033, XOR)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00005033, SRL)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h40005033, SRA)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00006033, OR)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h00007033, AND)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h0000000F, FENCE)
  `INSTR_DECODER_CMP(32'hFFFFFFFF, 32'h00000073, ECALL)
  `INSTR_DECODER_CMP(32'hFFFFFFFF, 32'h00100073, EBREAK)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00006003, LWU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003003, LD)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003023, SD)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h0000001B, ADDIW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0000101B, SLLIW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0000501B, SRLIW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h4000501B, SRAIW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0000003B, ADDW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h4000003B, SUBW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0000103B, SLLW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0000503B, SRLW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h4000503B, SRAW)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00001073, CSRRW)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002073, CSRRS)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003073, CSRRC)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00005073, CSRRWI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00006073, CSRRSI)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00007073, CSRRCI)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02000033, MUL)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02001033, MULH)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02002033, MULHSU)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02003033, MULHU)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02004033, DIV)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02005033, DIVU)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02006033, REM)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h02007033, REMU)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0200003B, MULW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0200403B, DIVW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0200503B, DIVUW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0200603B, REMW)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h0200703B, REMUW)
  `INSTR_DECODER_CMP(32'hF9F0707F, 32'h1000202F, LR_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h1800202F, SC_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h0800202F, AMOSWAP_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h0000202F, AMOADD_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h2000202F, AMOXOR_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h6000202F, AMOAND_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h4000202F, AMOOR_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h8000202F, AMOMIN_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hA000202F, AMOMAX_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hC000202F, AMOMINU_W)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hE000202F, AMOMAXU_W)
  `INSTR_DECODER_CMP(32'hF9F0707F, 32'h1000302F, LR_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h1800302F, SC_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h0800302F, AMOSWAP_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h0000302F, AMOADD_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h2000302F, AMOXOR_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h6000302F, AMOAND_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h4000302F, AMOOR_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'h8000302F, AMOMIN_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hA000302F, AMOMAX_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hC000302F, AMOMINU_D)
  `INSTR_DECODER_CMP(32'hF800707F, 32'hE000302F, AMOMAXU_D)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002007, FLW)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00002027, FSW)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h00000043, FMADD_S)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h00000047, FMSUB_S)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h0000004B, FNMSUB_S)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h0000004F, FNMADD_S)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h00000053, FADD_S)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h08000053, FSUB_S)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h10000053, FMUL_S)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h18000053, FDIV_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'h58000053, FSQRT_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h20000053, FSGNJ_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h20001053, FSGNJN_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h20002053, FSGNJX_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h28000053, FMIN_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h28001053, FMAX_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC0000053, FCVT_W_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC0100053, FCVT_WU_S)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hE0000053, FMV_X_W)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA0002053, FEQ_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA0001053, FLT_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA0000053, FLE_S)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hE0001053, FCLASS_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD0000053, FCVT_S_W)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD0100053, FCVT_S_WU)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hF0000053, FMV_W_X)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC0200053, FCVT_L_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC0300053, FCVT_LU_S)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD0200053, FCVT_S_L)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD0300053, FCVT_S_LU)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003007, FLD)
  `INSTR_DECODER_CMP(32'h0000707F, 32'h00003027, FSD)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h02000043, FMADD_D)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h02000047, FMSUB_D)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h0200004B, FNMSUB_D)
  `INSTR_DECODER_CMP(32'h0600007F, 32'h0200004F, FNMADD_D)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h02000053, FADD_D)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h0A000053, FSUB_D)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h12000053, FMUL_D)
  `INSTR_DECODER_CMP(32'hFE00007F, 32'h1A000053, FDIV_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'h5A000053, FSQRT_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h22000053, FSGNJ_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h22001053, FSGNJN_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h22002053, FSGNJX_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h2A000053, FMIN_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'h2A001053, FMAX_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'h40100053, FCVT_S_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'h42000053, FCVT_D_S)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA2002053, FEQ_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA2001053, FLT_D)
  `INSTR_DECODER_CMP(32'hFE00707F, 32'hA2000053, FLE_D)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hE2001053, FCLASS_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC2000053, FCVT_W_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC2100053, FCVT_WU_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD2000053, FCVT_D_W)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD2100053, FCVT_D_WU)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC2200053, FCVT_L_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hC2300053, FCVT_LU_D)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hE2000053, FMV_X_D)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD2200053, FCVT_D_L)
  `INSTR_DECODER_CMP(32'hFFF0007F, 32'hD2300053, FCVT_D_LU)
  `INSTR_DECODER_CMP(32'hFFF0707F, 32'hF2000053, FMV_D_X)
  `INSTR_DECODER_CMP(32'hFFFFFFFF, 32'h30200073, MRET)
  `INSTR_DECODER_CMP(32'hFFFFFFFF, 32'h10500073, WFI)

  wor is_xrd;
  assign is_xrd = cmd_o.func[ADD];
  assign is_xrd = cmd_o.func[ADDI];
  assign is_xrd = cmd_o.func[ADDIW];
  assign is_xrd = cmd_o.func[ADDW];
  assign is_xrd = cmd_o.func[AMOADD_D];
  assign is_xrd = cmd_o.func[AMOADD_W];
  assign is_xrd = cmd_o.func[AMOAND_D];
  assign is_xrd = cmd_o.func[AMOAND_W];
  assign is_xrd = cmd_o.func[AMOMAX_D];
  assign is_xrd = cmd_o.func[AMOMAX_W];
  assign is_xrd = cmd_o.func[AMOMAXU_D];
  assign is_xrd = cmd_o.func[AMOMAXU_W];
  assign is_xrd = cmd_o.func[AMOMIN_D];
  assign is_xrd = cmd_o.func[AMOMIN_W];
  assign is_xrd = cmd_o.func[AMOMINU_D];
  assign is_xrd = cmd_o.func[AMOMINU_W];
  assign is_xrd = cmd_o.func[AMOOR_D];
  assign is_xrd = cmd_o.func[AMOOR_W];
  assign is_xrd = cmd_o.func[AMOSWAP_D];
  assign is_xrd = cmd_o.func[AMOSWAP_W];
  assign is_xrd = cmd_o.func[AMOXOR_D];
  assign is_xrd = cmd_o.func[AMOXOR_W];
  assign is_xrd = cmd_o.func[AND];
  assign is_xrd = cmd_o.func[ANDI];
  assign is_xrd = cmd_o.func[AUIPC];
  assign is_xrd = cmd_o.func[CSRRC];
  assign is_xrd = cmd_o.func[CSRRCI];
  assign is_xrd = cmd_o.func[CSRRS];
  assign is_xrd = cmd_o.func[CSRRSI];
  assign is_xrd = cmd_o.func[CSRRW];
  assign is_xrd = cmd_o.func[CSRRWI];
  assign is_xrd = cmd_o.func[DIV];
  assign is_xrd = cmd_o.func[DIVU];
  assign is_xrd = cmd_o.func[DIVUW];
  assign is_xrd = cmd_o.func[DIVW];
  assign is_xrd = cmd_o.func[FCLASS_D];
  assign is_xrd = cmd_o.func[FCLASS_S];
  assign is_xrd = cmd_o.func[FCVT_L_D];
  assign is_xrd = cmd_o.func[FCVT_L_S];
  assign is_xrd = cmd_o.func[FCVT_LU_D];
  assign is_xrd = cmd_o.func[FCVT_LU_S];
  assign is_xrd = cmd_o.func[FCVT_W_D];
  assign is_xrd = cmd_o.func[FCVT_W_S];
  assign is_xrd = cmd_o.func[FCVT_WU_D];
  assign is_xrd = cmd_o.func[FCVT_WU_S];
  assign is_xrd = cmd_o.func[FENCE];
  assign is_xrd = cmd_o.func[FEQ_D];
  assign is_xrd = cmd_o.func[FEQ_S];
  assign is_xrd = cmd_o.func[FLE_D];
  assign is_xrd = cmd_o.func[FLE_S];
  assign is_xrd = cmd_o.func[FLT_D];
  assign is_xrd = cmd_o.func[FLT_S];
  assign is_xrd = cmd_o.func[FMV_X_D];
  assign is_xrd = cmd_o.func[FMV_X_W];
  assign is_xrd = cmd_o.func[JAL];
  assign is_xrd = cmd_o.func[JALR];
  assign is_xrd = cmd_o.func[LB];
  assign is_xrd = cmd_o.func[LBU];
  assign is_xrd = cmd_o.func[LD];
  assign is_xrd = cmd_o.func[LH];
  assign is_xrd = cmd_o.func[LHU];
  assign is_xrd = cmd_o.func[LR_D];
  assign is_xrd = cmd_o.func[LR_W];
  assign is_xrd = cmd_o.func[LUI];
  assign is_xrd = cmd_o.func[LW];
  assign is_xrd = cmd_o.func[LWU];
  assign is_xrd = cmd_o.func[MUL];
  assign is_xrd = cmd_o.func[MULH];
  assign is_xrd = cmd_o.func[MULHSU];
  assign is_xrd = cmd_o.func[MULHU];
  assign is_xrd = cmd_o.func[MULW];
  assign is_xrd = cmd_o.func[OR];
  assign is_xrd = cmd_o.func[ORI];
  assign is_xrd = cmd_o.func[REM];
  assign is_xrd = cmd_o.func[REMU];
  assign is_xrd = cmd_o.func[REMUW];
  assign is_xrd = cmd_o.func[REMW];
  assign is_xrd = cmd_o.func[SC_D];
  assign is_xrd = cmd_o.func[SC_W];
  assign is_xrd = cmd_o.func[SLL];
  assign is_xrd = cmd_o.func[SLLI];
  assign is_xrd = cmd_o.func[SLLIW];
  assign is_xrd = cmd_o.func[SLLW];
  assign is_xrd = cmd_o.func[SLT];
  assign is_xrd = cmd_o.func[SLTI];
  assign is_xrd = cmd_o.func[SLTIU];
  assign is_xrd = cmd_o.func[SLTU];
  assign is_xrd = cmd_o.func[SRA];
  assign is_xrd = cmd_o.func[SRAI];
  assign is_xrd = cmd_o.func[SRAIW];
  assign is_xrd = cmd_o.func[SRAW];
  assign is_xrd = cmd_o.func[SRL];
  assign is_xrd = cmd_o.func[SRLI];
  assign is_xrd = cmd_o.func[SRLIW];
  assign is_xrd = cmd_o.func[SRLW];
  assign is_xrd = cmd_o.func[SUB];
  assign is_xrd = cmd_o.func[SUBW];
  assign is_xrd = cmd_o.func[XOR];
  assign is_xrd = cmd_o.func[XORI];

  wor is_frd;
  assign is_frd = cmd_o.func[FADD_D];
  assign is_frd = cmd_o.func[FADD_S];
  assign is_frd = cmd_o.func[FCVT_D_L];
  assign is_frd = cmd_o.func[FCVT_D_LU];
  assign is_frd = cmd_o.func[FCVT_D_S];
  assign is_frd = cmd_o.func[FCVT_D_W];
  assign is_frd = cmd_o.func[FCVT_D_WU];
  assign is_frd = cmd_o.func[FCVT_S_D];
  assign is_frd = cmd_o.func[FCVT_S_L];
  assign is_frd = cmd_o.func[FCVT_S_LU];
  assign is_frd = cmd_o.func[FCVT_S_W];
  assign is_frd = cmd_o.func[FCVT_S_WU];
  assign is_frd = cmd_o.func[FDIV_D];
  assign is_frd = cmd_o.func[FDIV_S];
  assign is_frd = cmd_o.func[FLD];
  assign is_frd = cmd_o.func[FLW];
  assign is_frd = cmd_o.func[FMADD_D];
  assign is_frd = cmd_o.func[FMADD_S];
  assign is_frd = cmd_o.func[FMAX_D];
  assign is_frd = cmd_o.func[FMAX_S];
  assign is_frd = cmd_o.func[FMIN_D];
  assign is_frd = cmd_o.func[FMIN_S];
  assign is_frd = cmd_o.func[FMSUB_D];
  assign is_frd = cmd_o.func[FMSUB_S];
  assign is_frd = cmd_o.func[FMUL_D];
  assign is_frd = cmd_o.func[FMUL_S];
  assign is_frd = cmd_o.func[FMV_D_X];
  assign is_frd = cmd_o.func[FMV_W_X];
  assign is_frd = cmd_o.func[FNMADD_D];
  assign is_frd = cmd_o.func[FNMADD_S];
  assign is_frd = cmd_o.func[FNMSUB_D];
  assign is_frd = cmd_o.func[FNMSUB_S];
  assign is_frd = cmd_o.func[FSGNJ_D];
  assign is_frd = cmd_o.func[FSGNJ_S];
  assign is_frd = cmd_o.func[FSGNJN_D];
  assign is_frd = cmd_o.func[FSGNJN_S];
  assign is_frd = cmd_o.func[FSGNJX_D];
  assign is_frd = cmd_o.func[FSGNJX_S];
  assign is_frd = cmd_o.func[FSQRT_D];
  assign is_frd = cmd_o.func[FSQRT_S];
  assign is_frd = cmd_o.func[FSUB_D];
  assign is_frd = cmd_o.func[FSUB_S];

  always_comb begin
    cmd_o.rd = '0;
    if (is_xrd) cmd_o.rd = {1'b0, rd};
    else if (is_frd) cmd_o.rd = {1'b1, rd};
  end

  wor is_xrs1;
  assign is_xrs1 = cmd_o.func[ADD];
  assign is_xrs1 = cmd_o.func[ADDI];
  assign is_xrs1 = cmd_o.func[ADDIW];
  assign is_xrs1 = cmd_o.func[ADDW];
  assign is_xrs1 = cmd_o.func[AMOADD_D];
  assign is_xrs1 = cmd_o.func[AMOADD_W];
  assign is_xrs1 = cmd_o.func[AMOAND_D];
  assign is_xrs1 = cmd_o.func[AMOAND_W];
  assign is_xrs1 = cmd_o.func[AMOMAX_D];
  assign is_xrs1 = cmd_o.func[AMOMAX_W];
  assign is_xrs1 = cmd_o.func[AMOMAXU_D];
  assign is_xrs1 = cmd_o.func[AMOMAXU_W];
  assign is_xrs1 = cmd_o.func[AMOMIN_D];
  assign is_xrs1 = cmd_o.func[AMOMIN_W];
  assign is_xrs1 = cmd_o.func[AMOMINU_D];
  assign is_xrs1 = cmd_o.func[AMOMINU_W];
  assign is_xrs1 = cmd_o.func[AMOOR_D];
  assign is_xrs1 = cmd_o.func[AMOOR_W];
  assign is_xrs1 = cmd_o.func[AMOSWAP_D];
  assign is_xrs1 = cmd_o.func[AMOSWAP_W];
  assign is_xrs1 = cmd_o.func[AMOXOR_D];
  assign is_xrs1 = cmd_o.func[AMOXOR_W];
  assign is_xrs1 = cmd_o.func[AND];
  assign is_xrs1 = cmd_o.func[ANDI];
  assign is_xrs1 = cmd_o.func[BEQ];
  assign is_xrs1 = cmd_o.func[BGE];
  assign is_xrs1 = cmd_o.func[BGEU];
  assign is_xrs1 = cmd_o.func[BLT];
  assign is_xrs1 = cmd_o.func[BLTU];
  assign is_xrs1 = cmd_o.func[BNE];
  assign is_xrs1 = cmd_o.func[CSRRC];
  assign is_xrs1 = cmd_o.func[CSRRS];
  assign is_xrs1 = cmd_o.func[CSRRW];
  assign is_xrs1 = cmd_o.func[DIV];
  assign is_xrs1 = cmd_o.func[DIVU];
  assign is_xrs1 = cmd_o.func[DIVUW];
  assign is_xrs1 = cmd_o.func[DIVW];
  assign is_xrs1 = cmd_o.func[FCVT_D_L];
  assign is_xrs1 = cmd_o.func[FCVT_D_LU];
  assign is_xrs1 = cmd_o.func[FCVT_D_W];
  assign is_xrs1 = cmd_o.func[FCVT_D_WU];
  assign is_xrs1 = cmd_o.func[FCVT_S_L];
  assign is_xrs1 = cmd_o.func[FCVT_S_LU];
  assign is_xrs1 = cmd_o.func[FCVT_S_W];
  assign is_xrs1 = cmd_o.func[FCVT_S_WU];
  assign is_xrs1 = cmd_o.func[FENCE];
  assign is_xrs1 = cmd_o.func[FLD];
  assign is_xrs1 = cmd_o.func[FLW];
  assign is_xrs1 = cmd_o.func[FMV_D_X];
  assign is_xrs1 = cmd_o.func[FMV_W_X];
  assign is_xrs1 = cmd_o.func[FSD];
  assign is_xrs1 = cmd_o.func[FSW];
  assign is_xrs1 = cmd_o.func[JALR];
  assign is_xrs1 = cmd_o.func[LB];
  assign is_xrs1 = cmd_o.func[LBU];
  assign is_xrs1 = cmd_o.func[LD];
  assign is_xrs1 = cmd_o.func[LH];
  assign is_xrs1 = cmd_o.func[LHU];
  assign is_xrs1 = cmd_o.func[LR_D];
  assign is_xrs1 = cmd_o.func[LR_W];
  assign is_xrs1 = cmd_o.func[LW];
  assign is_xrs1 = cmd_o.func[LWU];
  assign is_xrs1 = cmd_o.func[MUL];
  assign is_xrs1 = cmd_o.func[MULH];
  assign is_xrs1 = cmd_o.func[MULHSU];
  assign is_xrs1 = cmd_o.func[MULHU];
  assign is_xrs1 = cmd_o.func[MULW];
  assign is_xrs1 = cmd_o.func[OR];
  assign is_xrs1 = cmd_o.func[ORI];
  assign is_xrs1 = cmd_o.func[REM];
  assign is_xrs1 = cmd_o.func[REMU];
  assign is_xrs1 = cmd_o.func[REMUW];
  assign is_xrs1 = cmd_o.func[REMW];
  assign is_xrs1 = cmd_o.func[SB];
  assign is_xrs1 = cmd_o.func[SC_D];
  assign is_xrs1 = cmd_o.func[SC_W];
  assign is_xrs1 = cmd_o.func[SD];
  assign is_xrs1 = cmd_o.func[SH];
  assign is_xrs1 = cmd_o.func[SLL];
  assign is_xrs1 = cmd_o.func[SLLI];
  assign is_xrs1 = cmd_o.func[SLLIW];
  assign is_xrs1 = cmd_o.func[SLLW];
  assign is_xrs1 = cmd_o.func[SLT];
  assign is_xrs1 = cmd_o.func[SLTI];
  assign is_xrs1 = cmd_o.func[SLTIU];
  assign is_xrs1 = cmd_o.func[SLTU];
  assign is_xrs1 = cmd_o.func[SRA];
  assign is_xrs1 = cmd_o.func[SRAI];
  assign is_xrs1 = cmd_o.func[SRAIW];
  assign is_xrs1 = cmd_o.func[SRAW];
  assign is_xrs1 = cmd_o.func[SRL];
  assign is_xrs1 = cmd_o.func[SRLI];
  assign is_xrs1 = cmd_o.func[SRLIW];
  assign is_xrs1 = cmd_o.func[SRLW];
  assign is_xrs1 = cmd_o.func[SUB];
  assign is_xrs1 = cmd_o.func[SUBW];
  assign is_xrs1 = cmd_o.func[SW];
  assign is_xrs1 = cmd_o.func[XOR];
  assign is_xrs1 = cmd_o.func[XORI];

  wor is_frs1;
  assign is_frs1 = cmd_o.func[FADD_D];
  assign is_frs1 = cmd_o.func[FADD_S];
  assign is_frs1 = cmd_o.func[FCLASS_D];
  assign is_frs1 = cmd_o.func[FCLASS_S];
  assign is_frs1 = cmd_o.func[FCVT_D_S];
  assign is_frs1 = cmd_o.func[FCVT_L_D];
  assign is_frs1 = cmd_o.func[FCVT_L_S];
  assign is_frs1 = cmd_o.func[FCVT_LU_D];
  assign is_frs1 = cmd_o.func[FCVT_LU_S];
  assign is_frs1 = cmd_o.func[FCVT_S_D];
  assign is_frs1 = cmd_o.func[FCVT_W_D];
  assign is_frs1 = cmd_o.func[FCVT_W_S];
  assign is_frs1 = cmd_o.func[FCVT_WU_D];
  assign is_frs1 = cmd_o.func[FCVT_WU_S];
  assign is_frs1 = cmd_o.func[FDIV_D];
  assign is_frs1 = cmd_o.func[FDIV_S];
  assign is_frs1 = cmd_o.func[FEQ_D];
  assign is_frs1 = cmd_o.func[FEQ_S];
  assign is_frs1 = cmd_o.func[FLE_D];
  assign is_frs1 = cmd_o.func[FLE_S];
  assign is_frs1 = cmd_o.func[FLT_D];
  assign is_frs1 = cmd_o.func[FLT_S];
  assign is_frs1 = cmd_o.func[FMADD_D];
  assign is_frs1 = cmd_o.func[FMADD_S];
  assign is_frs1 = cmd_o.func[FMAX_D];
  assign is_frs1 = cmd_o.func[FMAX_S];
  assign is_frs1 = cmd_o.func[FMIN_D];
  assign is_frs1 = cmd_o.func[FMIN_S];
  assign is_frs1 = cmd_o.func[FMSUB_D];
  assign is_frs1 = cmd_o.func[FMSUB_S];
  assign is_frs1 = cmd_o.func[FMUL_D];
  assign is_frs1 = cmd_o.func[FMUL_S];
  assign is_frs1 = cmd_o.func[FMV_X_D];
  assign is_frs1 = cmd_o.func[FMV_X_W];
  assign is_frs1 = cmd_o.func[FNMADD_D];
  assign is_frs1 = cmd_o.func[FNMADD_S];
  assign is_frs1 = cmd_o.func[FNMSUB_D];
  assign is_frs1 = cmd_o.func[FNMSUB_S];
  assign is_frs1 = cmd_o.func[FSGNJ_D];
  assign is_frs1 = cmd_o.func[FSGNJ_S];
  assign is_frs1 = cmd_o.func[FSGNJN_D];
  assign is_frs1 = cmd_o.func[FSGNJN_S];
  assign is_frs1 = cmd_o.func[FSGNJX_D];
  assign is_frs1 = cmd_o.func[FSGNJX_S];
  assign is_frs1 = cmd_o.func[FSQRT_D];
  assign is_frs1 = cmd_o.func[FSQRT_S];
  assign is_frs1 = cmd_o.func[FSUB_D];
  assign is_frs1 = cmd_o.func[FSUB_S];

  always_comb begin
    cmd_o.rs1 = '0;
    if (is_xrs1) cmd_o.rs1 = {1'b0, rs1};
    else if (is_frs1) cmd_o.rs1 = {1'b1, rs1};
  end

  wor is_xrs2;
  assign is_xrs2 = cmd_o.func[ADD];
  assign is_xrs2 = cmd_o.func[ADDW];
  assign is_xrs2 = cmd_o.func[AMOADD_D];
  assign is_xrs2 = cmd_o.func[AMOADD_W];
  assign is_xrs2 = cmd_o.func[AMOAND_D];
  assign is_xrs2 = cmd_o.func[AMOAND_W];
  assign is_xrs2 = cmd_o.func[AMOMAX_D];
  assign is_xrs2 = cmd_o.func[AMOMAX_W];
  assign is_xrs2 = cmd_o.func[AMOMAXU_D];
  assign is_xrs2 = cmd_o.func[AMOMAXU_W];
  assign is_xrs2 = cmd_o.func[AMOMIN_D];
  assign is_xrs2 = cmd_o.func[AMOMIN_W];
  assign is_xrs2 = cmd_o.func[AMOMINU_D];
  assign is_xrs2 = cmd_o.func[AMOMINU_W];
  assign is_xrs2 = cmd_o.func[AMOOR_D];
  assign is_xrs2 = cmd_o.func[AMOOR_W];
  assign is_xrs2 = cmd_o.func[AMOSWAP_D];
  assign is_xrs2 = cmd_o.func[AMOSWAP_W];
  assign is_xrs2 = cmd_o.func[AMOXOR_D];
  assign is_xrs2 = cmd_o.func[AMOXOR_W];
  assign is_xrs2 = cmd_o.func[AND];
  assign is_xrs2 = cmd_o.func[BEQ];
  assign is_xrs2 = cmd_o.func[BGE];
  assign is_xrs2 = cmd_o.func[BGEU];
  assign is_xrs2 = cmd_o.func[BLT];
  assign is_xrs2 = cmd_o.func[BLTU];
  assign is_xrs2 = cmd_o.func[BNE];
  assign is_xrs2 = cmd_o.func[DIV];
  assign is_xrs2 = cmd_o.func[DIVU];
  assign is_xrs2 = cmd_o.func[DIVUW];
  assign is_xrs2 = cmd_o.func[DIVW];
  assign is_xrs2 = cmd_o.func[MUL];
  assign is_xrs2 = cmd_o.func[MULH];
  assign is_xrs2 = cmd_o.func[MULHSU];
  assign is_xrs2 = cmd_o.func[MULHU];
  assign is_xrs2 = cmd_o.func[MULW];
  assign is_xrs2 = cmd_o.func[OR];
  assign is_xrs2 = cmd_o.func[REM];
  assign is_xrs2 = cmd_o.func[REMU];
  assign is_xrs2 = cmd_o.func[REMUW];
  assign is_xrs2 = cmd_o.func[REMW];
  assign is_xrs2 = cmd_o.func[SB];
  assign is_xrs2 = cmd_o.func[SC_D];
  assign is_xrs2 = cmd_o.func[SC_W];
  assign is_xrs2 = cmd_o.func[SD];
  assign is_xrs2 = cmd_o.func[SH];
  assign is_xrs2 = cmd_o.func[SLL];
  assign is_xrs2 = cmd_o.func[SLLW];
  assign is_xrs2 = cmd_o.func[SLT];
  assign is_xrs2 = cmd_o.func[SLTU];
  assign is_xrs2 = cmd_o.func[SRA];
  assign is_xrs2 = cmd_o.func[SRAW];
  assign is_xrs2 = cmd_o.func[SRL];
  assign is_xrs2 = cmd_o.func[SRLW];
  assign is_xrs2 = cmd_o.func[SUB];
  assign is_xrs2 = cmd_o.func[SUBW];
  assign is_xrs2 = cmd_o.func[SW];
  assign is_xrs2 = cmd_o.func[XOR];

  wor is_frs2;
  assign is_frs2 = cmd_o.func[FADD_D];
  assign is_frs2 = cmd_o.func[FADD_S];
  assign is_frs2 = cmd_o.func[FDIV_D];
  assign is_frs2 = cmd_o.func[FDIV_S];
  assign is_frs2 = cmd_o.func[FEQ_D];
  assign is_frs2 = cmd_o.func[FEQ_S];
  assign is_frs2 = cmd_o.func[FLE_D];
  assign is_frs2 = cmd_o.func[FLE_S];
  assign is_frs2 = cmd_o.func[FLT_D];
  assign is_frs2 = cmd_o.func[FLT_S];
  assign is_frs2 = cmd_o.func[FSW];
  assign is_frs2 = cmd_o.func[FSD];
  assign is_frs2 = cmd_o.func[FMADD_D];
  assign is_frs2 = cmd_o.func[FMADD_S];
  assign is_frs2 = cmd_o.func[FMAX_D];
  assign is_frs2 = cmd_o.func[FMAX_S];
  assign is_frs2 = cmd_o.func[FMIN_D];
  assign is_frs2 = cmd_o.func[FMIN_S];
  assign is_frs2 = cmd_o.func[FMSUB_D];
  assign is_frs2 = cmd_o.func[FMSUB_S];
  assign is_frs2 = cmd_o.func[FMUL_D];
  assign is_frs2 = cmd_o.func[FMUL_S];
  assign is_frs2 = cmd_o.func[FNMADD_D];
  assign is_frs2 = cmd_o.func[FNMADD_S];
  assign is_frs2 = cmd_o.func[FNMSUB_D];
  assign is_frs2 = cmd_o.func[FNMSUB_S];
  assign is_frs2 = cmd_o.func[FSGNJ_D];
  assign is_frs2 = cmd_o.func[FSGNJ_S];
  assign is_frs2 = cmd_o.func[FSGNJN_D];
  assign is_frs2 = cmd_o.func[FSGNJN_S];
  assign is_frs2 = cmd_o.func[FSGNJX_D];
  assign is_frs2 = cmd_o.func[FSGNJX_S];
  assign is_frs2 = cmd_o.func[FSUB_D];
  assign is_frs2 = cmd_o.func[FSUB_S];

  always_comb begin
    cmd_o.rs2 = '0;
    if (is_xrs2) cmd_o.rs2 = {1'b0, rs2};
    else if (is_frs2) cmd_o.rs2 = {1'b1, rs2};
  end

  wor is_frs3;
  assign is_frs3 = cmd_o.func[FMADD_D];
  assign is_frs3 = cmd_o.func[FMADD_S];
  assign is_frs3 = cmd_o.func[FMSUB_D];
  assign is_frs3 = cmd_o.func[FMSUB_S];
  assign is_frs3 = cmd_o.func[FNMADD_D];
  assign is_frs3 = cmd_o.func[FNMADD_S];
  assign is_frs3 = cmd_o.func[FNMSUB_D];
  assign is_frs3 = cmd_o.func[FNMSUB_S];
  always_comb cmd_o.rs3 = is_frs3 ? {1'b1, rs3} : '0;

  wor is_aimm;
  assign is_aimm = cmd_o.func[SLLI];
  assign is_aimm = cmd_o.func[SLLIW];
  assign is_aimm = cmd_o.func[SRAI];
  assign is_aimm = cmd_o.func[SRAIW];
  assign is_aimm = cmd_o.func[SRLI];
  assign is_aimm = cmd_o.func[SRLIW];

  wor is_bimm;
  assign is_bimm = cmd_o.func[BEQ];
  assign is_bimm = cmd_o.func[BGE];
  assign is_bimm = cmd_o.func[BGEU];
  assign is_bimm = cmd_o.func[BLT];
  assign is_bimm = cmd_o.func[BLTU];
  assign is_bimm = cmd_o.func[BNE];

  wor is_cimm;
  assign is_cimm = cmd_o.func[CSRRCI];
  assign is_cimm = cmd_o.func[CSRRSI];
  assign is_cimm = cmd_o.func[CSRRWI];

  wor is_iimm;
  assign is_iimm = cmd_o.func[ADDI];
  assign is_iimm = cmd_o.func[ADDIW];
  assign is_iimm = cmd_o.func[ANDI];
  assign is_iimm = cmd_o.func[CSRRC];
  assign is_iimm = cmd_o.func[CSRRS];
  assign is_iimm = cmd_o.func[CSRRW];
  assign is_iimm = cmd_o.func[EBREAK];
  assign is_iimm = cmd_o.func[ECALL];
  assign is_iimm = cmd_o.func[FENCE];
  assign is_iimm = cmd_o.func[FLD];
  assign is_iimm = cmd_o.func[FLW];
  assign is_iimm = cmd_o.func[JALR];
  assign is_iimm = cmd_o.func[LB];
  assign is_iimm = cmd_o.func[LBU];
  assign is_iimm = cmd_o.func[LD];
  assign is_iimm = cmd_o.func[LH];
  assign is_iimm = cmd_o.func[LHU];
  assign is_iimm = cmd_o.func[LW];
  assign is_iimm = cmd_o.func[LWU];
  assign is_iimm = cmd_o.func[ORI];
  assign is_iimm = cmd_o.func[SLTI];
  assign is_iimm = cmd_o.func[SLTIU];
  assign is_iimm = cmd_o.func[XORI];

  wor is_jimm;
  assign is_jimm = cmd_o.func[JAL];

  wor is_rimm;
  assign is_rimm = cmd_o.func[FADD_D];
  assign is_rimm = cmd_o.func[FADD_S];
  assign is_rimm = cmd_o.func[FCVT_D_L];
  assign is_rimm = cmd_o.func[FCVT_D_LU];
  assign is_rimm = cmd_o.func[FCVT_D_S];
  assign is_rimm = cmd_o.func[FCVT_D_W];
  assign is_rimm = cmd_o.func[FCVT_D_WU];
  assign is_rimm = cmd_o.func[FCVT_L_D];
  assign is_rimm = cmd_o.func[FCVT_L_S];
  assign is_rimm = cmd_o.func[FCVT_LU_D];
  assign is_rimm = cmd_o.func[FCVT_LU_S];
  assign is_rimm = cmd_o.func[FCVT_S_D];
  assign is_rimm = cmd_o.func[FCVT_S_L];
  assign is_rimm = cmd_o.func[FCVT_S_LU];
  assign is_rimm = cmd_o.func[FCVT_S_W];
  assign is_rimm = cmd_o.func[FCVT_S_WU];
  assign is_rimm = cmd_o.func[FCVT_W_D];
  assign is_rimm = cmd_o.func[FCVT_W_S];
  assign is_rimm = cmd_o.func[FCVT_WU_D];
  assign is_rimm = cmd_o.func[FCVT_WU_S];
  assign is_rimm = cmd_o.func[FDIV_D];
  assign is_rimm = cmd_o.func[FDIV_S];
  assign is_rimm = cmd_o.func[FMADD_D];
  assign is_rimm = cmd_o.func[FMADD_S];
  assign is_rimm = cmd_o.func[FMSUB_D];
  assign is_rimm = cmd_o.func[FMSUB_S];
  assign is_rimm = cmd_o.func[FMUL_D];
  assign is_rimm = cmd_o.func[FMUL_S];
  assign is_rimm = cmd_o.func[FNMADD_D];
  assign is_rimm = cmd_o.func[FNMADD_S];
  assign is_rimm = cmd_o.func[FNMSUB_D];
  assign is_rimm = cmd_o.func[FNMSUB_S];
  assign is_rimm = cmd_o.func[FSQRT_D];
  assign is_rimm = cmd_o.func[FSQRT_S];
  assign is_rimm = cmd_o.func[FSUB_D];
  assign is_rimm = cmd_o.func[FSUB_S];

  wor is_simm;
  assign is_simm = cmd_o.func[FSD];
  assign is_simm = cmd_o.func[FSW];
  assign is_simm = cmd_o.func[SB];
  assign is_simm = cmd_o.func[SD];
  assign is_simm = cmd_o.func[SH];
  assign is_simm = cmd_o.func[SW];

  wor is_timm;
  assign is_timm = cmd_o.func[AMOADD_D];
  assign is_timm = cmd_o.func[AMOADD_W];
  assign is_timm = cmd_o.func[AMOAND_D];
  assign is_timm = cmd_o.func[AMOAND_W];
  assign is_timm = cmd_o.func[AMOMAX_D];
  assign is_timm = cmd_o.func[AMOMAX_W];
  assign is_timm = cmd_o.func[AMOMAXU_D];
  assign is_timm = cmd_o.func[AMOMAXU_W];
  assign is_timm = cmd_o.func[AMOMIN_D];
  assign is_timm = cmd_o.func[AMOMIN_W];
  assign is_timm = cmd_o.func[AMOMINU_D];
  assign is_timm = cmd_o.func[AMOMINU_W];
  assign is_timm = cmd_o.func[AMOOR_D];
  assign is_timm = cmd_o.func[AMOOR_W];
  assign is_timm = cmd_o.func[AMOSWAP_D];
  assign is_timm = cmd_o.func[AMOSWAP_W];
  assign is_timm = cmd_o.func[AMOXOR_D];
  assign is_timm = cmd_o.func[AMOXOR_W];
  assign is_timm = cmd_o.func[LR_D];
  assign is_timm = cmd_o.func[LR_W];
  assign is_timm = cmd_o.func[SC_D];
  assign is_timm = cmd_o.func[SC_W];

  wor is_uimm;
  assign is_uimm = cmd_o.func[AUIPC];
  assign is_uimm = cmd_o.func[LUI];

  always_comb begin
    if (is_aimm) cmd_o.imm = aimm;
    else if (is_bimm) cmd_o.imm = bimm;
    else if (is_cimm) cmd_o.imm = cimm;
    else if (is_iimm) cmd_o.imm = iimm;
    else if (is_jimm) cmd_o.imm = jimm;
    else if (is_rimm) cmd_o.imm = rimm;
    else if (is_simm) cmd_o.imm = simm;
    else if (is_timm) cmd_o.imm = timm;
    else if (is_uimm) cmd_o.imm = uimm;
    else cmd_o.imm = '0;
  end

  always_comb cmd_o.pc = pc_i;

  wor is_blocking;
  assign is_blocking = cmd_o.func[BEQ];
  assign is_blocking = cmd_o.func[BGE];
  assign is_blocking = cmd_o.func[BGEU];
  assign is_blocking = cmd_o.func[BLT];
  assign is_blocking = cmd_o.func[BLTU];
  assign is_blocking = cmd_o.func[BNE];
  assign is_blocking = cmd_o.func[JAL];
  assign is_blocking = cmd_o.func[JALR];
  assign is_blocking = cmd_o.func[FENCE];
  assign is_blocking = cmd_o.func[MRET];
  assign is_blocking = cmd_o.func[WFI];

  always_comb begin
    cmd_o.blocking = is_blocking;
  end

  always_comb begin
    cmd_o.reg_req            = {64{cmd_o.blocking}};
    cmd_o.reg_req[cmd_o.rd]  = '1;
    cmd_o.reg_req[cmd_o.rs1] = '1;
    cmd_o.reg_req[cmd_o.rs2] = '1;
    cmd_o.reg_req[cmd_o.rs3] = '1;
  end

endmodule
