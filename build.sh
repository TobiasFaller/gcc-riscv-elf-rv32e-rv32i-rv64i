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
  rv32if-ilp32-- rv32icf-ilp32-- rv32im-ilp32-- rv32imc-ilp32--
  rv32imaf-ilp32-- rv32imafc-ilp32-- rv32iaf-ilp32-- rv32iafc-ilp32--"

__ROOT_DIR=`pwd`

export PATH=$PATH:${__OPT_TARGET_PATH}/bin

function git_checkout() {
  directory=$1
  branch=$2
  repository=$3

  (cd $directory && git pull origin $branch && git reset --hard HEAD && git clean -dfx) \
  || git clone --config core.autocrlf=input --depth=1 --branch=$branch $repository $directory
}

git_checkout 'riscv-binutils' 'riscv-next' 'https://github.com/riscv/riscv-binutils-gdb.git'
git_checkout 'riscv-gcc' 'riscv-next' 'https://github.com/riscv/riscv-gcc.git'
git_checkout 'riscv-newlib' 'riscv-newlib-next' 'https://github.com/riscv/riscv-newlib.git'
git_checkout 'riscv-uclibc++' 'master' 'git://git.busybox.net/uClibc++'

# ----------------------------------------------------------------------------
# installation
# ----------------------------------------------------------------------------

sudo apt install -y build-essential texinfo

# ----------------------------------------------------------------------------
# binutils
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -d built-binutils ]; then
  rm -rf build-binutils || true
  mkdir build-binutils && cd build-binutils
  ../riscv-binutils/configure \
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
mkdir $__ROOT_DIR/built-binutils | true

# ----------------------------------------------------------------------------
# gcc
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -d built-gcc ]; then
  if [ ! -f ./riscv-gcc/gcc/config/riscv/t-elf-multilib64 ]; then
    mv ./riscv-gcc/gcc/config/riscv/t-elf-multilib ./riscv-gcc/gcc/config/riscv/t-elf-multilib64 | true
    ./riscv-gcc/gcc/config/riscv/multilib-generator ${__OPT_TARGET_MULTILIB} \
      > ./riscv-gcc/gcc/config/riscv/t-elf-multilib32
    patch ./riscv-gcc/gcc/config.gcc ./config.gcc.patch
  fi

  rm -rf build-gcc || true
  mkdir build-gcc && cd build-gcc
  ../riscv-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    ${__OPT_BOOTSTRAP} \
    --without-headers --enable-languages=c,c++ \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --enable-initfini-array
  make all-gcc ${__OPT_MULTICORE}
  make install-gcc ${__OPT_MULTICORE}
fi
mkdir $__ROOT_DIR/built-gcc | true

# ----------------------------------------------------------------------------
# checking gcc
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -d checked-gcc ]; then
  rm -rf check-gcc || true
  mkdir check-gcc && cd check-gcc

  cat >start.s <<EOF
.section .text
_start:
  nop
EOF

  for type in ${__OPT_TARGET_MULTILIB}; do
    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`

    ${__OPT_TARGET_PREFIX}-gcc --march=$march --mabi=$mabi -o $march.o start.s
  done
fi
mkdir $__ROOT_DIR/checked-gcc | true

# ----------------------------------------------------------------------------
# newlib (libc)
# ----------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -d built-newlib ]; then
  rm -rf build-newlib || true
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
fi
mkdir $__ROOT_DIR/built-newlib | true

# ----------------------------------------------------------------------------
# uclibc++ (libcpp)
# ----------------------------------------------------------------------------

function build_uclibcpp() {
  MAKE_PARAMS='CROSS_COMPILE="${__OPT_TARGET_PREFIX}-"'
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
if [ ! -d built-uclibc++ ]; then
  cd riscv-uclibc++
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
mkdir $__ROOT_DIR/built-uclibc++ | true

cd $__ROOT_DIR
echo "Done"