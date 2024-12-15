# branch_target_buffer (module)

### Author : Subhan Zawad Bihan (https://github.com/SubhanBihan)

## TOP IO
<img src="./branch_target_buffer_top.svg">

## Description

Write a markdown documentation for this systemverilog module:
<br>**This file is part of DSInnovators:maverickOne**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|addr_t|type||logic [63:0]||

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|clk_i|input|logic||Clock input|
|arst_ni|input|logic||Asynchronous Reset input|
|current_addr_i|input|addr_t||Current address (EXEC) input|
|next_addr_i|input|addr_t||Next address (EXEC) input|
|pc_i|input|addr_t||pc (IF) input|
|is_jump_i|input|logic||Is Jump/Branch (IF) input|
|found_o|output|logic||Found match in buffer output|
|table_update_o|output|logic||Table update event output|
|next_pc_o|output|addr_t||Next pc (in case of jump) output|
