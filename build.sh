#!/bin/bash
set -e -x

# --------------------------------------------------------------------------------------------------------------------
# configuration
# --------------------------------------------------------------------------------------------------------------------

# Set __OPT_MULTICORE to "" when using WSL because of a multi-threading bug:
# "Fixed an issue where multithreaded operations could return ENOENT even though the file exists. [GH 2712]"
# https://docs.microsoft.com/en-us/windows/wsl/release-notes#build-17655-skip-ahead
__OPT_MULTICORE=-j4
__OPT_TARGET_PATH=/usr/local/riscv-unknown-elf
__OPT_TARGET_PREFIX=riscv-unknown-elf-
__OPT_TARGET_ARCH=riscv-unknown-elf

__OPT_TARGET_MARCH=rv32imc
__OPT_TARGET_MABI=ilp32
__OPT_TARGET_MARCH_FULL=rv64gc

__OPT_TARGET_ENABLE_RISCV32E=yes
__OPT_TARGET_ENABLE_RISCV32I=yes
__OPT_TARGET_ENABLE_RISCV64I=yes

__VERSION_BINUTILS=binutils-2_31_1
__VERSION_GDB=gdb-8.2.1-release
__VERSION_GCC=master #gcc-8_2_0-release does not support rv32e yet
__VERSION_NEWLIB=newlib-3.0.0
__VERSION_UCLIBCPP=v0.2.4

# --------------------------------------------------------------------------------------------------------------------
# initialization
# --------------------------------------------------------------------------------------------------------------------

__OPT_TARGET_MULTILIB=""
if [ "yes" == $__OPT_TARGET_ENABLE_RISCV32E ]; then
__OPT_TARGET_MULTILIB+="
  rv32e-ilp32e-- rv32ec-ilp32e--
  rv32em-ilp32e-- rv32emc-ilp32e--
  rv32ea-ilp32e-- rv32eac-ilp32e--
  rv32ema-ilp32e-- rv32emac-ilp32e--"
fi
if [ "yes" == $__OPT_TARGET_ENABLE_RISCV32I ]; then
__OPT_TARGET_MULTILIB+="
  rv32i-ilp32-- rv32ic-ilp32--
  rv32im-ilp32-- rv32imc-ilp32--
  rv32ia-ilp32-- rv32iac-ilp32--
  rv32ima-ilp32-- rv32imac-ilp32--

  rv32if-ilp32f-- rv32ifc-ilp32f--
  rv32imf-ilp32f-- rv32imfc-ilp32f--
  rv32iaf-ilp32f-- rv32iafc-ilp32f--
  rv32imaf-ilp32f-- rv32imafc-ilp32f--

  rv32ifd-ilp32d-- rv32ifdc-ilp32d--
  rv32imfd-ilp32d-- rv32imfdc-ilp32d--
  rv32iafd-ilp32d-- rv32iafdc-ilp32d--
  rv32g-ilp32d-- rv32gc-ilp32d--"
fi
if [ "yes" == $__OPT_TARGET_ENABLE_RISCV64I ]; then
__OPT_TARGET_MULTILIB+="
  rv64i-lp64-- rv64ic-lp64--
  rv64im-lp64-- rv64imc-lp64--
  rv64ia-lp64-- rv64iac-lp64--
  rv64ima-lp64-- rv64imac-lp64--

  rv64if-lp64f-- rv64ifc-lp64f--
  rv64imf-lp64f-- rv64imfc-lp64f--
  rv64iaf-lp64f-- rv64iafc-lp64f--
  rv64imaf-lp64f-- rv64imafc-lp64f--

  rv64ifd-lp64d-- rv64ifdc-lp64d--
  rv64imfd-lp64d-- rv64imfdc-lp64d--
  rv64iafd-lp64d-- rv64iafdc-lp64d--
  rv64g-lp64d-- rv64gc-lp64d--"
fi

export PATH=$PATH:${__OPT_TARGET_PATH}/bin
__ROOT_DIR=`pwd`

# --------------------------------------------------------------------------------------------------------------------
# installation
# --------------------------------------------------------------------------------------------------------------------

if [ ! -f .installed-libs ]; then
  sudo apt install -y build-essential flex bison texinfo autoconf
  sudo apt install -y linux-headers-amd64
  sudo apt install -y libgmp-dev libgmp10
  sudo apt install -y libmpfr-dev libmpfr4
  sudo apt install -y libmpc-dev libmpc3
  sudo apt install -y zlib1g-dev zlib1g
fi
touch .installed-libs

# --------------------------------------------------------------------------------------------------------------------
# sources
# --------------------------------------------------------------------------------------------------------------------

