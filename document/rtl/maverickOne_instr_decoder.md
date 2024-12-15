# maverickOne_instr_decoder (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./maverickOne_instr_decoder_top.svg">

## Description

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

<br>**This file is part of DSInnovators:maverickOne**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|XLEN|int||maverickOne_pkg::XLEN| interger register width|
|decoded_instr_t|type||maverickOne_pkg::decoded_instr_t| type definition of decoded instruction|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|pc_i|input|logic [XLEN-1:0]|| 32-bit input instruction code|
|code_i|input|logic [31:0]|| 32-bit input instruction code|
|cmd_o|output|decoded_instr_t|| Output decoded instruction|
