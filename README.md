RISC-V RV32E / RV32I / RV64I ELF (WIP)
======================================

Build script to build the current GCC toolchain from source with riscv-unknown-elf as target with ilp32e / ilp32 and ilp64 ABI.
This includes the support for newlib and uclibc++.
The configuration does not support multi-threading and uses init_array and fini_array to initialize the used software libraries.

Toolchain Configuration
-----------------------

| Option                       | Description                      | Default                      |
| ---------------------------- | -------------------------------- | ---------------------------- |
| __OPT_TARGET_ARCH            | Target architecture triplet      | riscv-unknown-elf            |
| __OPT_TARGET_MARCH           | Default target architecture      | RV32IMC                      |
| __OPT_TARGET_MABI            | Default target ABI               | ILP32                        |
| __OPT_TARGET_MARCH_FULL      | Maximum target architecture      | RV64GC                       |
| __OPT_TARGET_ENABLE_RISCV32E | Enable RV32E variants            | yes                          |
| __OPT_TARGET_ENABLE_RISCV32I | Enable RV32I variants            | yes                          |
| __OPT_TARGET_ENABLE_RISCV64G | Enable RV64G variants            | yes                          |
| __OPT_MULTICORE              | Makefile max. parallel job count | -j4                          |
| __OPT_TARGET_PATH            | Installation directory           | /usr/local/riscv-unknown-elf |
| __OPT_TARGET_PREFIX          | Program name prefix              | riscv-unknown-elf-           |


Instruction Sets:

- E: Base Integer Instruction Set
- I: Base Integer Instruction Set

Extensions:

- M: Integer Multiplication and Division
- A: Atomic Instructions
- C: Compressed Instructions
- F: Single-Precision Floating-Point Instructions
- D: Double-Precision Floating-Point Instructions

Library-sharing between the compressed and uncompressed instruction sets is disabled and each architecture / instruction set generates a unique c / c++ library.
The following configuration sets can be built independently or together in one toolchain:

RV32E
-----

| Architecture | ABI    |
| ------------ | ------ |
| RV32E(C)     | ilp32e |
| RV32EM(C)    | ilp32e |
| RV32EA(C)    | ilp32e |
| RV32EMA(C)   | ilp32e |

RV32I
-----

| Architecture            | ABI    |
| ----------------------- | ------ |
| RV32I(C)                | ilp32i |
| RV32IM(C)               | ilp32i |
| RV32IA(C)               | ilp32i |
| RV32IMA(C)              | ilp32i |
| RV32IF(C)               | ilp32f |
| RV32IMF(C)              | ilp32f |
| RV32IAF(C)              | ilp32f |
| RV32IMAF(C)             | ilp32f |
| RV32IFD(C)              | ilp32d |
| RV32IMFD(C)             | ilp32d |
| RV32IAFD(C)             | ilp32d |
| RV32IMAFD(C) / RV32G(C) | ilp32d |

RV64I
-----

| Architecture            | ABI   |
| ----------------------- | ----- |
| RV64I(C)                | lp64i |
| RV64IM(C)               | lp64i |
| RV64IA(C)               | lp64i |
| RV64IMA(C)              | lp64i |
| RV64IF(C)               | lp64f |
| RV64IMF(C)              | lp64f |
| RV64IAF(C)              | lp64f |
| RV64IMAF(C)             | lp64f |
| RV64IFD(C)              | lp64d |
| RV64IMFD(C)             | lp64d |
| RV64IAFD(C)             | lp64d |
| RV64IMAFD(C) / RV64G(C) | lp64d |

More information
================

- [RISC-V Specifications](https://riscv.org/specifications/)
- [RISC-V Tools](https://github.com/riscv/riscv-tools)
- [RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
