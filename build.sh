#!/bin/bash
export __OPT_MULTICORE=-j4
export __OPT_BOOTSTRAP=--enable-bootstrap
export __OPT_TARGET_PATH=/usr/local/riscv32e
export __OPT_TARGET_ARCH=riscv32-unknown-elf
export __OPT_TARGET_MARCH=rv32e
export __OPT_TARGET_MARCH_FULL=rv32emac
export __OPT_TARGET_MABI=ilp32e

export PATH=$PATH:${__OPT_TARGET_PATH}/bin

git config --global core.autocrlf input
git clone --depth=1 --branch=riscv-next https://github.com/riscv/riscv-binutils-gdb.git riscv-binutils
git clone --depth=1 --branch=riscv-next https://github.com/riscv/riscv-gcc.git riscv-gcc
git clone --depth=1 --branch=riscv-newlib-next https://github.com/riscv/riscv-newlib.git riscv-newlib
git clone --depth=1 --branch=master git://git.busybox.net/uClibc++ uclibc++

mkdir build-binutils && cd build-binutils
../riscv-binutils/configure \
--target=${__OPT_TARGET_ARCH} \
--prefix=${__OPT_TARGET_PATH} \
--with-arch=${__OPT_TARGET_MARCH_FULL} \
--enable-lto \
--disable-nls --disable-wchar_t \
--enable-initfini-array
make all ${__OPT_MULTICORE}
make install ${__OPT_MULTICORE}
cd ..

mv ./riscv-gcc/gcc/config/riscv/t-elf-multilib ./riscv-gcc/gcc/config/riscv/t-elf-multilib64 | true
./riscv-gcc/gcc/config/riscv/multilib-generator \
  rv32e-ilp32e-- rv32ec-ilp32e-- rv32em-ilp32e-- rv32emc-ilp32e-- \
  rv32ema-ilp32e-- rv32emac-ilp32e-- rv32ea-ilp32e-- rv32eac-ilp32e-- \
  > ./riscv-gcc/gcc/config/riscv/t-elf-multilib32
patch ./riscv-gcc/gcc/config.gcc ./config.gcc.patch

mkdir build-gcc && cd build-gcc
../riscv-gcc/configure \
--target=${__OPT_TARGET_ARCH} \
--prefix=${__OPT_TARGET_PATH} \
${__OPT_BOOTSTRAP} \
--without-headers --enable-languages=c,c++ \
--with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
--enable-lto --enable-multilib \
--disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
--enable-initfini-array
make all-gcc ${__OPT_MULTICORE}
make install-gcc ${__OPT_MULTICORE}
cd ..

mkdir build-newlib && cd build-newlib
../riscv-newlib/configure \
--target=${__OPT_TARGET_ARCH} \
--with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
--prefix=${__OPT_TARGET_PATH} \
--enable-multilib \
--disable-newlib-supplied-syscalls --enable-newlib-nano-malloc \
--enable-newlib-global-atexit --enable-newlib-register-fini \
--disable-newlib-multithread
make all ${__OPT_MULTICORE}
make install ${__OPT_MULTICORE}
cd ..

export CROSS_COMPILE=${__OPT_TARGET_ARCH}-
export HOSTCFLAGS="-mabi=${__OPT_TARGET_MABI} -march=${__OPT_TARGET_MARCH}"
export HOSTCXXFLAGS="-mabi=${__OPT_TARGET_MABI} -march=${__OPT_TARGET_MARCH}"

cd uclibc++
# Remove exception handling
rm ./src/eh_globals.cpp | true
rm ./src/eh_alloc.cpp | true
rm ./include/unwind-cxx.h | true

make defconfig
patch ./.config ../config.uclibc++.patch

# Patch destination path
sed -i 's|UCLIBCXX_RUNTIME_PREFIX=""|UCLIBCXX_RUNTIME_PREFIX="'${__OPT_TARGET_PATH}'/'${__OPT_TARGET_ARCH}'"|' .config

# Build default version
make lib
make install-include install-lib install-bin
make distclean

# Build specific target architectures / ABIs
types="rv32e/ilp32e rv32ec/ilp32e rv32em/ilp32e rv32emc/ilp32e rv32ema/ilp32e rv32ema/ilp32e rv32emac/ilp32e rv32ea/ilp32e rv32eac/ilp32e"
for type in $types; do
  march=`echo $type | sed 's/\(.*\)\/\(.*\)$/\1/'`
  mabi=`echo $type | sed 's/\(.*\)\/\(.*\)$/\2/'`

  make defconfig
  patch ./.config ../config.uclibc++.patch

  sed -i 's|UCLIBCXX_RUNTIME_PREFIX=""|UCLIBCXX_RUNTIME_PREFIX="'${__OPT_TARGET_PATH}'/'${__OPT_TARGET_ARCH}'"|' .config
  sed -i 's|UCLIBCXX_RUNTIME_LIB_SUBDIR=".*"|UCLIBCXX_RUNTIME_LIB_SUBDIR="/lib/'$march'/'$mabi'"|' .config

  export HOSTCFLAGS="-mabi=$mabi -march=$march"
  export HOSTCXXFLAGS="-mabi=$mabi -march=$march"
  make lib
  make install-lib
  make distclean
done;
cd ..

# Rename files to lower case
orig_dir=`pwd`
cd ${__OPT_TARGET_PATH}/${__OPT_TARGET_ARCH}/lib
for file in `find . -name libuClibc++.a`; do mv $file `echo $file | tr [:upper:] [:lower:]`; done;
cd $orig_dir
