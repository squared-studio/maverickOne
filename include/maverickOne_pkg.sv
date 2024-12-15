/*
Author : Foez Ahmed (https://github.com/foez-ahmed)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

`ifndef MAVERICKONE_PKG_SV__
`define MAVERICKONE_PKG_SV__ 0

package maverickOne_pkg;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // PARAMETERS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  parameter int ILEN = 32;

  parameter int CILEN = 16;

  parameter int XLEN = 64;
  parameter int FLEN = 64;

  parameter int NUM_GPR = 32;
  parameter int NUM_FPR = 32;

  parameter int NUM_REGS = NUM_GPR + NUM_FPR;

  ////////////////////////////////////////////////
  // maverickOne_INSTR_LAUNCHER
  ////////////////////////////////////////////////

  parameter int NUM_OUTSTANDING = 7;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // ISA
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum int {
    LUI,
    AUIPC,
    JAL,
    JALR,
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU,
    LB,
    LH,
    LW,
    LBU,
    LHU,
    SB,
    SH,
    SW,
    ADDI,
    SLTI,
    SLTIU,
    XORI,
    ORI,
    ANDI,
    SLLI,
    SRLI,
    SRAI,
    ADD,
    SUB,
    SLL,
    SLT,
    SLTU,
    XOR,
    SRL,
    SRA,
    OR,
    AND,
    FENCE,
    ECALL,
    EBREAK,
    LWU,
    LD,
    SD,
    ADDIW,
    SLLIW,
    SRLIW,
    SRAIW,
    ADDW,
    SUBW,
    SLLW,
    SRLW,
    SRAW,
    CSRRW,
    CSRRS,
    CSRRC,
    CSRRWI,
    CSRRSI,
    CSRRCI,
    MUL,
    MULH,
    MULHSU,
    MULHU,
    DIV,
    DIVU,
    REM,
    REMU,
    MULW,
    DIVW,
    DIVUW,
    REMW,
    REMUW,
    LR_W,
    SC_W,
    AMOSWAP_W,
    AMOADD_W,
    AMOXOR_W,
    AMOAND_W,
    AMOOR_W,
    AMOMIN_W,
    AMOMAX_W,
    AMOMINU_W,
    AMOMAXU_W,
    LR_D,
    SC_D,
    AMOSWAP_D,
    AMOADD_D,
    AMOXOR_D,
    AMOAND_D,
    AMOOR_D,
    AMOMIN_D,
    AMOMAX_D,
    AMOMINU_D,
    AMOMAXU_D,
    FLW,
    FSW,
    FMADD_S,
    FMSUB_S,
    FNMSUB_S,
    FNMADD_S,
    FADD_S,
    FSUB_S,
    FMUL_S,
    FDIV_S,
    FSQRT_S,
    FSGNJ_S,
    FSGNJN_S,
    FSGNJX_S,
    FMIN_S,
    FMAX_S,
    FCVT_W_S,
    FCVT_WU_S,
    FMV_X_W,
    FEQ_S,
    FLT_S,
    FLE_S,
    FCLASS_S,
    FCVT_S_W,
    FCVT_S_WU,
    FMV_W_X,
    FCVT_L_S,
    FCVT_LU_S,
    FCVT_S_L,
    FCVT_S_LU,
    FLD,
    FSD,
    FMADD_D,
    FMSUB_D,
    FNMSUB_D,
    FNMADD_D,
    FADD_D,
    FSUB_D,
    FMUL_D,
    FDIV_D,
    FSQRT_D,
    FSGNJ_D,
    FSGNJN_D,
    FSGNJX_D,
    FMIN_D,
    FMAX_D,
    FCVT_S_D,
    FCVT_D_S,
    FEQ_D,
    FLT_D,
    FLE_D,
    FCLASS_D,
    FCVT_W_D,
    FCVT_WU_D,
    FCVT_D_W,
    FCVT_D_WU,
    FCVT_L_D,
    FCVT_LU_D,
    FMV_X_D,
    FCVT_D_L,
    FCVT_D_LU,
    FMV_D_X,
    MRET,
    WFI
  } func_t;

  func_t functions;

  parameter int TOTAL_FUNCS = functions.num();

  typedef struct packed {

    // The `func` field one-hot enumerates the operation represented by the current instruction.
    logic [TOTAL_FUNCS-1:0] func;

    // The `rd` is the destination register ant the `rs1`, `rs2` & `rs3` are the source registers.
    // An offset of 32 is added for the floating point registers' address.
    logic [$clog2(NUM_REGS)-1:0] rd;
    logic [$clog2(NUM_REGS)-1:0] rs1;
    logic [$clog2(NUM_REGS)-1:0] rs2;
    logic [$clog2(NUM_REGS)-1:0] rs3;

    // The `imm` has multi-purpose such signed/unsigned immediate, shift, csr_addr, etc. based on
    // the `func`. -------- imm:64 / {fm:4,pred:4,succ:4} / shamt:6 / {uimm:5,csr:12}
    logic [XLEN-1:0] imm;

    // The `pc` hold's the physical address of the current instruction.
    logic [XLEN-1:0] pc;

    // The `blocking` field is set high when the current instruction must block next instructions
    logic blocking;

    // The `reg_req` field is a flag that indicates the registers that are required for the current
    // instruction
    logic [NUM_REGS-1:0] reg_req;

  } decoded_instr_t;

endpackage

`endif
