# Introduction
The `maverickOne` is a 64-bit RISC-V compliant core designed in SystemVerilog. It includes the RV64IMAFD extensions, providing integer, multiplication/division, atomic, floating-point, and double-precision floating-point

### MaverickOne Architecture
<img src="document/march.svg">


# Features

## Instruction Launch
<img src="document/rtl/Launcher.gif">


# Directory Structure
- **.github:** Repository Managements.
- **build:** Auto generated. Contains builds of simulation.
- **document:** Contains all files related to the documentation of the RTL.
- **include:** Contains all headers, macros, constants, packages, etc., used in both RTL and TB.
- **log:** Auto generated. Contains logs of simulation.
- **source:** Contains the SystemVerilog RTL files.
- **submodules:** Contains other git repositories as submodule to this repository.
- **test:** Contains SystemVerilog testbench and it's relevant files.

### [Supported Instruction Set](./document/supported_instructions.md)

### [Supported CSRs](./document/supported_csrs.md)

### [Module List](./document/rtl/modules.md)

### [Coding Guide Lines](./document/coding_guideline.md) ([verible-verilog-lint](https://github.com/chipsalliance/verible))

