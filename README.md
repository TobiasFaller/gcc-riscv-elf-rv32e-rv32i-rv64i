RISC-V RV32E / RV32I / RV64I ELF (Last updated: 2025.08.03)
===========================================================

Build script to build the current GCC toolchain from source with riscv-unknown-elf bare-metal as target with ilp32e / ilp32 and ilp64 ABI.
This includes the support for newlib and uclibc++.
The configuration does not support multi-threading and uses init_array and fini_array to initialize the used software libraries.

Toolchain Configuration
-----------------------

| Option                              | Description                                            | Default Value                |
| ----------------------------------- | ------------------------------------------------------ | ---------------------------- |
| __OPT_TARGET_ARCH                   | Target architecture triplet                            | riscv-unknown-elf            |
| __OPT_TARGET_MARCH                  | Default target architecture                            | RV64GC                       |
| __OPT_TARGET_MABI                   | Default target ABI                                     | ILP64D                       |
| __OPT_TARGET_MARCH_FULL             | Maximum target architecture                            | RV64GC                       |
| __OPT_TARGET_ENABLE_RISCV32E        | Enable RV32E variants                                  | yes                          |
| __OPT_TARGET_ENABLE_RISCV32I        | Enable RV32I variants                                  | yes                          |
| __OPT_TARGET_ENABLE_RISCV64G        | Enable RV64G variants                                  | yes                          |
| __OPT_TARGET_ENABLE_RISCV128G       | Enable RV128G variants                                 | no                           |
| __OPT_TARGET_ENABLE_SINGLE_FLOAT    | Enable single-precision floating-point support         | yes                          |
| __OPT_TARGET_ENABLE_DOUBLE_FLOAT    | Enable double-precision floating-point support         | yes                          |
| __OPT_TARGET_ENABLE_QUAD_FLOAT      | Enable quad-precision floating-point support           | no                           |
| __OPT_TARGET_ENABLE_ADDITIONAL_ABIS | Enable additional uncommon ABIs                        | no                           |
| __OPT_TARGET_PATH                   | Installation directory                                 | /usr/local/riscv-unknown-elf |
| __OPT_TARGET_PREFIX                 | Program name prefix                                    | riscv-unknown-elf-           |
| __OPT_BUILD_BINUTILS                | Build GNU Binutils (Binutils)                          | yes                          |
| __OPT_BUILD_GCC                     | Build GNU Compiler Collection (GCC), requires Binutils | yes                          |
| __OPT_BUILD_GDB                     | Build GNU Project Debugger (GDB)                       | yes                          |
| __OPT_BUILD_OPENOCD                 | Build Open On-Chip Debugger (OpenOCD)                  | yes                          |
| __OPT_BUILD_NEWLIB                  | Build Newlib C Library (Newlib), requires GCC          | yes                          |
| __OPT_BUILD_UCLIBCPP                | Build uCLibc++, requires Newlib                        | yes                          |
| __OPT_BUILD_MULTICORE               | Maximum parallel job count for Makefile                | -j$(nproc)                   |
| __OPT_BUILD_HACKY_MULTICORE         | Patches build files to enable multi-threaded builds    | yes (might break the build)  |
| __OPT_INSTALL_DEPENDENCIES          | Install dependencies required for build                | yes                          |

Instruction Sets:

- E: Base Integer Instruction Set with 16 registers
- I: Base Integer Instruction Set with 32 registers

Extensions:

- M: Integer Multiplication and Division
- A: Atomic Instructions
- C: Compressed Instructions
- F: Single-Precision Floating-Point Instructions
- D: Double-Precision Floating-Point Instructions
- Q: Quadruple-Precision Floating-Point Instructions

Library-sharing between the compressed and uncompressed instruction sets is disabled and each architecture / instruction set generates a unique c / c++ library.
The following configuration sets can be built independently or together in one toolchain:

Toolchain Version
-----------------

