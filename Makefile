export __OPT_INSTALL_DEPENDENCIES=yes
export __OPT_TARGET_PREFIX=riscv-unknown-elf-
export __OPT_TARGET_ARCH=riscv-unknown-elf
export __OPT_TARGET_PATH=/usr/local/riscv-unknown-elf
#export __OPT_TARGET_PATH=$(shell realpath ./toolchain)

export __OPT_TARGET_MARCH=rv32ima
export __OPT_TARGET_MABI=ilp32
export __OPT_TARGET_MARCH_FULL=rv32ima_zicsr_zifencei_zba_zbb_zbs_zbkb_zca_zcb_zcmp

export __OPT_TARGET_ENABLE_RISCV32E=no
export __OPT_TARGET_ENABLE_RISCV32I=yes
export __OPT_TARGET_ENABLE_RISCV64I=no
export __OPT_TARGET_ENABLE_RISCV128I=no
export __OPT_TARGET_ENABLE_SINGLE_FLOAT=no
export __OPT_TARGET_ENABLE_DOUBLE_FLOAT=no
export __OPT_TARGET_ENABLE_QUAD_FLOAT=no
export __OPT_TARGET_ENABLE_ADDITIONAL_ABIS=no

export __OPT_BUILD_MULTICORE=-j$(shell nproc)
export __OPT_BUILD_HACKY_MULTICORE=yes

export __VERSION_BINUTILS=binutils-2_46
export __VERSION_GCC=releases/gcc-15.2.0
export __VERSION_NEWLIB=newlib-4.6.0
export __VERSION_UCLIBCPP=v0.2.5
export __VERSION_GDB=gdb-17.1-release
export __VERSION_OPENOCD=master

all:
	sudo mkdir -p ${__OPT_TARGET_PATH}
	sudo chown $(shell id -u):$(shell id -g) ${__OPT_TARGET_PATH}

	chmod u+x build.sh
	./build.sh ${__OPT_TARGET_PATH}
