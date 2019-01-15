#!/bin/bash
set -e

__OPT_MULTICORE=-j4
__OPT_BOOTSTRAP=--enable-bootstrap
__OPT_TARGET_PATH=/usr/local/riscv32-unknown-elf
__OPT_TARGET_PREFIX=riscv32-unknown-elf-
__OPT_TARGET_ARCH=riscv32-unknown-elf
__OPT_TARGET_MARCH=rv32i
__OPT_TARGET_MARCH_FULL=rv32imafc
__OPT_TARGET_MABI=ilp32
__OPT_TARGET_MULTILIB="rv32e-ilp32e-- rv32ec-ilp32e-- rv32em-ilp32e-- rv32emc-ilp32e--
  rv32ema-ilp32e-- rv32emac-ilp32e-- rv32ea-ilp32e-- rv32eac-ilp32e--
  rv32i-ilp32-- rv32ic-ilp32-- rv32im-ilp32-- rv32imc-ilp32--
  rv32ima-ilp32-- rv32imac-ilp32-- rv32ia-ilp32-- rv32iac-ilp32--
  rv32if-ilp32-- rv32ifc-ilp32-- rv32im-ilp32-- rv32imc-ilp32--
  rv32imaf-ilp32-- rv32imafc-ilp32-- rv32iaf-ilp32-- rv32iafc-ilp32--"

__VERSION_BINUTILS=binutils-2_31_1
__VERSION_GDB=gdb-8.2.1-release
__VERSION_GCC=gcc-8_2_0-release
__VERSION_NEWLIB=newlib-3.0.0
__VERSION_UCLIBCPP=v0.2.4

export PATH=$PATH:${__OPT_TARGET_PATH}/bin
__ROOT_DIR=`pwd`

# ----------------------------------------------------------------------------
# installation
# ----------------------------------------------------------------------------

if [ ! -f .installed-libs ]; then
  sudo apt install -y build-essential flex bison texinfo
  sudo apt install -y linux-headers-amd64
  sudo apt install -y libgmp-dev libgmp10
  sudo apt install -y libmpfr-dev libmpfr4
  sudo apt install -y libmpc-dev libmpc3
  sudo apt install -y zlib1g-dev zlib1g
fi
touch .installed-libs

# ----------------------------------------------------------------------------
# sources
# ----------------------------------------------------------------------------

function git_checkout() {
  directory=$1
  branch=$2
  repository=$3

  (cd $directory && git pull origin $branch && git reset --hard HEAD && git clean -dfx) \
  || git clone --config core.autocrlf=input --depth=1 --branch=$branch $repository $directory
}

git_checkout 'src-binutils' __VERSION_BINUTILS 'git://sourceware.org/git/binutils-gdb.git'
git_checkout 'src-gdb' __VERSION_GDB 'git://sourceware.org/git/binutils-gdb.git'
git_checkout 'src-gcc' __VERSION_GCC 'git://gcc.gnu.org/git/gcc.git'
git_checkout 'src-newlib' __VERSION_NEWLIB 'git://sourceware.org/git/newlib-cygwin.git'
git_checkout 'src-uclibc++' __VERSION_UCLIBCPP 'git://git.busybox.net/uClibc++'

# ----------------------------------------------------------------------------
# binutils
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-binutils ]; then
  rm -rf build-binutils || true
  mkdir build-binutils && cd build-binutils
  ../src-binutils/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --with-arch=${__OPT_TARGET_MARCH_FULL} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --enable-lto \
    --disable-nls --disable-wchar_t \
    --enable-initfini-array
  make all ${__OPT_MULTICORE}
  make install ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-binutils

# ----------------------------------------------------------------------------
# gcc
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-gcc ]; then
  if [ ! -f ./src-gcc/gcc/config/riscv/t-elf-multilib64 ]; then
    mv ./src-gcc/gcc/config/riscv/t-elf-multilib ./src-gcc/gcc/config/riscv/t-elf-multilib64 | true
    ./src-gcc/gcc/config/riscv/multilib-generator ${__OPT_TARGET_MULTILIB} \
      > ./src-gcc/gcc/config/riscv/t-elf-multilib32
    patch ./src-gcc/gcc/config.gcc ./config.gcc.patch
  fi

  rm -rf build-gcc || true
  mkdir build-gcc && cd build-gcc
  ../src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    ${__OPT_BOOTSTRAP} \
    --without-headers --enable-languages=c,c++ \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --enable-initfini-array \
    --with-system-zlib --with-gnu-as --with-gnu-ld
  make all-gcc ${__OPT_MULTICORE}
  make install-gcc ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-gcc

# ----------------------------------------------------------------------------
# checking gcc
# ----------------------------------------------------------------------------

