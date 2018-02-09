RISC-V RV32E ELF
================

Build script to build the current GCC toolchain from source with riscv32-unknown-elf as target with ilp32e ABI.
This includes the support for newlib and uclibc++.
The configuration does not support multi-threading and uses init_array and fini_array to initialize the used software libraries.
The library-sharing between the compressed and uncompressed instruction set is disabled.

The following configuration was added for multi-lib:
- RV32E / RV32EC
- RV32EM / RV32EMC
- RV32EA / RV32EAC
- RV32EMA / RV32EMAC

E: Base Integer Instruction Set

Extensions:

- M: Integer Multiplication and Division
- A: Atomic Instructions
- C: Compressed Instructions

Default target: rv32e/ilp32e

More information
================

- [RISC-V Specifications](https://riscv.org/specifications/)
- [RISC-V Tools](https://github.com/riscv/riscv-tools)
- [RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
