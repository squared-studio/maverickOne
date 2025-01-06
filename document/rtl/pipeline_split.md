# pipeline_split (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./pipeline_split_top.svg">

## Description

The purpose of this module is to ensure reliable data transfer by prioritizing the main output path
while providing a fallback to the secondary path if the main path is unavailable. This allows for
efficient handling of data in scenarios where data must be directed to different paths based on
readiness, ensuring no data loss or delay in processing.
<br>**This file is part of DSInnovators:maverickOne**
Copyright (c) 2024 DSInnovators
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|DW|int||8|Data width parameter|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic||Asynchronous reset, active low|
|clk_i|input|logic||Clock input|
|clear_i|input|logic||Synchronous clear signal|
|data_in_i|input|logic [DW-1:0]||Input data|
|data_in_valid_i|input|logic||Input data valid signal|
|data_in_ready_o|output|logic||Input data ready signal|
|data_out_main_o|output|logic [DW-1:0]||Main output data|
|data_out_main_valid_o|output|logic||Main output data valid signal|
|data_out_main_ready_i|input|logic||Main output data ready signal|
|data_out_secondary_o|output|logic [DW-1:0]||Secondary output data|
|data_out_secondary_valid_o|output|logic||Secondary output data valid signal|
|data_out_secondary_ready_i|input|logic||Secondary output data ready signal|