#cd $__ROOT_DIR
#if [ ! -d checked-gcc ]; then
#  rm -rf check-gcc || true
#  mkdir check-gcc && cd check-gcc
#
#  __LDFLAGS='-nostdlib -Wl,-Bstatic,-T,../test/link.ld,--no-gc-sections'
#  __CCFLAGS='-Os --std=c99 -ffreestanding -nostdlib'
#
#    ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -o start.o -c ../test/start.c
#    ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -o start-asm.o -c ../test/start.s
#    ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -o start.elf start.o
#    ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -o start-asm.elf start-asm.o
#    ${__OPT_TARGET_PREFIX}readelf start.elf -a > start.txt
#    ${__OPT_TARGET_PREFIX}readelf start-asm.elf -a > start-asm.txt
#
#  for type in ${__OPT_TARGET_MULTILIB}; do
#    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
#    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`
#
#    ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -march=$march -mabi=$mabi -o $march.o -c ../test/start.c
#    ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -march=$march -mabi=$mabi -o $march-asm.o -c ../test/start.s
#    ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -o $march.elf $march.o
#    ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -o $march-asm.elf $march-asm.o
#    ${__OPT_TARGET_PREFIX}readelf $march.elf -a > $march.txt
#    ${__OPT_TARGET_PREFIX}readelf $march-asm.elf -a > $march-asm.txt
#  done
#fi
#mkdir $__ROOT_DIR/checked-gcc | true

# ----------------------------------------------------------------------------
# newlib (libc)
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-newlib ]; then
  rm -rf build-newlib || true
  mkdir build-newlib && cd build-newlib
  ../src-newlib/configure \
    --target=${__OPT_TARGET_ARCH} \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --prefix=${__OPT_TARGET_PATH} \
    --enable-multilib \
    --disable-newlib-supplied-syscalls --enable-newlib-nano-malloc \
    --enable-newlib-global-atexit --enable-newlib-register-fini \
    --disable-newlib-multithread
  make all ${__OPT_MULTICORE}
  make install ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-newlib

# ----------------------------------------------------------------------------
# gcc stage 2
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-gcc-stage2 ]; then
  rm -rf build-gcc-stage2 || true
  mkdir build-gcc-stage2 && cd build-gcc-stage2
  ../src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    ${__OPT_BOOTSTRAP} \
    --without-headers --enable-languages=c,c++ \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --enable-initfini-array \
    --with-system-zlib --with-newlib --disable-shared \
    --with-gnu-as --with-gnu-ld
  make all ${__OPT_MULTICORE}
  make install ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-gcc-stage2

# ----------------------------------------------------------------------------
# uclibc++ (libcpp)
# ----------------------------------------------------------------------------

function build_uclibcpp() {
  MAKE_PARAMS='CROSS_COMPILE="${__OPT_TARGET_PREFIX}"'
  if [ -n "$1" && -n "$2" ]; then
    MAKE_PARAMS+=' HOSTCFLAGS="-march=$1 -mabi=$2"'
    MAKE_PARAMS+=' HOSTCXXFLAGS="-march=$1 -mabi=$2"'
  done
  alias make="$MAKE_PARAMS make"

  make distclean
  make defconfig
  patch ./.config ../config.uclibc++.patch

  sed -i 's|UCLIBCXX_RUNTIME_PREFIX=""|UCLIBCXX_RUNTIME_PREFIX="${__OPT_TARGET_PATH}/${__OPT_TARGET_ARCH}"|' .config
  if [ -n "$1" && -n "$2" ]; then
    sed -i 's|UCLIBCXX_RUNTIME_LIB_SUBDIR=".*"|UCLIBCXX_RUNTIME_LIB_SUBDIR="/lib/'$march'/'$mabi'"|' .config
  fi

  make lib
  make install-include install-lib install-bin
  make distclean
}

cd $__ROOT_DIR
if [ ! -f .built-uclibc++ ]; then
  cd src-uclibc++
  git reset --hard HEAD
  git clean -dfx

  # Remove exception handling
  rm ./src/eh_globals.cpp | true
  rm ./src/eh_alloc.cpp | true
  rm ./include/unwind-cxx.h | true

  # Build default version
  build_uclibcpp '' ''

  # Build specific target architectures / ABIs
  for type in ${__OPT_TARGET_MULTILIB}; do
    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`
    build_uclibcpp $march $mabi
  done;

  # Rename files to lower case
  cd ${__OPT_TARGET_PATH}/${__OPT_TARGET_ARCH}/lib
  for file in `find . -name libuClibc++.a`; do
    mv $file $(dirname $file)/`echo $(basename $file) | tr [:upper:] [:lower:]`
  done;
fi
touch $__ROOT_DIR/.built-uclibc++ | true

cd $__ROOT_DIR
echo "Done"