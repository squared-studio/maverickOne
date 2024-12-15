# decoder_no_valid (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./decoder_no_valid_top.svg">

## Description

<br>**This file is part of DSInnovators:maverickOne**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|NUM_WIRE|int||4|Number of output wires|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|index_i|input|logic [$clog2(NUM_WIRE)-1:0]||Input index|
|wire_o|output|logic [ NUM_WIRE-1:0]||Output wires|
