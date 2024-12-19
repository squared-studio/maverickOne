# exe_m64_mult (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./exe_m64_mult_top.svg">

## Description

This module implements a 64-bit multiplier with support for various multiplication operations
including:
- **MUL:** Signed multiplication
- **MULH:** Signed high multiplication
- **MULHSU:** Signed-unsigned high multiplication
- **MULHU:** Unsigned high multiplication
- **MULW:** Word multiplication
<br>**This file is part of DSInnovators:maverickOne**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

<img src="./exe_m64_mult_des.svg">

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|BYPASS_Q0|bit||0||
|BYPASS_Q1|bit||0||

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk_i|input|logic|||
|arst_ni|input|logic|||
|MUL_i|input|logic|||
|MULH_i|input|logic|||
|MULHSU_i|input|logic|||
|MULHU_i|input|logic|||
|MULW_i|input|logic|||
|rs1_i|input|logic [63:0]|||
|rs2_i|input|logic [63:0]|||
|rd_i|input|logic [5:0]|||
|valid_i|input|logic|||
|ready_o|output|logic|||
|wr_data_o|output|logic [63:0]|||
|wr_size_o|output|logic [ 1:0]|||
|wr_addr_o|output|logic [ 5:0]|||
|valid_o|output|logic|||
|ready_i|input|logic|||