| Software / Library              | Version | Date             | Homepage                                       | Git Repository                                       |
| ------------------------------- | ------- | ---------------- | ---------------------------------------------- | ---------------------------------------------------- |
| GNU Binutils (Binutils)         | 2.45    | 2025-07-27 09:56 | [Link](https://www.gnu.org/software/binutils/) | [Link](https://sourceware.org/git/binutils-gdb.git)  |
| GNU Project Debugger (GDB)      | 16.3    | 2025-04-20 10:22 | [Link](https://www.gnu.org/software/gdb/)      | [Link](https://sourceware.org/git/binutils-gdb.git)  |
| GNU Compiler Collection (GCC)   | 15.1.0  | 2025-04-25 08:21 | [Link](https://gcc.gnu.org/)                   | [Link](https://gcc.gnu.org/git/gcc.git)              |
| Open On-Chip Debugger (OpenOCD) | 0.12.0  | 2023-01-14 10:14 | [Link](https://openocd.org/)                   | [Link](https://git.code.sf.net/p/openocd/code)       |
| Newlib C Library (Newlib)       | 4.5.0   | 2025-01-01 20:35 | [Link](https://sourceware.org/newlib/)         | [Link](https://sourceware.org/git/newlib-cygwin.git) |
| uCLibc++                        | 0.2.5   | 2019-04-06 17:20 | [Link](https://cxx.uclibc.org/)                | [Link](https://git.busybox.net/uClibc++)             |

Requirements
------------

Build of RV64GC with all ABIs on Ryzen 3950X (16 Cores):

- Disk Space: 15 GiB (Build) / 3 GiB (Installed)
- Memory: 16 GiB (+ 16 GiB when using tmpfs for build directory)
- Build Time: 12 min (with hacky multi-core)

RV32E (Draft)
-------------

Available extension combinations and possible ABIs:

| Architecture | Defautl ABI | Additional ABIs |
| ------------ | ----------- | --------------- |
| RV32E(C)     | ilp32e      |                 |
| RV32EM(C)    | ilp32e      |                 |
| RV32EA(C)    | ilp32e      |                 |
| RV32EMA(C)   | ilp32e      |                 |

RV32I (Ratified)
----------------

Available extension combinations and possible ABIs:

| Architecture            | Default ABI | Additional ABIs |
| ----------------------- | ----------- | --------------- |
| RV32I(C)                | ilp32       |                 |
| RV32IM(C)               | ilp32       |                 |
| RV32IA(C)               | ilp32       |                 |
| RV32IMA(C)              | ilp32       |                 |
| RV32IF(C)               | ilp32f      | ilp32           |
| RV32IMF(C)              | ilp32f      | ilp32           |
| RV32IAF(C)              | ilp32f      | ilp32           |
| RV32IMAF(C)             | ilp32f      | ilp32           |
| RV32IFD(C)              | ilp32d      | ilp32, ilp32f   |
| RV32IMFD(C)             | ilp32d      | ilp32, ilp32f   |
| RV32IAFD(C)             | ilp32d      | ilp32, ilp32f   |
| RV32IMAFD(C) / RV32G(C) | ilp32d      | ilp32, ilp32f   |

RV64I (Ratified)
----------------

Available extension combinations and possible ABIs:

| Architecture              | Default ABI | Additional ABIs    |
| ------------------------- | ----------- | ------------------ |
| RV64I(C)                  | lp64        |                    |
| RV64IM(C)                 | lp64        |                    |
| RV64IA(C)                 | lp64        |                    |
| RV64IMA(C)                | lp64        |                    |
| RV64IF(C)                 | lp64f       | lp64               |
| RV64IMF(C)                | lp64f       | lp64               |
| RV64IAF(C)                | lp64f       | lp64               |
| RV64IMAF(C)               | lp64f       | lp64               |
| RV64IFD(C)                | lp64d       | lp64, lp64f        |
| RV64IMFD(C)               | lp64d       | lp64, lp64f        |
| RV64IAFD(C)               | lp64d       | lp64, lp64f        |
| RV64IMAFD(C) / RV64G(C)   | lp64d       | lp64, lp64f        |
| RV64IFDQ(C)               | lp64q       | lp64, lp64f, lp64d |
| RV64IMFDQ(C)              | lp64q       | lp64, lp64f, lp64d |
| RV64IAFDQ(C)              | lp64q       | lp64, lp64f, lp64d |
| RV64IMAFDQ(C) / RV64GQ(C) | lp64q       | lp64, lp64f, lp64d |

RV128I (Draft) (TODO)
---------------------

Available extension combinations and possible ABIs:

| Architecture                | Default ABI | Additional ABIs |
| --------------------------- | ----------- | --------------- |
| RV128I(C)                   | Unknown     | Unknown         |
| RV128IM(C)                  | Unknown     | Unknown         |
| RV128IA(C)                  | Unknown     | Unknown         |
| RV128IMA(C)                 | Unknown     | Unknown         |
| RV128IF(C)                  | Unknown     | Unknown         |
| RV128IMF(C)                 | Unknown     | Unknown         |
| RV128IAF(C)                 | Unknown     | Unknown         |
| RV128IMAF(C)                | Unknown     | Unknown         |
| RV128IFD(C)                 | Unknown     | Unknown         |
| RV128IMFD(C)                | Unknown     | Unknown         |
| RV128IAFD(C)                | Unknown     | Unknown         |
| RV128IMAFD(C) / RV128G(C)   | Unknown     | Unknown         |
| RV128IFDQ(C)                | Unknown     | Unknown         |
| RV128IMFDQ(C)               | Unknown     | Unknown         |
| RV128IAFDQ(C)               | Unknown     | Unknown         |
| RV128IMAFDQ(C) / RV128GQ(C) | Unknown     | Unknown         |

More information
================

- [RISC-V Specifications](https://riscv.org/specifications/)
- [RISC-V Tools](https://github.com/riscv/riscv-tools)
- [RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)