function git_checkout() {
  directory=$1
  branch=$2
  repository=$3

  if [ ! -d $directory ]; then
    git clone --config core.autocrlf=input --depth 1 --branch $branch $repository $directory \
      && cd $directory && git checkout -b $branch
  fi

  cd $directory
  if [ $? -eq 0 ]; then
    git fetch -f origin $branch || true
    git reset --hard $branch || git reset --hard refs/tags/$branch
    git clean -dfx
  else
    exit 1;
  fi
}

git_checkout $__ROOT_DIR/'src-binutils' $__VERSION_BINUTILS 'git://sourceware.org/git/binutils-gdb.git'
git_checkout $__ROOT_DIR/'src-gdb' $__VERSION_GDB 'git://sourceware.org/git/binutils-gdb.git'
git_checkout $__ROOT_DIR/'src-gcc' $__VERSION_GCC 'git://gcc.gnu.org/git/gcc.git'
git_checkout $__ROOT_DIR/'src-newlib' $__VERSION_NEWLIB 'git://sourceware.org/git/newlib-cygwin.git'
git_checkout $__ROOT_DIR/'src-uclibc++' $__VERSION_UCLIBCPP 'git://git.busybox.net/uClibc++'

# --------------------------------------------------------------------------------------------------------------------
# binutils
# --------------------------------------------------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-binutils ]; then
  rm -rf build-binutils || true
  mkdir build-binutils && cd build-binutils
  ../src-binutils/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --with-arch=${__OPT_TARGET_MARCH_FULL} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --enable-lto --disable-nls --disable-wchar_t \
    --enable-initfini-array --without-gdb

  make all ${__OPT_MULTICORE}
  make install ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-binutils

# --------------------------------------------------------------------------------------------------------------------
# gcc
# --------------------------------------------------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-gcc ]; then
  __SRC_GCC_MULTILIB=./src-gcc/gcc/config/riscv
  if [ ! -f $__SRC_GCC_MULTILIB/t-elf-multilib64 ]; then
    mv $__SRC_GCC_MULTILIB/t-elf-multilib $__SRC_GCC_MULTILIB/t-elf-multilib64
    $__SRC_GCC_MULTILIB/multilib-generator ${__OPT_TARGET_MULTILIB} \
      > $__SRC_GCC_MULTILIB/t-elf-multilib
  fi

  rm -rf build-gcc || true
  mkdir build-gcc && cd build-gcc
  ../src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --without-headers --enable-languages=c --with-newlib \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib --enable-initfini-array \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --disable-shared --disable-libssp \
    --with-system-zlib --with-gnu-as --with-gnu-ld

  make all-gcc ${__OPT_MULTICORE}
  make install-gcc ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-gcc

# --------------------------------------------------------------------------------------------------------------------
# checking gcc
# --------------------------------------------------------------------------------------------------------------------

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

# --------------------------------------------------------------------------------------------------------------------
# newlib (libc)
# --------------------------------------------------------------------------------------------------------------------

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

# --------------------------------------------------------------------------------------------------------------------
# gcc stage 2
# --------------------------------------------------------------------------------------------------------------------

cd $__ROOT_DIR
if [ ! -f .built-gcc-stage2 ]; then
  __SRC_GCC_MULTILIB=./src-gcc/gcc/config/riscv
  if [ ! -f $__SRC_GCC_MULTILIB/t-elf-multilib64 ]; then
    mv $__SRC_GCC_MULTILIB/t-elf-multilib $__SRC_GCC_MULTILIB/t-elf-multilib64
    $__SRC_GCC_MULTILIB/multilib-generator ${__OPT_TARGET_MULTILIB} \
      > $__SRC_GCC_MULTILIB/t-elf-multilib
  fi

  rm -rf build-gcc-stage2 || true
  mkdir build-gcc-stage2 && cd build-gcc-stage2
  ../src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --without-headers --enable-languages=c,c++ --with-newlib \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib --enable-initfini-array \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --disable-shared --disable-libssp \
    --with-system-zlib --with-gnu-as --with-gnu-ld

  make all ${__OPT_MULTICORE}
  make install ${__OPT_MULTICORE}
fi
touch $__ROOT_DIR/.built-gcc-stage2

# --------------------------------------------------------------------------------------------------------------------
# uclibc++ (libcpp)
# --------------------------------------------------------------------------------------------------------------------

