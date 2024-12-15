/*
Description
Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)
Co-Author : S. M. Tahmeed Reza (https://github.com/tahmeedKENJI)
This file is part of DSInnovators:maverickOne
Copyright (c) 2024 DSInnovators
Licensed under the MIT License
See LICENSE file in the project root for full license information
*/

module instr_decoder_tb;

  //`define ENABLE_DUMPFILE

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-IMPORTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // bring in the testbench essentials functions and macros
  `include "vip/tb_ess.sv"
  `include "maverickOne_pkg.sv"

  import maverickOne_pkg::*;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-LOCALPARAMS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  localparam int Clen = maverickOne_pkg::ILEN;
  localparam int NumInstr = maverickOne_pkg::TOTAL_FUNCS;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-TYPEDEFS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  typedef enum logic [XLEN-1:0] {
    AIMM,
    BIMM,
    CIMM,
    IIMM,
    JIMM,
    RIMM,
    SIMM,
    TIMM,
    UIMM,
    NONE
  } imm_src_t;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-SIGNALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // generates static task start_clk_i with tHigh:4ns tLow:6ns
  `CREATE_CLK(clk_i, 2ns, 2ns)

  logic [Clen-1:0] code_i;
  decoded_instr_t cmd_o;
  logic [XLEN-1:0] pc_i;
  decoded_instr_t exp_cmd_o;

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-VARIABLES
  //////////////////////////////////////////////////////////////////////////////////////////////////

  bit pc_ok;
  bit func_ok;
  bit rd_ok;
  bit rs1_ok;
  bit rs2_ok;
  bit rs3_ok;
  bit blocking_ok;
  bit imm_ok;
  bit reg_req_ok;
  int tx_pc;
  int tx_func;
  int tx_rd;
  int tx_rs1;
  int tx_rs2;
  int tx_rs3;
  int tx_blocking;
  int tx_imm;
  int tx_reg_req;
  int tx_all;

  logic [256-1:0] instr_check;

  logic [11:0] reg_state;
  imm_src_t imm_src_infer;
  logic [XLEN-1:0] stand_imm;  // stand-in immediate

  int hit_count[NumInstr];

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-ASSIGNMENTS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // update the program counter
  always_comb begin : pc
    exp_cmd_o.pc = pc_i;
  end

  // determine the instruction
  always_comb begin : func
    exp_cmd_o.func = '0;
    casez (code_i)
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz0010111: exp_cmd_o.func[AUIPC] = '1;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz1101111: exp_cmd_o.func[JAL] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz1100111: exp_cmd_o.func[JALR] = '1;
      32'bzzzzzzzzzzzzzzzzzzzzzzzzz0110111: exp_cmd_o.func[LUI] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz1100011: exp_cmd_o.func[BEQ] = '1;
      32'bzzzzzzzzzzzzzzzzz001zzzzz1100011: exp_cmd_o.func[BNE] = '1;
      32'bzzzzzzzzzzzzzzzzz100zzzzz1100011: exp_cmd_o.func[BLT] = '1;
      32'bzzzzzzzzzzzzzzzzz101zzzzz1100011: exp_cmd_o.func[BGE] = '1;
      32'bzzzzzzzzzzzzzzzzz110zzzzz1100011: exp_cmd_o.func[BLTU] = '1;
      32'bzzzzzzzzzzzzzzzzz111zzzzz1100011: exp_cmd_o.func[BGEU] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0000011: exp_cmd_o.func[LB] = '1;
      32'bzzzzzzzzzzzzzzzzz001zzzzz0000011: exp_cmd_o.func[LH] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0000011: exp_cmd_o.func[LW] = '1;
      32'bzzzzzzzzzzzzzzzzz100zzzzz0000011: exp_cmd_o.func[LBU] = '1;
      32'bzzzzzzzzzzzzzzzzz101zzzzz0000011: exp_cmd_o.func[LHU] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0100011: exp_cmd_o.func[SB] = '1;
      32'bzzzzzzzzzzzzzzzzz001zzzzz0100011: exp_cmd_o.func[SH] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0100011: exp_cmd_o.func[SW] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0010011: exp_cmd_o.func[ADDI] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0010011: exp_cmd_o.func[SLTI] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0010011: exp_cmd_o.func[SLTIU] = '1;
      32'bzzzzzzzzzzzzzzzzz100zzzzz0010011: exp_cmd_o.func[XORI] = '1;
      32'bzzzzzzzzzzzzzzzzz110zzzzz0010011: exp_cmd_o.func[ORI] = '1;
      32'bzzzzzzzzzzzzzzzzz111zzzzz0010011: exp_cmd_o.func[ANDI] = '1;
      32'b0000000zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func[ADD] = '1;
      32'b0100000zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func[SUB] = '1;
      32'b0000000zzzzzzzzzz001zzzzz0110011: exp_cmd_o.func[SLL] = '1;
      32'b0000000zzzzzzzzzz010zzzzz0110011: exp_cmd_o.func[SLT] = '1;
      32'b0000000zzzzzzzzzz011zzzzz0110011: exp_cmd_o.func[SLTU] = '1;
      32'b0000000zzzzzzzzzz100zzzzz0110011: exp_cmd_o.func[XOR] = '1;
      32'b0000000zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func[SRL] = '1;
      32'b0100000zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func[SRA] = '1;
      32'b0000000zzzzzzzzzz110zzzzz0110011: exp_cmd_o.func[OR] = '1;
      32'b0000000zzzzzzzzzz111zzzzz0110011: exp_cmd_o.func[AND] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0001111: exp_cmd_o.func[FENCE] = '1;
      32'b00000000000000000000000001110011: exp_cmd_o.func[ECALL] = '1;
      32'b00000000000100000000000001110011: exp_cmd_o.func[EBREAK] = '1;
      32'bzzzzzzzzzzzzzzzzz110zzzzz0000011: exp_cmd_o.func[LWU] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0000011: exp_cmd_o.func[LD] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0100011: exp_cmd_o.func[SD] = '1;
      32'b000000zzzzzzzzzzz001zzzzz0010011: exp_cmd_o.func[SLLI] = '1;
      32'b000000zzzzzzzzzzz101zzzzz0010011: exp_cmd_o.func[SRLI] = '1;
      32'b010000zzzzzzzzzzz101zzzzz0010011: exp_cmd_o.func[SRAI] = '1;
      32'bzzzzzzzzzzzzzzzzz000zzzzz0011011: exp_cmd_o.func[ADDIW] = '1;
      32'b0000000zzzzzzzzzz001zzzzz0011011: exp_cmd_o.func[SLLIW] = '1;
      32'b0000000zzzzzzzzzz101zzzzz0011011: exp_cmd_o.func[SRLIW] = '1;
      32'b0100000zzzzzzzzzz101zzzzz0011011: exp_cmd_o.func[SRAIW] = '1;
      32'b0000000zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func[ADDW] = '1;
      32'b0100000zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func[SUBW] = '1;
      32'b0000000zzzzzzzzzz001zzzzz0111011: exp_cmd_o.func[SLLW] = '1;
      32'b0000000zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func[SRLW] = '1;
      32'b0100000zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func[SRAW] = '1;
      32'bzzzzzzzzzzzzzzzzz001zzzzz1110011: exp_cmd_o.func[CSRRW] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz1110011: exp_cmd_o.func[CSRRS] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz1110011: exp_cmd_o.func[CSRRC] = '1;
      32'bzzzzzzzzzzzzzzzzz101zzzzz1110011: exp_cmd_o.func[CSRRWI] = '1;
      32'bzzzzzzzzzzzzzzzzz110zzzzz1110011: exp_cmd_o.func[CSRRSI] = '1;
      32'bzzzzzzzzzzzzzzzzz111zzzzz1110011: exp_cmd_o.func[CSRRCI] = '1;
      32'b0000001zzzzzzzzzz000zzzzz0110011: exp_cmd_o.func[MUL] = '1;
      32'b0000001zzzzzzzzzz001zzzzz0110011: exp_cmd_o.func[MULH] = '1;
      32'b0000001zzzzzzzzzz010zzzzz0110011: exp_cmd_o.func[MULHSU] = '1;
      32'b0000001zzzzzzzzzz011zzzzz0110011: exp_cmd_o.func[MULHU] = '1;
      32'b0000001zzzzzzzzzz100zzzzz0110011: exp_cmd_o.func[DIV] = '1;
      32'b0000001zzzzzzzzzz101zzzzz0110011: exp_cmd_o.func[DIVU] = '1;
      32'b0000001zzzzzzzzzz110zzzzz0110011: exp_cmd_o.func[REM] = '1;
      32'b0000001zzzzzzzzzz111zzzzz0110011: exp_cmd_o.func[REMU] = '1;
      32'b0000001zzzzzzzzzz000zzzzz0111011: exp_cmd_o.func[MULW] = '1;
      32'b0000001zzzzzzzzzz100zzzzz0111011: exp_cmd_o.func[DIVW] = '1;
      32'b0000001zzzzzzzzzz101zzzzz0111011: exp_cmd_o.func[DIVUW] = '1;
      32'b0000001zzzzzzzzzz110zzzzz0111011: exp_cmd_o.func[REMW] = '1;
      32'b0000001zzzzzzzzzz111zzzzz0111011: exp_cmd_o.func[REMUW] = '1;
      32'b00010zz00000zzzzz010zzzzz0101111: exp_cmd_o.func[LR_W] = '1;
      32'b00011zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[SC_W] = '1;
      32'b00001zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOSWAP_W] = '1;
      32'b00000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOADD_W] = '1;
      32'b00100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOXOR_W] = '1;
      32'b01100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOAND_W] = '1;
      32'b01000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOOR_W] = '1;
      32'b10000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOMIN_W] = '1;
      32'b10100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOMAX_W] = '1;
      32'b11000zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOMINU_W] = '1;
      32'b11100zzzzzzzzzzzz010zzzzz0101111: exp_cmd_o.func[AMOMAXU_W] = '1;
      32'b00010zz00000zzzzz011zzzzz0101111: exp_cmd_o.func[LR_D] = '1;
      32'b00011zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[SC_D] = '1;
      32'b00001zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOSWAP_D] = '1;
      32'b00000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOADD_D] = '1;
      32'b00100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOXOR_D] = '1;
      32'b01100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOAND_D] = '1;
      32'b01000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOOR_D] = '1;
      32'b10000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOMIN_D] = '1;
      32'b10100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOMAX_D] = '1;
      32'b11000zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOMINU_D] = '1;
      32'b11100zzzzzzzzzzzz011zzzzz0101111: exp_cmd_o.func[AMOMAXU_D] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0000111: exp_cmd_o.func[FLW] = '1;
      32'bzzzzzzzzzzzzzzzzz010zzzzz0100111: exp_cmd_o.func[FSW] = '1;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1000011: exp_cmd_o.func[FMADD_S] = '1;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1000111: exp_cmd_o.func[FMSUB_S] = '1;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1001011: exp_cmd_o.func[FNMSUB_S] = '1;
      32'bzzzzz00zzzzzzzzzzzzzzzzzz1001111: exp_cmd_o.func[FNMADD_S] = '1;
      32'b0000000zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FADD_S] = '1;
      32'b0000100zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FSUB_S] = '1;
      32'b0001000zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FMUL_S] = '1;
      32'b0001100zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FDIV_S] = '1;
      32'b010110000000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FSQRT_S] = '1;
      32'b0010000zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FSGNJ_S] = '1;
      32'b0010000zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FSGNJN_S] = '1;
      32'b0010000zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func[FSGNJX_S] = '1;
      32'b0010100zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FMIN_S] = '1;
      32'b0010100zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FMAX_S] = '1;
      32'b110000000000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_W_S] = '1;
      32'b110000000001zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_WU_S] = '1;
      32'b111000000000zzzzz000zzzzz1010011: exp_cmd_o.func[FMV_X_W] = '1;
      32'b1010000zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func[FEQ_S] = '1;
      32'b1010000zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FLT_S] = '1;
      32'b1010000zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FLE_S] = '1;
      32'b111000000000zzzzz001zzzzz1010011: exp_cmd_o.func[FCLASS_S] = '1;
      32'b110100000000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_S_W] = '1;
      32'b110100000001zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_S_WU] = '1;
      32'b111100000000zzzzz000zzzzz1010011: exp_cmd_o.func[FMV_W_X] = '1;
      32'b110000000010zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_L_S] = '1;
      32'b110000000011zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_LU_S] = '1;
      32'b110100000010zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_S_L] = '1;
      32'b110100000011zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_S_LU] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0000111: exp_cmd_o.func[FLD] = '1;
      32'bzzzzzzzzzzzzzzzzz011zzzzz0100111: exp_cmd_o.func[FSD] = '1;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1000011: exp_cmd_o.func[FMADD_D] = '1;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1000111: exp_cmd_o.func[FMSUB_D] = '1;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1001011: exp_cmd_o.func[FNMSUB_D] = '1;
      32'bzzzzz01zzzzzzzzzzzzzzzzzz1001111: exp_cmd_o.func[FNMADD_D] = '1;
      32'b0000001zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FADD_D] = '1;
      32'b0000101zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FSUB_D] = '1;
      32'b0001001zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FMUL_D] = '1;
      32'b0001101zzzzzzzzzzzzzzzzzz1010011: exp_cmd_o.func[FDIV_D] = '1;
      32'b010110100000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FSQRT_D] = '1;
      32'b0010001zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FSGNJ_D] = '1;
      32'b0010001zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FSGNJN_D] = '1;
      32'b0010001zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func[FSGNJX_D] = '1;
      32'b0010101zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FMIN_D] = '1;
      32'b0010101zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FMAX_D] = '1;
      32'b010000000001zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_S_D] = '1;
      32'b010000100000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_D_S] = '1;
      32'b1010001zzzzzzzzzz010zzzzz1010011: exp_cmd_o.func[FEQ_D] = '1;
      32'b1010001zzzzzzzzzz001zzzzz1010011: exp_cmd_o.func[FLT_D] = '1;
      32'b1010001zzzzzzzzzz000zzzzz1010011: exp_cmd_o.func[FLE_D] = '1;
      32'b111000100000zzzzz001zzzzz1010011: exp_cmd_o.func[FCLASS_D] = '1;
      32'b110000100000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_W_D] = '1;
      32'b110000100001zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_WU_D] = '1;
      32'b110100100000zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_D_W] = '1;
      32'b110100100001zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_D_WU] = '1;
      32'b110000100010zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_L_D] = '1;
      32'b110000100011zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_LU_D] = '1;
      32'b111000100000zzzzz000zzzzz1010011: exp_cmd_o.func[FMV_X_D] = '1;
      32'b110100100010zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_D_L] = '1;
      32'b110100100011zzzzzzzzzzzzz1010011: exp_cmd_o.func[FCVT_D_LU] = '1;
      32'b111100100000zzzzz000zzzzz1010011: exp_cmd_o.func[FMV_D_X] = '1;
      32'h30200073:                         exp_cmd_o.func[MRET] = '1;
      32'h10500073:                         exp_cmd_o.func[WFI] = '1;
      default:                              exp_cmd_o.func = '0;
    endcase
  end

  // check for blocking condition
  always_comb begin : blocking
    exp_cmd_o.blocking = '0;
    exp_cmd_o.blocking =
     (exp_cmd_o.func[JAL])
    |(exp_cmd_o.func[JALR])
    |(exp_cmd_o.func[BEQ])
    |(exp_cmd_o.func[BNE])
    |(exp_cmd_o.func[BLT])
    |(exp_cmd_o.func[BGE])
    |(exp_cmd_o.func[BLTU])
    |(exp_cmd_o.func[BGEU])
    |(exp_cmd_o.func[FENCE])
    |(exp_cmd_o.func[MRET])
    |(exp_cmd_o.func[WFI]);
  end

  // determine register state for each instruction
  always_comb begin : register_state
    reg_state = '0;
    unique case (exp_cmd_o.func)
      (1 << LUI):       reg_state = 12'o1000;
      (1 << AUIPC):     reg_state = 12'o1000;
      (1 << JAL):       reg_state = 12'o1000;
      (1 << JALR):      reg_state = 12'o1100;
      (1 << BEQ):       reg_state = 12'o0110;
      (1 << BNE):       reg_state = 12'o0110;
      (1 << BLT):       reg_state = 12'o0110;
      (1 << BGE):       reg_state = 12'o0110;
      (1 << BLTU):      reg_state = 12'o0110;
      (1 << BGEU):      reg_state = 12'o0110;  // checked
      (1 << LB):        reg_state = 12'o1100;
      (1 << LH):        reg_state = 12'o1100;
      (1 << LW):        reg_state = 12'o1100;
      (1 << LBU):       reg_state = 12'o1100;
      (1 << LHU):       reg_state = 12'o1100;  // checked
      (1 << SB):        reg_state = 12'o0110;
      (1 << SH):        reg_state = 12'o0110;
      (1 << SW):        reg_state = 12'o0110;  // checked
      (1 << ADDI):      reg_state = 12'o1100;
      (1 << SLTI):      reg_state = 12'o1100;
      (1 << SLTIU):     reg_state = 12'o1100;
      (1 << XORI):      reg_state = 12'o1100;
      (1 << ORI):       reg_state = 12'o1100;
      (1 << ANDI):      reg_state = 12'o1100;
      (1 << SLLI):      reg_state = 12'o1100;
      (1 << SRLI):      reg_state = 12'o1100;
      (1 << SRAI):      reg_state = 12'o1100;  // checked
      (1 << ADD):       reg_state = 12'o1110;
      (1 << SUB):       reg_state = 12'o1110;
      (1 << SLL):       reg_state = 12'o1110;
      (1 << SLT):       reg_state = 12'o1110;
      (1 << SLTU):      reg_state = 12'o1110;
      (1 << XOR):       reg_state = 12'o1110;
      (1 << SRL):       reg_state = 12'o1110;
      (1 << SRA):       reg_state = 12'o1110;
      (1 << OR):        reg_state = 12'o1110;
      (1 << AND):       reg_state = 12'o1110;
      (1 << FENCE):     reg_state = 12'o1100;
      (1 << ECALL):     reg_state = 12'o0000;
      (1 << EBREAK):    reg_state = 12'o0000;
      (1 << LWU):       reg_state = 12'o1100;
      (1 << LD):        reg_state = 12'o1100;
      (1 << SD):        reg_state = 12'o0110;
      (1 << ADDIW):     reg_state = 12'o1100;
      (1 << SLLIW):     reg_state = 12'o1100;
      (1 << SRLIW):     reg_state = 12'o1100;
      (1 << SRAIW):     reg_state = 12'o1100;
      (1 << ADDW):      reg_state = 12'o1110;
      (1 << SUBW):      reg_state = 12'o1110;
      (1 << SLLW):      reg_state = 12'o1110;
      (1 << SRLW):      reg_state = 12'o1110;
      (1 << SRAW):      reg_state = 12'o1110;
      (1 << CSRRW):     reg_state = 12'o1100;
      (1 << CSRRS):     reg_state = 12'o1100;
      (1 << CSRRC):     reg_state = 12'o1100;
      (1 << CSRRWI):    reg_state = 12'o1000;
      (1 << CSRRSI):    reg_state = 12'o1000;
      (1 << CSRRCI):    reg_state = 12'o1000;
      (1 << MUL):       reg_state = 12'o1110;
      (1 << MULH):      reg_state = 12'o1110;
      (1 << MULHSU):    reg_state = 12'o1110;
      (1 << MULHU):     reg_state = 12'o1110;
      (1 << DIV):       reg_state = 12'o1110;
      (1 << DIVU):      reg_state = 12'o1110;
      (1 << REM):       reg_state = 12'o1110;
      (1 << REMU):      reg_state = 12'o1110;
      (1 << MULW):      reg_state = 12'o1110;
      (1 << DIVW):      reg_state = 12'o1110;
      (1 << DIVUW):     reg_state = 12'o1110;
      (1 << REMW):      reg_state = 12'o1110;
      (1 << REMUW):     reg_state = 12'o1110;
      (1 << LR_W):      reg_state = 12'o1100;
      (1 << SC_W):      reg_state = 12'o1110;
      (1 << AMOSWAP_W): reg_state = 12'o1110;
      (1 << AMOADD_W):  reg_state = 12'o1110;
      (1 << AMOXOR_W):  reg_state = 12'o1110;
      (1 << AMOAND_W):  reg_state = 12'o1110;
      (1 << AMOOR_W):   reg_state = 12'o1110;
      (1 << AMOMIN_W):  reg_state = 12'o1110;
      (1 << AMOMAX_W):  reg_state = 12'o1110;
      (1 << AMOMINU_W): reg_state = 12'o1110;
      (1 << AMOMAXU_W): reg_state = 12'o1110;
      (1 << LR_D):      reg_state = 12'o1100;
      (1 << SC_D):      reg_state = 12'o1110;
      (1 << AMOSWAP_D): reg_state = 12'o1110;
      (1 << AMOADD_D):  reg_state = 12'o1110;
      (1 << AMOXOR_D):  reg_state = 12'o1110;
      (1 << AMOAND_D):  reg_state = 12'o1110;
      (1 << AMOOR_D):   reg_state = 12'o1110;
      (1 << AMOMIN_D):  reg_state = 12'o1110;
      (1 << AMOMAX_D):  reg_state = 12'o1110;
      (1 << AMOMINU_D): reg_state = 12'o1110;
      (1 << AMOMAXU_D): reg_state = 12'o1110;
      (1 << FLW):       reg_state = 12'o2100;
      (1 << FSW):       reg_state = 12'o0120;
      (1 << FADD_S):    reg_state = 12'o2220;
      (1 << FSUB_S):    reg_state = 12'o2220;
      (1 << FMUL_S):    reg_state = 12'o2220;
      (1 << FDIV_S):    reg_state = 12'o2220;
      (1 << FSQRT_S):   reg_state = 12'o2200;
      (1 << FMIN_S):    reg_state = 12'o2220;
      (1 << FMAX_S):    reg_state = 12'o2220;
      (1 << FMADD_S):   reg_state = 12'o2222;
      (1 << FMSUB_S):   reg_state = 12'o2222;
      (1 << FNMADD_S):  reg_state = 12'o2222;
      (1 << FNMSUB_S):  reg_state = 12'o2222;
      (1 << FCVT_W_S):  reg_state = 12'o1200;
      (1 << FCVT_WU_S): reg_state = 12'o1200;
      (1 << FCVT_L_S):  reg_state = 12'o1200;
      (1 << FCVT_LU_S): reg_state = 12'o1200;
      (1 << FCVT_S_W):  reg_state = 12'o2100;
      (1 << FCVT_S_WU): reg_state = 12'o2100;
      (1 << FCVT_S_L):  reg_state = 12'o2100;
      (1 << FCVT_S_LU): reg_state = 12'o2100;
      (1 << FSGNJ_S):   reg_state = 12'o2220;
      (1 << FSGNJN_S):  reg_state = 12'o2220;
      (1 << FSGNJX_S):  reg_state = 12'o2220;
      (1 << FMV_X_W):   reg_state = 12'o1200;
      (1 << FMV_W_X):   reg_state = 12'o2100;
      (1 << FEQ_S):     reg_state = 12'o1220;
      (1 << FLT_S):     reg_state = 12'o1220;
      (1 << FLE_S):     reg_state = 12'o1220;
      (1 << FCLASS_S):  reg_state = 12'o1200;
      (1 << FLD):       reg_state = 12'o2100;
      (1 << FSD):       reg_state = 12'o0120;
      (1 << FADD_D):    reg_state = 12'o2220;
      (1 << FSUB_D):    reg_state = 12'o2220;
      (1 << FMUL_D):    reg_state = 12'o2220;
      (1 << FDIV_D):    reg_state = 12'o2220;
      (1 << FSQRT_D):   reg_state = 12'o2200;
      (1 << FMIN_D):    reg_state = 12'o2220;
      (1 << FMAX_D):    reg_state = 12'o2220;
      (1 << FMADD_D):   reg_state = 12'o2222;
      (1 << FMSUB_D):   reg_state = 12'o2222;
      (1 << FNMADD_D):  reg_state = 12'o2222;
      (1 << FNMSUB_D):  reg_state = 12'o2222;
      (1 << FCVT_W_D):  reg_state = 12'o1200;
      (1 << FCVT_WU_D): reg_state = 12'o1200;
      (1 << FCVT_L_D):  reg_state = 12'o1200;
      (1 << FCVT_LU_D): reg_state = 12'o1200;
      (1 << FCVT_D_W):  reg_state = 12'o2100;
      (1 << FCVT_D_WU): reg_state = 12'o2100;
      (1 << FCVT_D_L):  reg_state = 12'o2100;
      (1 << FCVT_D_LU): reg_state = 12'o2100;
      (1 << FCVT_S_D):  reg_state = 12'o2200;
      (1 << FCVT_D_S):  reg_state = 12'o2210;
      (1 << FSGNJ_D):   reg_state = 12'o2220;
      (1 << FSGNJN_D):  reg_state = 12'o2220;
      (1 << FSGNJX_D):  reg_state = 12'o2220;
      (1 << FMV_X_D):   reg_state = 12'o1200;
      (1 << FMV_D_X):   reg_state = 12'o2100;
      (1 << FEQ_D):     reg_state = 12'o1220;
      (1 << FLT_D):     reg_state = 12'o1220;
      (1 << FLE_D):     reg_state = 12'o1220;
      (1 << FCLASS_D):  reg_state = 12'o1200;
      (1 << MRET):      reg_state = 12'o0000;
      (1 << WFI):       reg_state = 12'o0000;
      default:          reg_state = 12'o0000;
    endcase
  end

  // determine type of immediate per instruction
  always_comb begin : immediate_mapping
    case (exp_cmd_o.func)
      (1 << LUI):       imm_src_infer = UIMM;
      (1 << AUIPC):     imm_src_infer = UIMM;
      (1 << JAL):       imm_src_infer = JIMM;
      (1 << JALR):      imm_src_infer = IIMM;
      (1 << BEQ):       imm_src_infer = BIMM;
      (1 << BNE):       imm_src_infer = BIMM;
      (1 << BLT):       imm_src_infer = BIMM;
      (1 << BGE):       imm_src_infer = BIMM;
      (1 << BLTU):      imm_src_infer = BIMM;
      (1 << BGEU):      imm_src_infer = BIMM;
      (1 << LB):        imm_src_infer = IIMM;
      (1 << LH):        imm_src_infer = IIMM;
      (1 << LW):        imm_src_infer = IIMM;
      (1 << LBU):       imm_src_infer = IIMM;
      (1 << LHU):       imm_src_infer = IIMM;
      (1 << SB):        imm_src_infer = SIMM;
      (1 << SH):        imm_src_infer = SIMM;
      (1 << SW):        imm_src_infer = SIMM;
      (1 << ADDI):      imm_src_infer = IIMM;
      (1 << SLTI):      imm_src_infer = IIMM;
      (1 << SLTIU):     imm_src_infer = IIMM;
      (1 << XORI):      imm_src_infer = IIMM;
      (1 << ORI):       imm_src_infer = IIMM;
      (1 << ANDI):      imm_src_infer = IIMM;
      (1 << SLLI):      imm_src_infer = AIMM;
      (1 << SRLI):      imm_src_infer = AIMM;
      (1 << SRAI):      imm_src_infer = AIMM;
      (1 << ADD):       imm_src_infer = NONE;
      (1 << SUB):       imm_src_infer = NONE;
      (1 << SLL):       imm_src_infer = NONE;
      (1 << SLT):       imm_src_infer = NONE;
      (1 << SLTU):      imm_src_infer = NONE;
      (1 << XOR):       imm_src_infer = NONE;
      (1 << SRL):       imm_src_infer = NONE;
      (1 << SRA):       imm_src_infer = NONE;
      (1 << OR):        imm_src_infer = NONE;
      (1 << AND):       imm_src_infer = NONE;
      (1 << FENCE):     imm_src_infer = IIMM;
      (1 << ECALL):     imm_src_infer = IIMM;
      (1 << EBREAK):    imm_src_infer = IIMM;
      (1 << LWU):       imm_src_infer = IIMM;
      (1 << LD):        imm_src_infer = IIMM;
      (1 << SD):        imm_src_infer = SIMM;
      (1 << ADDIW):     imm_src_infer = IIMM;
      (1 << SLLIW):     imm_src_infer = AIMM;
      (1 << SRLIW):     imm_src_infer = AIMM;
      (1 << SRAIW):     imm_src_infer = AIMM;
      (1 << ADDW):      imm_src_infer = NONE;
      (1 << SUBW):      imm_src_infer = NONE;
      (1 << SLLW):      imm_src_infer = NONE;
      (1 << SRLW):      imm_src_infer = NONE;
      (1 << SRAW):      imm_src_infer = NONE;
      (1 << CSRRW):     imm_src_infer = IIMM;
      (1 << CSRRS):     imm_src_infer = IIMM;
      (1 << CSRRC):     imm_src_infer = IIMM;
      (1 << CSRRWI):    imm_src_infer = CIMM;
      (1 << CSRRSI):    imm_src_infer = CIMM;
      (1 << CSRRCI):    imm_src_infer = CIMM;
      (1 << MUL):       imm_src_infer = NONE;
      (1 << MULH):      imm_src_infer = NONE;
      (1 << MULHSU):    imm_src_infer = NONE;
      (1 << MULHU):     imm_src_infer = NONE;
      (1 << DIV):       imm_src_infer = NONE;
      (1 << DIVU):      imm_src_infer = NONE;
      (1 << REM):       imm_src_infer = NONE;
      (1 << REMU):      imm_src_infer = NONE;
      (1 << MULW):      imm_src_infer = NONE;
      (1 << DIVW):      imm_src_infer = NONE;
      (1 << DIVUW):     imm_src_infer = NONE;
      (1 << REMW):      imm_src_infer = NONE;
      (1 << REMUW):     imm_src_infer = NONE;
      (1 << LR_W):      imm_src_infer = TIMM;
      (1 << SC_W):      imm_src_infer = TIMM;
      (1 << AMOSWAP_W): imm_src_infer = TIMM;
      (1 << AMOADD_W):  imm_src_infer = TIMM;
      (1 << AMOXOR_W):  imm_src_infer = TIMM;
      (1 << AMOAND_W):  imm_src_infer = TIMM;
      (1 << AMOOR_W):   imm_src_infer = TIMM;
      (1 << AMOMIN_W):  imm_src_infer = TIMM;
      (1 << AMOMAX_W):  imm_src_infer = TIMM;
      (1 << AMOMINU_W): imm_src_infer = TIMM;
      (1 << AMOMAXU_W): imm_src_infer = TIMM;
      (1 << LR_D):      imm_src_infer = TIMM;
      (1 << SC_D):      imm_src_infer = TIMM;
      (1 << AMOSWAP_D): imm_src_infer = TIMM;
      (1 << AMOADD_D):  imm_src_infer = TIMM;
      (1 << AMOXOR_D):  imm_src_infer = TIMM;
      (1 << AMOAND_D):  imm_src_infer = TIMM;
      (1 << AMOOR_D):   imm_src_infer = TIMM;
      (1 << AMOMIN_D):  imm_src_infer = TIMM;
      (1 << AMOMAX_D):  imm_src_infer = TIMM;
      (1 << AMOMINU_D): imm_src_infer = TIMM;
      (1 << AMOMAXU_D): imm_src_infer = TIMM;
      (1 << FLW):       imm_src_infer = IIMM;
      (1 << FSW):       imm_src_infer = SIMM;
      (1 << FMADD_S):   imm_src_infer = RIMM;
      (1 << FMSUB_S):   imm_src_infer = RIMM;
      (1 << FNMADD_S):  imm_src_infer = RIMM;
      (1 << FNMSUB_S):  imm_src_infer = RIMM;
      (1 << FADD_S):    imm_src_infer = RIMM;
      (1 << FSUB_S):    imm_src_infer = RIMM;
      (1 << FMUL_S):    imm_src_infer = RIMM;
      (1 << FDIV_S):    imm_src_infer = RIMM;
      (1 << FSQRT_S):   imm_src_infer = RIMM;
      (1 << FSGNJ_S):   imm_src_infer = NONE;
      (1 << FSGNJN_S):  imm_src_infer = NONE;
      (1 << FSGNJX_S):  imm_src_infer = NONE;
      (1 << FMIN_S):    imm_src_infer = NONE;
      (1 << FMAX_S):    imm_src_infer = NONE;
      (1 << FCVT_W_S):  imm_src_infer = RIMM;
      (1 << FCVT_WU_S): imm_src_infer = RIMM;
      (1 << FMV_X_W):   imm_src_infer = NONE;
      (1 << FEQ_S):     imm_src_infer = NONE;
      (1 << FLT_S):     imm_src_infer = NONE;
      (1 << FLE_S):     imm_src_infer = NONE;
      (1 << FCLASS_S):  imm_src_infer = NONE;
      (1 << FCVT_S_W):  imm_src_infer = RIMM;
      (1 << FCVT_S_WU): imm_src_infer = RIMM;
      (1 << FMV_W_X):   imm_src_infer = NONE;
      (1 << FCVT_L_S):  imm_src_infer = RIMM;
      (1 << FCVT_LU_S): imm_src_infer = RIMM;
      (1 << FCVT_S_L):  imm_src_infer = RIMM;
      (1 << FCVT_S_LU): imm_src_infer = RIMM;
      (1 << FLD):       imm_src_infer = IIMM;
      (1 << FSD):       imm_src_infer = SIMM;
      (1 << FMADD_D):   imm_src_infer = RIMM;
      (1 << FMSUB_D):   imm_src_infer = RIMM;
      (1 << FNMADD_D):  imm_src_infer = RIMM;
      (1 << FNMSUB_D):  imm_src_infer = RIMM;
      (1 << FADD_D):    imm_src_infer = RIMM;
      (1 << FSUB_D):    imm_src_infer = RIMM;
      (1 << FMUL_D):    imm_src_infer = RIMM;
      (1 << FDIV_D):    imm_src_infer = RIMM;
      (1 << FSQRT_D):   imm_src_infer = RIMM;
      (1 << FSGNJ_D):   imm_src_infer = NONE;
      (1 << FSGNJN_D):  imm_src_infer = NONE;
      (1 << FSGNJX_D):  imm_src_infer = NONE;
      (1 << FMIN_D):    imm_src_infer = NONE;
      (1 << FMAX_D):    imm_src_infer = NONE;
      (1 << FCVT_S_D):  imm_src_infer = RIMM;
      (1 << FCVT_D_S):  imm_src_infer = RIMM;
      (1 << FEQ_D):     imm_src_infer = NONE;
      (1 << FLT_D):     imm_src_infer = NONE;
      (1 << FLE_D):     imm_src_infer = NONE;
      (1 << FCLASS_D):  imm_src_infer = NONE;
      (1 << FCVT_W_D):  imm_src_infer = RIMM;
      (1 << FCVT_WU_D): imm_src_infer = RIMM;
      (1 << FCVT_D_W):  imm_src_infer = RIMM;
      (1 << FCVT_D_WU): imm_src_infer = RIMM;
      (1 << FCVT_L_D):  imm_src_infer = RIMM;
      (1 << FCVT_LU_D): imm_src_infer = RIMM;
      (1 << FMV_X_D):   imm_src_infer = NONE;
      (1 << FCVT_D_L):  imm_src_infer = RIMM;
      (1 << FCVT_D_LU): imm_src_infer = RIMM;
      (1 << FMV_D_X):   imm_src_infer = NONE;
      (1 << MRET):      imm_src_infer = NONE;
      (1 << WFI):       imm_src_infer = NONE;
      default:          imm_src_infer = NONE;
    endcase
  end

  // set source register 3 state and location
  always_comb begin : rs3
    unique case (reg_state[2:0])
      0: exp_cmd_o.rs3 = '0;
      1: exp_cmd_o.rs3 = {1'b0, code_i[31:27]};
      2: exp_cmd_o.rs3 = {1'b1, code_i[31:27]};
    endcase
  end

  // set source register 2 state and location
  always_comb begin : rs2
    unique case (reg_state[5:3])
      0: exp_cmd_o.rs2 = '0;
      1: exp_cmd_o.rs2 = {1'b0, code_i[24:20]};
      2: exp_cmd_o.rs2 = {1'b1, code_i[24:20]};
    endcase
  end

  // set source register 1 state and location
  always_comb begin : rs1
    unique case (reg_state[8:6])
      0: exp_cmd_o.rs1 = '0;
      1: exp_cmd_o.rs1 = {1'b0, code_i[19:15]};
      2: exp_cmd_o.rs1 = {1'b1, code_i[19:15]};
    endcase
  end

  // set destination register state and location
  always_comb begin : rd
    unique case (reg_state[11:9])
      0: exp_cmd_o.rd = '0;
      1: exp_cmd_o.rd = {1'b0, code_i[11:7]};
      2: exp_cmd_o.rd = {1'b1, code_i[11:7]};
    endcase
  end

  // set register requirement
  always_comb begin : reg_req
    if (exp_cmd_o.blocking) exp_cmd_o.reg_req = '1;
    else begin
      exp_cmd_o.reg_req = '0;
      exp_cmd_o.reg_req[exp_cmd_o.rd] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs1] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs2] = 1'b1;
      exp_cmd_o.reg_req[exp_cmd_o.rs3] = 1'b1;
    end
  end

  // set immediate based on instruction type
  always_comb begin : imm
    stand_imm = '0;
    case (imm_src_infer)
      AIMM: begin  // sign extended shift amount
        foreach (stand_imm[i]) stand_imm[i] = (code_i[25]);
        stand_imm[5:0] = code_i[25:20];
        exp_cmd_o.imm  = stand_imm;
      end
      BIMM: begin  // B-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[12:0] = {code_i[31], code_i[7], code_i[30:25], code_i[11:8], 1'b0};
        exp_cmd_o.imm   = stand_imm;
      end
      CIMM: begin  // csr instructions
        stand_imm[11:0] = code_i[31:20];
        stand_imm[16:12] = code_i[19:15];
        exp_cmd_o.imm = stand_imm;
      end
      IIMM: begin  // I-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[11:0] = code_i[31:20];
        exp_cmd_o.imm   = stand_imm;
      end
      JIMM: begin  // J-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[20:0] = {code_i[31], code_i[19:12], code_i[20], code_i[30:21], 1'b0};
        exp_cmd_o.imm   = stand_imm;
      end
      RIMM: begin  // R-TYPE instructions
        stand_imm[2:0] = code_i[14:12];
        exp_cmd_o.imm  = stand_imm;
      end
      SIMM: begin  // S-TYPE instructions
        foreach (stand_imm[i]) stand_imm[i] = (code_i[31]);
        stand_imm[11:0] = {code_i[31:25], code_i[11:7]};
        exp_cmd_o.imm   = stand_imm;
      end
      TIMM: begin
        stand_imm[1:0] = {code_i[26:25]};
        exp_cmd_o.imm  = stand_imm;
      end
      UIMM: begin  // U-TYPE instructions
        stand_imm[31:12] = {code_i[31:12]};
        exp_cmd_o.imm = stand_imm;
      end
      default: exp_cmd_o.imm = stand_imm;
    endcase
  end
  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-RTLS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  instr_decoder u_dut (
      .pc_i,
      .code_i,
      .cmd_o
  );

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-METHODS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  `define INSTR_DECODER_TB_MON_CHECK(__FIELD__)                                       \
    if (exp_cmd_o.``__FIELD__`` !== cmd_o.``__FIELD__``) begin                                    \
      $display(`"``__FIELD__``: Exp:0x%h Got:0x%h`",                                              \
        exp_cmd_o.``__FIELD__``, cmd_o.``__FIELD__``);                                            \
      ``__FIELD__``_ok = 0;                                                                       \
    end else tx_``__FIELD__``++;                                                                  \


  // Task to start input-output monitoring
  task automatic start_in_out_mon();
    pc_ok       = 1;
    func_ok     = 1;
    rd_ok       = 1;
    rs1_ok      = 1;
    rs2_ok      = 1;
    rs3_ok      = 1;
    blocking_ok = 1;
    imm_ok      = 1;
    reg_req_ok  = 1;

    tx_pc       = 0;
    tx_func     = 0;
    tx_rd       = 0;
    tx_rs1      = 0;
    tx_rs2      = 0;
    tx_rs3      = 0;
    tx_blocking = 0;
    tx_imm      = 0;
    tx_reg_req  = 0;

    instr_check = '0;
    tx_all      = 0;

    fork
      forever begin
        @(posedge clk_i);
        tx_all++;
        if (exp_cmd_o !== cmd_o && exp_cmd_o.func !== '0 && cmd_o.func !== '0) begin

          // GEN Func Name
          func_t func;
          func = func_t'($clog2(exp_cmd_o.func));
          $display();
          $write("\033[1;31m[%0t]%s has faults at 0x%08h\033[0m DUT:", $realtime, func.name,
                 code_i);
          foreach (cmd_o.func[i]) begin
            if (cmd_o.func[i]) begin
              func = func_t'(i);
              $write(" %s", func.name);
            end
          end
          $display();
          `INSTR_DECODER_TB_MON_CHECK(pc)
          `INSTR_DECODER_TB_MON_CHECK(func)
          `INSTR_DECODER_TB_MON_CHECK(rd)
          `INSTR_DECODER_TB_MON_CHECK(rs1)
          `INSTR_DECODER_TB_MON_CHECK(rs2)
          `INSTR_DECODER_TB_MON_CHECK(rs3)
          `INSTR_DECODER_TB_MON_CHECK(blocking)
          `INSTR_DECODER_TB_MON_CHECK(imm)
          `INSTR_DECODER_TB_MON_CHECK(reg_req)
          $display();
          result_print(0, "Test Failed due to fault");
          $finish;
        end else begin
          tx_pc++;
          tx_func++;
          tx_rd++;
          tx_rs1++;
          tx_rs2++;
          tx_rs3++;
          tx_blocking++;
          tx_imm++;
          tx_reg_req++;
          hit_count[$clog2(exp_cmd_o.func)]++;
        end
      end
    join_none
  endtask

  // Task to start random drive on inputs
  task automatic start_random_drive();
    fork
      forever begin
        @(posedge clk_i);
        pc_i <= $urandom;
        randcase
          1: code_i <= (($urandom & 'hFFFFFF80) | 'h00000037);  // LUI
          1: code_i <= (($urandom & 'hFFFFFF80) | 'h00000017);  // AUIPC
          1: code_i <= (($urandom & 'hFFFFFF80) | 'h0000006F);  // JAL
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00000067);  // JALR
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00000063);  // BEQ
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00001063);  // BNE
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00004063);  // BLT
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00005063);  // BGE
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00006063);  // BLTU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00007063);  // BGEU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00000003);  // LB
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00001003);  // LH
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002003);  // LW
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00004003);  // LBU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00005003);  // LHU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00000023);  // SB
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00001023);  // SH
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002023);  // SW
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00000013);  // ADDI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002013);  // SLTI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003013);  // SLTIU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00004013);  // XORI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00006013);  // ORI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00007013);  // ANDI
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00000033);  // ADD
          1: code_i <= (($urandom & 'h01FF8F80) | 'h40000033);  // SUB
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00001033);  // SLL
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00002033);  // SLT
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00003033);  // SLTU
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00004033);  // XOR
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00005033);  // SRL
          1: code_i <= (($urandom & 'h01FF8F80) | 'h40005033);  // SRA
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00006033);  // OR
          1: code_i <= (($urandom & 'h01FF8F80) | 'h00007033);  // AND
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h0000000F);  // FENCE
          1: code_i <= (($urandom & 'h00000000) | 'h00000073);  // ECALL
          1: code_i <= (($urandom & 'h00000000) | 'h00100073);  // EBREAK
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00006003);  // LWU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003003);  // LD
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003023);  // SD
          1: code_i <= (($urandom & 'h03FF8F80) | 'h00001013);  // SLLI
          1: code_i <= (($urandom & 'h03FF8F80) | 'h00005013);  // SRLI
          1: code_i <= (($urandom & 'h03FF8F80) | 'h40005013);  // SRAI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h0000001B);  // ADDIW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0000101B);  // SLLIW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0000501B);  // SRLIW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h4000501B);  // SRAIW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0000003B);  // ADDW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h4000003B);  // SUBW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0000103B);  // SLLW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0000503B);  // SRLW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h4000503B);  // SRAW
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00001073);  // CSRRW
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002073);  // CSRRS
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003073);  // CSRRC
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00005073);  // CSRRWI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00006073);  // CSRRSI
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00007073);  // CSRRCI
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02000033);  // MUL
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02001033);  // MULH
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02002033);  // MULHSU
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02003033);  // MULHU
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02004033);  // DIV
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02005033);  // DIVU
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02006033);  // REM
          1: code_i <= (($urandom & 'h01FF8F80) | 'h02007033);  // REMU
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0200003B);  // MULW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0200403B);  // DIVW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0200503B);  // DIVUW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0200603B);  // REMW
          1: code_i <= (($urandom & 'h01FF8F80) | 'h0200703B);  // REMUW
          1: code_i <= (($urandom & 'h060F8F80) | 'h1000202F);  // LR_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h1800202F);  // SC_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h0800202F);  // AMOSWAP_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h0000202F);  // AMOADD_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h2000202F);  // AMOXOR_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h6000202F);  // AMOAND_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h4000202F);  // AMOOR_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'h8000202F);  // AMOMIN_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'hA000202F);  // AMOMAX_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'hC000202F);  // AMOMINU_W
          1: code_i <= (($urandom & 'h07FF8F80) | 'hE000202F);  // AMOMAXU_W
          1: code_i <= (($urandom & 'h060F8F80) | 'h1000302F);  // LR_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h1800302F);  // SC_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h0800302F);  // AMOSWAP_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h0000302F);  // AMOADD_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h2000302F);  // AMOXOR_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h6000302F);  // AMOAND_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h4000302F);  // AMOOR_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'h8000302F);  // AMOMIN_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'hA000302F);  // AMOMAX_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'hC000302F);  // AMOMINU_D
          1: code_i <= (($urandom & 'h07FF8F80) | 'hE000302F);  // AMOMAXU_D
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002007);  // FLW
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00002027);  // FSW
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h00000043);  // FMADD_S
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h00000047);  // FMSUB_S
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h0000004B);  // FNMSUB_S
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h0000004F);  // FNMADD_S
          1: code_i <= (($urandom & 'h01FFFF80) | 'h00000053);  // FADD_S
          1: code_i <= (($urandom & 'h01FFFF80) | 'h08000053);  // FSUB_S
          1: code_i <= (($urandom & 'h01FFFF80) | 'h10000053);  // FMUL_S
          1: code_i <= (($urandom & 'h01FFFF80) | 'h18000053);  // FDIV_S
          1: code_i <= (($urandom & 'h000FFF80) | 'h58000053);  // FSQRT_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'h20000053);  // FSGNJ_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'h20001053);  // FSGNJN_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'h20002053);  // FSGNJX_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'h28000053);  // FMIN_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'h28001053);  // FMAX_S
          1: code_i <= (($urandom & 'h000FFF80) | 'hC0000053);  // FCVT_W_S
          1: code_i <= (($urandom & 'h000FFF80) | 'hC0100053);  // FCVT_WU_S
          1: code_i <= (($urandom & 'h000F8F80) | 'hE0000053);  // FMV_X_W
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA0002053);  // FEQ_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA0001053);  // FLT_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA0000053);  // FLE_S
          1: code_i <= (($urandom & 'h000F8F80) | 'hE0001053);  // FCLASS_S
          1: code_i <= (($urandom & 'h000FFF80) | 'hD0000053);  // FCVT_S_W
          1: code_i <= (($urandom & 'h000FFF80) | 'hD0100053);  // FCVT_S_WU
          1: code_i <= (($urandom & 'h000F8F80) | 'hF0000053);  // FMV_W_X
          1: code_i <= (($urandom & 'h000FFF80) | 'hC0200053);  // FCVT_L_S
          1: code_i <= (($urandom & 'h000FFF80) | 'hC0300053);  // FCVT_LU_S
          1: code_i <= (($urandom & 'h000FFF80) | 'hD0200053);  // FCVT_S_L
          1: code_i <= (($urandom & 'h000FFF80) | 'hD0300053);  // FCVT_S_LU
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003007);  // FLD
          1: code_i <= (($urandom & 'hFFFF8F80) | 'h00003027);  // FSD
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h02000043);  // FMADD_D
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h02000047);  // FMSUB_D
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h0200004B);  // FNMSUB_D
          1: code_i <= (($urandom & 'hF9FFFF80) | 'h0200004F);  // FNMADD_D
          1: code_i <= (($urandom & 'h01FFFF80) | 'h02000053);  // FADD_D
          1: code_i <= (($urandom & 'h01FFFF80) | 'h0A000053);  // FSUB_D
          1: code_i <= (($urandom & 'h01FFFF80) | 'h12000053);  // FMUL_D
          1: code_i <= (($urandom & 'h01FFFF80) | 'h1A000053);  // FDIV_D
          1: code_i <= (($urandom & 'h000FFF80) | 'h5A000053);  // FSQRT_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'h22000053);  // FSGNJ_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'h22001053);  // FSGNJN_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'h22002053);  // FSGNJX_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'h2A000053);  // FMIN_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'h2A001053);  // FMAX_D
          1: code_i <= (($urandom & 'h000FFF80) | 'h40100053);  // FCVT_S_D
          1: code_i <= (($urandom & 'h000FFF80) | 'h42000053);  // FCVT_D_S
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA2002053);  // FEQ_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA2001053);  // FLT_D
          1: code_i <= (($urandom & 'h01FF8F80) | 'hA2000053);  // FLE_D
          1: code_i <= (($urandom & 'h000F8F80) | 'hE2001053);  // FCLASS_D
          1: code_i <= (($urandom & 'h000FFF80) | 'hC2000053);  // FCVT_W_D
          1: code_i <= (($urandom & 'h000FFF80) | 'hC2100053);  // FCVT_WU_D
          1: code_i <= (($urandom & 'h000FFF80) | 'hD2000053);  // FCVT_D_W
          1: code_i <= (($urandom & 'h000FFF80) | 'hD2100053);  // FCVT_D_WU
          1: code_i <= (($urandom & 'h000FFF80) | 'hC2200053);  // FCVT_L_D
          1: code_i <= (($urandom & 'h000FFF80) | 'hC2300053);  // FCVT_LU_D
          1: code_i <= (($urandom & 'h000F8F80) | 'hE2000053);  // FMV_X_D
          1: code_i <= (($urandom & 'h000FFF80) | 'hD2200053);  // FCVT_D_L
          1: code_i <= (($urandom & 'h000FFF80) | 'hD2300053);  // FCVT_D_LU
          1: code_i <= (($urandom & 'h000F8F80) | 'hF2000053);  // FMV_D_X
          1: code_i <= (($urandom & 'h00000000) | 'h30200073);  // MRET
          1: code_i <= (($urandom & 'h00000000) | 'h10500073);  // WFI
          1: code_i <= (($urandom & 'hFFFFFFFF) | 'h00000000);  // Random
        endcase
      end
    join_none
  endtask

  //////////////////////////////////////////////////////////////////////////////////////////////////
  //-PROCEDURALS
  //////////////////////////////////////////////////////////////////////////////////////////////////

  // Initial block to handle fatal timeout
  initial begin
    automatic bit keep_going = 1;
    func_t instr;
    while (keep_going) begin
      repeat (5000) @(posedge clk_i);
      $write("\033[1;33m%0t Remaining:\033[0m", $realtime);
      keep_going = 0;
      foreach (hit_count[i]) begin
        if (hit_count[i] < 1000) begin
          keep_going = 1;
          instr = func_t'(i);
          $write(" %s", instr.name);
        end
      end
      $display("\n");
    end

    $display("Success_pc             %d", tx_pc);
    $display("Success_func           %d", tx_func);
    $display("Success_rd             %d", tx_rd);
    $display("Success_rs1            %d", tx_rs1);
    $display("Success_rs2            %d", tx_rs2);
    $display("Success_rs3            %d", tx_rs3);
    $display("Success_blocking       %d", tx_blocking);
    $display("Success_imm            %d", tx_imm);
    $display("Success_reg_req        %d", tx_reg_req);
    $display("Total runs:            %d", tx_all);

    result_print(pc_ok, "PC read check");
    result_print(func_ok, "FUNC read check");
    result_print(rd_ok, "RD read check");
    result_print(rs1_ok, "RS1 read check");
    result_print(rs2_ok, "RS2 read check");
    result_print(rs3_ok, "RS3 read check");
    result_print(blocking_ok, "BLOCKING read check");
    result_print(imm_ok, "IMM read check");
    result_print(reg_req_ok, "REG_REQ read check");
    $finish;
  end

  // Initial block to start clock, monitor & drive
  initial begin
    pc_i   = '0;
    code_i = '0;
    start_clk_i();
    start_in_out_mon();
    start_random_drive();
  end

endmodule
