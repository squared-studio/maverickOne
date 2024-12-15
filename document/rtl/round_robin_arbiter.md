# round_robin_arbiter (module)

### Author : Foez Ahmed (https://github.com/foez-ahmed)

## TOP IO
<img src="./round_robin_arbiter_top.svg">

## Description

The round_robin_arbiter module is designed to fairly allocate resources among multiple requesters
using a round-robin arbitration scheme. It ensures that each requester gets a chance to access the
resource in a cyclic order, preventing any single requester from monopolizing the resource. The
module handles request signals, prioritizes them based on a rotating index, and grants access
accordingly, making it ideal for systems where fair resource distribution is crucial.
<br>**This file is part of DSInnovators:maverickOne**
<br>**Copyright (c) 2024 DSInnovators**
<br>**Licensed under the MIT License**
<br>**See LICENSE file in the project root for full license information**

<img src="./round_robin_arbiter_des.svg">

## Parameters
|Name|Type|Dimension|Default Value|Description|
|-|-|-|-|-|
|NUM_REQ|int||4|Number of requesters|

## Ports
|Name|Direction|Type|Dimension|Description|
|-|-|-|-|-|
|arst_ni|input|logic||Asynchronous reset, active low|
|clk_i|input|logic||Clock input|
|allow_i|input|logic||Allow Request|
|req_i|input|logic [NUM_REQ-1:0]||Request signals|
|gnt_o|output|logic [NUM_REQ-1:0]||Grant signals|
|gnt_found_o|output|logic||Grant Found|