function build_uclibcpp() {
  MAKE_PARAMS='CROSS_COMPILE="${__OPT_TARGET_PREFIX}"'
  if [ -n "$1" && -n "$2" ]; then
    MAKE_PARAMS+=' HOSTCFLAGS="-march=$1 -mabi=$2"'
    MAKE_PARAMS+=' HOSTCXXFLAGS="-march=$1 -mabi=$2"'
  fi
  alias make="$MAKE_PARAMS make"

  make distclean
  make defconfig

  sed -i -E 's|.*UCLIBCXX_HAS_FLOATS.*|UCLIBCXX_HAS_FLOATS=y|' .config
  sed -i -E 's|.*UCLIBCXX_HAS_LONG_DOUBLE.*|UCLIBCXX_HAS_LONG_DOUBLE=n|' .config
  sed -i -E 's|.*UCLIBCXX_HAS_TLS.*|UCLIBCXX_HAS_TLS=n|' .config

  sed -i -E 's|.*UCLIBCXX_HAS_LFS.*|UCLIBCXX_HAS_LFS=y|' .config
  sed -i -E 's|.*UCLIBCXX_SUPPORT_CDIR.*|UCLIBCXX_SUPPORT_CDIR=y|' .config
  sed -i -E 's|.*UCLIBCXX_SUPPORT_CIN.*|UCLIBCXX_SUPPORT_CIN=y|' .config
  sed -i -E 's|.*UCLIBCXX_SUPPORT_COUT.*|UCLIBCXX_SUPPORT_COUT=y|' .config
  sed -i -E 's|.*UCLIBCXX_SUPPORT_CERR.*|UCLIBCXX_SUPPORT_CERR=y|' .config
  sed -i -E 's|.*UCLIBCXX_SUPPORT_CLOG.*|UCLIBCXX_SUPPORT_CLOG=y|' .config

  sed -i -E 's|.*UCLIBCXX_CODE_EXPANSION.*|UCLIBCXX_CODE_EXPANSION=n|' .config
  sed -i -E 's|.*UCLIBCXX_EXPAND_(.*)=.*|UCLIBCXX_EXPAND_\1=n|' .config

  sed -i 's|.*UCLIBCXX_RUNTIME_PREFIX.*|UCLIBCXX_RUNTIME_PREFIX="'${__OPT_TARGET_PATH}'/'${__OPT_TARGET_ARCH}'"|' .config
  if [ -n "$1" ] && [ -n "$2" ]; then
    sed -i -E 's|.*UCLIBCXX_RUNTIME_LIB_SUBDIR.*|UCLIBCXX_RUNTIME_LIB_SUBDIR="/lib/'$march'/'$mabi'"|' .config;
  else
    sed -i -E 's|.*UCLIBCXX_RUNTIME_LIB_SUBDIR.*|UCLIBCXX_RUNTIME_LIB_SUBDIR="/lib"|' .config;
  fi

  sed -i -E 's|.*UCLIBCXX_EXCEPTION_SUPPORT.*|UCLIBCXX_EXCEPTION_SUPPORT=n|' .config
  sed -i -E 's|.*IMPORT_LIBGCC_EH.*|IMPORT_LIBGCC_EH=n|' .config
  sed -i -E 's|.*BUILD_STATIC_LIB.*|BUILD_STATIC_LIB=y|' .config
  sed -i -E 's|.*BUILD_ONLY_STATIC_LIB.*|BUILD_ONLY_STATIC_LIB=y|' .config

  # Temporary fixes
  sed -i -E 's|typedef basic_istream<char>(.+?)istream;|typedef basic_istream<char, char_traits<char> > istream;|' include/istream
  sed -i -E 's|typedef basic_istream<wchar_t>(.+?)wistream;|typedef basic_istream<wchar_t, char_traits<wchar_t> > wistream;|' include/istream
  sed -i -E 's|typedef basic_ostream<char>(.+?)ostream;|typedef basic_ostream<char, char_traits<char> > ostream;|' include/ostream
  sed -i -E 's|typedef basic_ostream<wchar_t>(.+?)wostream;|typedef basic_ostream<wchar_t, char_traits<wchar_t> > wostream;|' include/ostream
  sed -i -E 's|typedef basic_filebuf<char>(.+?)filebuf;|typedef basic_filebuf<char, char_traits<char> > filebuf;|' include/fstream
  sed -i -E 's|typedef basic_filebuf<wchar_t>(.+?)wfilebuf;|typedef basic_filebuf<wchar_t, char_traits<wchar_t> > wfilebuf;|' include/fstream
  sed -i -E 's|template <class charT,class traits = char_traits<charT> >|template <class charT,class traits>|' include/istream
  sed -i -E 's|template <class charT,class traits = char_traits<charT> >|template <class charT,class traits>|' include/ostream

  make all
  make install
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

  # Build specific target architectures / ABIs
  for type in ${__OPT_TARGET_MULTILIB}; do
    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`
    build_uclibcpp $march $mabi
  done;

  # Build default version last
  build_uclibcpp '' ''

  # Rename files to lower case
  cd ${__OPT_TARGET_PATH}/${__OPT_TARGET_ARCH}/lib
  for file in `find . -name libuClibc++.a`; do
    mv $file $(dirname $file)/`echo $(basename $file) | tr [:upper:] [:lower:]`
  done;
fi
touch $__ROOT_DIR/.built-uclibc++ | true

cd $__ROOT_DIR
echo "Done"