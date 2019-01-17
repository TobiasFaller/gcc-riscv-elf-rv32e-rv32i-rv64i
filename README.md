RISC-V RV32E / RV32I / RV64I ELF
================

Build script to build the current GCC toolchain from source with riscv-unknown-elf as target with ilp32e / ilp32 and ilp64 ABI.
This includes the support for newlib and uclibc++.
The configuration does not support multi-threading and uses init_array and fini_array to initialize the used software libraries.

Library-sharing between the compressed and uncompressed instruction sets is disabled and each architecture / instruction set generates a unique c / c++ library.
The following configuration sets can be built independently or together in one toolchain:

RV32E
-----
- RV32E / RV32EC
- RV32EM / RV32EMC
- RV32EA / RV32EAC
- RV32EMA / RV32EMAC

RV32I
-----
- RV32I / RV32IC
- RV32IM / RV32IMC
- RV32IA / RV32IAC
- RV32IMA / RV32IMAC
- RV32IF / RV32IFC
- RV32IMF / RV32IMFC
- RV32IAF / RV32IAFC
- RV32IMAF / RV32IMAFC
- RV32IFD / RV32IFDC
- RV32IMFD / RV32IMFDC
- RV32IAFD / RV32IAFDC
- RV32IMAFD(RV32G) / RV32IMAFDC(RV32GC)

RV64I
-----
- RV64I / RV64IC
- RV64IM / RV64IMC
- RV64IA / RV64IAC
- RV64IMA / RV64IMAC
- RV64IF / RV64IFC
- RV64IMF / RV64IMFC
- RV64IAF / RV64IAFC
- RV64IMAF / RV64IMAFC
- RV64IFD / RV64IFDC
- RV64IMFD / RV64IMFDC
- RV64IAFD / RV64IAFDC
- RV64IMAFD(RV64G) / RV64IMAFDC(RV64GC)

E: Base Integer Instruction Set
I: Base Integer Instruction Set

Extensions:

- M: Integer Multiplication and Division
- A: Atomic Instructions
- C: Compressed Instructions
- F: Single-Precision Floating-Point Instructions
- D: Double-Precision Floating-Point Instructions
- G: Instruction Set I with MACFD

Default target: rv32imc/ilp32

More information
================

- [RISC-V Specifications](https://riscv.org/specifications/)
- [RISC-V Tools](https://github.com/riscv/riscv-tools)
- [RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
