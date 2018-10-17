RISC-V RV32I ELF
================

Build script to build the current GCC toolchain from source with riscv32-unknown-elf as target with ilp32 ABI.
This includes the support for newlib and uclibc++.
The configuration does not support multi-threading and uses init_array and fini_array to initialize the used software libraries.
The library-sharing between the compressed and uncompressed instruction set is disabled.

The following configurations were added for multi-lib:
- RV32E / RV32EC
- RV32EM / RV32EMC
- RV32EA / RV32EAC
- RV32EMA / RV32EMAC
- RV32I / RV32IC
- RV32IM / RV32IMC
- RV32IA / RV32IAC
- RV32IMA / RV32IMAC
- RV32IF / RV32IFC
- RV32IMF / RV32IMFC
- RV32IAF / RV32IAFC
- RV32IMAF / RV32IMAFC

E: Base Integer Instruction Set
I: Base Integer Instruction Set

Extensions:

- M: Integer Multiplication and Division
- A: Atomic Instructions
- C: Compressed Instructions
- F: Single-Precision Floating-Point Instructions

Default target: rv32i/ilp32

More information
================

- [RISC-V Specifications](https://riscv.org/specifications/)
- [RISC-V Tools](https://github.com/riscv/riscv-tools)
- [RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
