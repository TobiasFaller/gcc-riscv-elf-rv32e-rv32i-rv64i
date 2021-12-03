#!/bin/bash
set -e -x

# --------------------------------------------------------------------------------------------------------------------
# configuration
# --------------------------------------------------------------------------------------------------------------------

# Set __OPT_BUILD_MULTICORE to "" when using WSL on Windows Pre Build 17655 because of a multi-threading bug:
# "Fixed an issue where multithreaded operations could return ENOENT even though the file exists. [GH 2712]"
# https://docs.microsoft.com/en-us/windows/wsl/release-notes#build-17655-skip-ahead
__OPT_TARGET_PREFIX=riscv-unknown-elf-
__OPT_TARGET_ARCH=riscv-unknown-elf

__OPT_TARGET_MARCH=rv64gc
__OPT_TARGET_MABI=lp64d
__OPT_TARGET_MARCH_FULL=rv64gc

__OPT_TARGET_ENABLE_RISCV32E=yes
__OPT_TARGET_ENABLE_RISCV32I=yes
__OPT_TARGET_ENABLE_RISCV64I=yes
__OPT_TARGET_ENABLE_RISCV128I=no
__OPT_TARGET_ENABLE_SINGLE_FLOAT=yes
__OPT_TARGET_ENABLE_DOUBLE_FLOAT=yes
__OPT_TARGET_ENABLE_QUAD_FLOAT=no
__OPT_TARGET_ENABLE_ADDITIONAL_ABIS=no

__OPT_BUILD_MULTICORE=-j$(nproc)
__OPT_BUILD_HACKY_MULTICORE=yes

__VERSION_BINUTILS=binutils-2_37
__VERSION_GDB=gdb-11.1-release
__VERSION_GCC=releases/gcc-11.2.0
__VERSION_NEWLIB=newlib-4.1.0
__VERSION_UCLIBCPP=v0.2.5

if [[ $# = 0 ]]; then
  __OPT_TARGET_PATH=/usr/local/riscv-unknown-elf
elif [[ $# = 1 ]]; then
  __OPT_TARGET_PATH="$1"
else
  echo 'Usage: build.sh <target-path>'
  echo '\ttarget-path: The prefix to use for the toolchain (installation directory)'
  exit 1
fi

# --------------------------------------------------------------------------------------------------------------------
# initialization
# --------------------------------------------------------------------------------------------------------------------

__OPT_TARGET_MULTILIB=""

# -----------------------------------------------------------------------------
# RISC-V 32 BIT (RV32E, RV32I)
# -----------------------------------------------------------------------------

if [ "yes" == $__OPT_TARGET_ENABLE_RISCV32E ]; then
  # Only the ilp32e ABI is currently supported
  __OPT_TARGET_MULTILIB+="
    rv32e-ilp32e-- rv32ec-ilp32e--
    rv32em-ilp32e-- rv32emc-ilp32e--
    rv32ea-ilp32e-- rv32eac-ilp32e--
    rv32ema-ilp32e-- rv32emac-ilp32e--"

  if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
    if [ "yes" == $__OPT_TARGET_ENABLE_SINGLE_FLOAT ]; then
      : # Waiting for Zfinx extension to be specified for floating-point values stored in integer registers
    fi
    if [ "yes" == $__OPT_TARGET_ENABLE_DOUBLE_FLOAT ]; then
      : # Waiting for Zfinx extension to be specified for floating-point values stored in integer registers
   fi
  fi
fi

if [ "yes" == $__OPT_TARGET_ENABLE_RISCV32I ]; then
  # ilp32, ilp32f, ilp32d, (ilp32q) supported
  __OPT_TARGET_MULTILIB+="
    rv32i-ilp32-- rv32ic-ilp32--
    rv32im-ilp32-- rv32imc-ilp32--
    rv32ia-ilp32-- rv32iac-ilp32--
    rv32ima-ilp32-- rv32imac-ilp32--"

  if [ "yes" == $__OPT_TARGET_ENABLE_SINGLE_FLOAT ]; then
    __OPT_TARGET_MULTILIB+="
      rv32if-ilp32f-- rv32ifc-ilp32f--
      rv32imf-ilp32f-- rv32imfc-ilp32f--
      rv32iaf-ilp32f-- rv32iafc-ilp32f--
      rv32imaf-ilp32f-- rv32imafc-ilp32f--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv32if-ilp32-- rv32ifc-ilp32--
        rv32imf-ilp32-- rv32imfc-ilp32--
        rv32iaf-ilp32-- rv32iafc-ilp32--
        rv32imaf-ilp32-- rv32imafc-ilp32--"
    fi
  fi

  if [ "yes" == $__OPT_TARGET_ENABLE_DOUBLE_FLOAT ]; then
    __OPT_TARGET_MULTILIB+="
      rv32ifd-ilp32d-- rv32ifdc-ilp32d--
      rv32imfd-ilp32d-- rv32imfdc-ilp32d--
      rv32iafd-ilp32d-- rv32iafdc-ilp32d--
      rv32g-ilp32d-- rv32gc-ilp32d--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv32ifd-ilp32-- rv32ifdc-ilp32--
        rv32imfd-ilp32-- rv32imfdc-ilp32--
        rv32iafd-ilp32-- rv32iafdc-ilp32--
        rv32g-ilp32-- rv32gc-ilp32--

        rv32ifd-ilp32f-- rv32ifdc-ilp32f--
        rv32imfd-ilp32f-- rv32imfdc-ilp32f--
        rv32iafd-ilp32f-- rv32iafdc-ilp32f--
        rv32g-ilp32f-- rv32gc-ilp32f--"
    fi
  fi

  if [ "yes" == $__OPT_TARGET_ENABLE_QUAD_FLOAT ]; then
    # Does not seem to exist yet
    __OPT_TARGET_MULTILIB+="
      rv32ifdq-ilp32q-- rv32ifdqc-ilp32q--
      rv32imfdq-ilp32q-- rv32imfdqc-ilp32q--
      rv32iafdq-ilp32q-- rv32iafdqc-ilp32q--
      rv32gq-ilp32q-- rv32gqc-ilp32q--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv32ifdq-ilp32-- rv32ifdqc-ilp32--
        rv32imfdq-ilp32-- rv32imfdqc-ilp32--
        rv32iafdq-ilp32-- rv32iafdqc-ilp32--
        rv32gq-ilp32-- rv32gqc-ilp32--

        rv32ifdq-ilp32f-- rv32ifdqc-ilp32f--
        rv32imfdq-ilp32f-- rv32imfdqc-ilp32f--
        rv32iafdq-ilp32f-- rv32iafdqc-ilp32f--
        rv32gq-ilp32f-- rv32gqc-ilp32f--

        rv32ifdq-ilp32d-- rv32ifdqc-ilp32d--
        rv32imfdq-ilp32d-- rv32imfdqc-ilp32d--
        rv32iafdq-ilp32d-- rv32iafdqc-ilp32d--
        rv32gq-ilp32d-- rv32gqc-ilp32d--"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# RISC-V 64 BIT (RV64I)
# -----------------------------------------------------------------------------

if [ "yes" == $__OPT_TARGET_ENABLE_RISCV64I ]; then
__OPT_TARGET_MULTILIB+="
  rv64i-lp64-- rv64ic-lp64--
  rv64im-lp64-- rv64imc-lp64--
  rv64ia-lp64-- rv64iac-lp64--
  rv64ima-lp64-- rv64imac-lp64--"

  if [ "yes" == $__OPT_TARGET_ENABLE_SINGLE_FLOAT ]; then
    __OPT_TARGET_MULTILIB+="
      rv64if-lp64f-- rv64ifc-lp64f--
      rv64imf-lp64f-- rv64imfc-lp64f--
      rv64iaf-lp64f-- rv64iafc-lp64f--
      rv64imaf-lp64f-- rv64imafc-lp64f--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv64if-lp64-- rv64ifc-lp64--
        rv64imf-lp64-- rv64imfc-lp64--
        rv64iaf-lp64-- rv64iafc-lp64--
        rv64imaf-lp64-- rv64imafc-lp64--"
    fi
  fi

  if [ "yes" == $__OPT_TARGET_ENABLE_DOUBLE_FLOAT ]; then
    __OPT_TARGET_MULTILIB+="
      rv64ifd-lp64d-- rv64ifdc-lp64d--
      rv64imfd-lp64d-- rv64imfdc-lp64d--
      rv64iafd-lp64d-- rv64iafdc-lp64d--
      rv64g-lp64d-- rv64gc-lp64d--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv64ifd-lp64-- rv64ifdc-lp64--
        rv64imfd-lp64-- rv64imfdc-lp64--
        rv64iafd-lp64-- rv64iafdc-lp64--
        rv64g-lp64-- rv64gc-lp64--

        rv64ifd-lp64f-- rv64ifdc-lp64f--
        rv64imfd-lp64f-- rv64imfdc-lp64f--
        rv64iafd-lp64f-- rv64iafdc-lp64f--
        rv64g-lp64f-- rv64gc-lp64f--"
    fi
  fi

  if [ "yes" == $__OPT_TARGET_ENABLE_QUAD_FLOAT ]; then
    # Does not seem to exist yet
    __OPT_TARGET_MULTILIB+="
      rv64ifdq-lp64q-- rv64ifdqc-lp64q--
      rv64imfdq-lp64q-- rv64imfdqc-lp64q--
      rv64iafdq-lp64q-- rv64iafdqc-lp64q--
      rv64gq-lp64q-- rv64gqc-lp64q--"

    if [ "yes" == $__OPT_TARGET_ENABLE_ADDITIONAL_ABIS ]; then
      __OPT_TARGET_MULTILIB+="
        rv64ifdq-lp64-- rv64ifdqc-lp64--
        rv64imfdq-lp64-- rv64imfdqc-lp64--
        rv64iafdq-lp64-- rv64iafdqc-lp64--
        rv64gq-lp64-- rv64gqc-lp64--

        rv64ifdq-lp64f-- rv64ifdqc-lp64f--
        rv64imfdq-lp64f-- rv64imfdqc-lp64f--
        rv64iafdq-lp64f-- rv64iafdqc-lp64f--
        rv64gq-lp64f-- rv64gqc-lp64f--

        rv64ifdq-lp64d-- rv64ifdqc-lp64d--
        rv64imfdq-lp64d-- rv64imfdqc-lp64d--
        rv64iafdq-lp64d-- rv64iafdqc-lp64d--
        rv64gq-lp64d-- rv64gqc-lp64d--"
    fi
  fi
fi

# -----------------------------------------------------------------------------
# RISC-V 128 BIT (RV128I)
# -----------------------------------------------------------------------------

if [ "yes" == $__OPT_TARGET_ENABLE_RISCV128I ]; then
  : # Waiting for RV128 specification / GCC
fi

# -----------------------------------------------------------------------------
# directories
# -----------------------------------------------------------------------------

export PATH=$PATH:${__OPT_TARGET_PATH}/bin
__ROOT_DIR=`pwd`
__SRC_DIR=$__ROOT_DIR/src
__BUILD_DIR=$__ROOT_DIR/build

mkdir -p $__SRC_DIR
mkdir -p $__BUILD_DIR

# --------------------------------------------------------------------------------------------------------------------
# installation
# --------------------------------------------------------------------------------------------------------------------

if [ "yes" == $__OPT_INSTALL_DEPENDENCIES ]; then
  if [ ! -f $__SRC_DIR/.installed-libs ]; then
    # TODO: Add switch-case for OS
    which apt-get && \
    sudo apt-get install -y \
      build-essential linux-headers-generic flex bison texinfo autoconf python3 \
      libgmp-dev libgmp10 \
      libmpfr-dev libmpfr6 \
      libmpc-dev libmpc3 \
      zlib1g-dev zlib1g
  fi
  touch $__SRC_DIR/.installed-libs
fi

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
    git fetch -f origin $branch --tags || true
    git reset --hard $branch || git reset --hard refs/tags/$branch
    git clean -dfx
  else
    exit 1;
  fi
}

if [ ! -f $__SRC_DIR/.installed-sources ]; then
  git_checkout $__SRC_DIR/'src-binutils' $__VERSION_BINUTILS 'git://sourceware.org/git/binutils-gdb.git'
  git_checkout $__SRC_DIR/'src-gdb' $__VERSION_GDB 'git://sourceware.org/git/binutils-gdb.git'
  git_checkout $__SRC_DIR/'src-gcc' $__VERSION_GCC 'git://gcc.gnu.org/git/gcc.git'
  git_checkout $__SRC_DIR/'src-newlib' $__VERSION_NEWLIB 'git://sourceware.org/git/newlib-cygwin.git'
  git_checkout $__SRC_DIR/'src-uclibc++' $__VERSION_UCLIBCPP 'git://git.busybox.net/uClibc++'
fi
touch $__SRC_DIR/.installed-sources

# --------------------------------------------------------------------------------------------------------------------
# binutils
# --------------------------------------------------------------------------------------------------------------------

cd $__BUILD_DIR
if [ ! -f .built-binutils ]; then
  rm -rf build-binutils || true
  mkdir build-binutils && cd build-binutils
  $__SRC_DIR/src-binutils/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --with-arch=${__OPT_TARGET_MARCH_FULL} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --enable-lto --disable-nls --disable-wchar_t \
    --enable-initfini-array --without-gdb

  make all ${__OPT_BUILD_MULTICORE}
  make install ${__OPT_BUILD_MULTICORE}
fi
touch $__BUILD_DIR/.built-binutils

# --------------------------------------------------------------------------------------------------------------------
# gcc
# --------------------------------------------------------------------------------------------------------------------

cd $__BUILD_DIR
if [ ! -f .built-gcc ]; then
  __SRC_GCC_MULTILIB=$__SRC_DIR/src-gcc/gcc/config/riscv
  if [ ! -f $__SRC_GCC_MULTILIB/t-elf-multilib64 ]; then
    mv $__SRC_GCC_MULTILIB/t-elf-multilib $__SRC_GCC_MULTILIB/t-elf-multilib64
  fi

  # Generate new multilib list
  python3 $__SRC_GCC_MULTILIB/multilib-generator ${__OPT_TARGET_MULTILIB} \
    > $__SRC_GCC_MULTILIB/t-elf-multilib

  rm -rf build-gcc || true
  mkdir build-gcc && cd build-gcc
  $__SRC_DIR/src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --without-headers --enable-languages=c --with-newlib \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib --enable-initfini-array \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --disable-shared --disable-libssp \
    --with-system-zlib --with-gnu-as --with-gnu-ld

  make all-gcc ${__OPT_BUILD_MULTICORE}
  make install-gcc ${__OPT_BUILD_MULTICORE}
fi
touch $__BUILD_DIR/.built-gcc

# --------------------------------------------------------------------------------------------------------------------
# checking gcc
# --------------------------------------------------------------------------------------------------------------------

function check_generated_type() {
  march=$1
  mabi=$2
  elf_file=$3

  case $march in
    rv32*) local bits=32;;
    rv64*) local bits=64;;
    rv128*) local bits=128;;
    *) echo "Unknown machine architecture"; exit;;
  esac

  case $march in
    rv*c|rv*c*) local rvc=yes;;
    *) local rvc=no;;
  esac

  case $march in
    rv32e|rv32e*) local rve=yes;;
    *) local rve=no;;
  esac

  case $mabi in
    *f) local rvf=yes; local rvd=no;;
    *d) local rvf=no; local rvd=yes;;
    *) local rvf=no; local rvd=no;;
  esac

  ${__OPT_TARGET_PREFIX}readelf $elf_file -a > start-${march}-${mabi}.elf.log

  if [ -z "$(grep -e 'Machine:.*RISC-V' start-${march}-${mabi}.elf.log)" ]; then
    echo "Invalid machine type. Exiting!"; exit;
  fi
  if [ -z "$(grep -e 'Class:.*ELF'"${bits}"'' start-${march}-${mabi}.elf.log)" ]; then
    echo "Invalid class type. Exiting!"; exit;
  fi

  if [ "$rvc" == "yes" ]; then
    if [ -z "$(grep -e 'Flags:.*RVC' start-${march}-${mabi}.elf.log)" ]; then
      echo "RVC flag present. Exiting!"; exit;
    fi
  else
    if [ ! -z "$(grep -e 'Flags:.*RVC' start-${march}-${mabi}.elf.log)" ]; then
      echo "RVC flag not present. Exiting!"; exit;
    fi
  fi

  if [ "$rve" == "yes" ]; then
    if [ -z "$(grep -e 'Flags:.*RVE' start-${march}-${mabi}.elf.log)" ]; then
      echo "RVE flag present. Exiting!"; exit;
    fi
  else
    if [ ! -z "$(grep -e 'Flags:.*RVE' start-${march}-${mabi}.elf.log)" ]; then
      echo "RVE flag not present. Exiting!"; exit;
    fi
  fi

  if [ "$rvf" == "yes" ]; then
    if [ -z "$(grep -e 'Flags:.*single-float ABI' start-${march}-${mabi}.elf.log)" ]; then
      echo "Single-float flag not present. Exiting!"; exit;
    fi
  elif [ "$rvd" == "yes" ]; then
    if [ -z "$(grep -e 'Flags:.*double-float ABI' start-${march}-${mabi}.elf.log)" ]; then
      echo "Double-float flag not present. Exiting!"; exit;
    fi
  else
    if [ -z "$(grep -e 'Flags:.*soft-float ABI' start-${march}-${mabi}.elf.log)" ] \
        && [ -z "$(grep -e 'Flags:.*0x0' start-${march}-${mabi}.elf.log)" ]; then
      echo "Soft-float flag not present. Exiting!"; exit;
    fi
  fi
}

function check_gcc() {
  local __LDFLAGS='-nostdlib -Wl,-Bstatic,-T,link.ld,--no-gc-sections'
  local __CCFLAGS='-Os --std=c99 -ffreestanding -nostdlib'
  local __CPPFLAGS='-Os --std=c++17 -ffreestanding -nostdlib'

  march=$1
  mabi=$2
  has_cpp=$3
  case $march in
  rv32*)
    bits=32;
    ;;
  rv64*)
    bits=64;
    ;;
  rv128*)
    bits=128;
    ;;
  *)
    exit;
    ;;
  esac

  cat > start.s <<EOF
.section .text
_start:
  nop
EOF
  cat > start.c <<EOF
void _start(void) {
  __asm("nop");
}
EOF
  cat > start.cpp <<EOF
void _start(void) {
  __asm("nop");
}
EOF
  cat > link.ld <<EOF
  OUTPUT_FORMAT("elf${bits}-littleriscv", "elf${bits}-littleriscv", "elf{bits}-littleriscv")
  OUTPUT_ARCH(riscv)

  MEMORY {
    MEM (XRW) : ORIGIN = 0x00000000, LENGTH = 0x01000000
  }

  SECTIONS {
    .text : ALIGN(4) {
      __text_start__ = .;
      *(.text .text.*)
      __text_end__ = .;
    } > MEM
}
EOF

  echo "Checking GCC arch=${march} with abi=${mabi}:"
  echo "Testing assembler"
  ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.o -c start.s
  ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.elf start-${march}-${mabi}.o
  check_generated_type $march $mabi start-${march}-${mabi}.elf

  echo "Testing C-compiler"
  ${__OPT_TARGET_PREFIX}gcc ${__CCFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.o -c start.c
  ${__OPT_TARGET_PREFIX}gcc ${__LDFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.elf start-${march}-${mabi}.o
  check_generated_type $march $mabi start-${march}-${mabi}.elf

  if [ "$has_cpp" == "yes" ]; then
    echo "Testing C++-compiler"
    ${__OPT_TARGET_PREFIX}g++ ${__CPPFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.o -c start.cpp
    ${__OPT_TARGET_PREFIX}g++ ${__LDFLAGS} -march=$march -mabi=$mabi -o start-${march}-${mabi}.elf start-${march}-${mabi}.o
    check_generated_type $march $mabi start-${march}-${mabi}.elf
  fi
}

cd $__BUILD_DIR
if [ ! -f .checked-gcc ]; then
  rm -rf check-gcc || true
  mkdir check-gcc && cd check-gcc

  check_gcc $__OPT_TARGET_MARCH $__OPT_TARGET_MABI "no"

  for type in ${__OPT_TARGET_MULTILIB}; do
    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`

    check_gcc $march $mabi "no"
  done
fi
touch $__BUILD_DIR/.checked-gcc

# --------------------------------------------------------------------------------------------------------------------
# newlib (libc)
# --------------------------------------------------------------------------------------------------------------------

cd $__BUILD_DIR
if [ ! -f .built-newlib ]; then
  rm -rf build-newlib || true
  mkdir build-newlib && cd build-newlib
  $__SRC_DIR/src-newlib/configure \
    --target=${__OPT_TARGET_ARCH} \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --prefix=${__OPT_TARGET_PATH} \
    --enable-multilib \
    --disable-newlib-supplied-syscalls --enable-newlib-nano-malloc \
    --enable-newlib-global-atexit --enable-newlib-register-fini \
    --disable-newlib-multithread

  if [ "yes" == $__OPT_BUILD_HACKY_MULTICORE ]; then
    # Patch newlib-sources/config-ml.in to use parallel for-loops for configuration and compilation
    patch --forward --force $__SRC_DIR/src-newlib/config-ml.in <<"EOF" || true
--- <config-ml.in>
+++ <config-ml.in>
@@ -503,7 +503,7 @@
 	    else \
 	      if [ -d ../$${dir}/$${lib} ]; then \
 		flags=`echo $$i | sed -e 's/^[^;]*;//' -e 's/@/ -/g'`; \
-		if (cd ../$${dir}/$${lib}; $(MAKE) $(FLAGS_TO_PASS) \
+		(cd ../$${dir}/$${lib}; $(MAKE) $(FLAGS_TO_PASS) \
 				CFLAGS="$(CFLAGS) $${flags}" \
 				CCASFLAGS="$(CCASFLAGS) $${flags}" \
 				FCFLAGS="$(FCFLAGS) $${flags}" \
@@ -523,15 +523,11 @@
 				INSTALL_DATA="$(INSTALL_DATA)" \
 				INSTALL_PROGRAM="$(INSTALL_PROGRAM)" \
 				INSTALL_SCRIPT="$(INSTALL_SCRIPT)" \
-				$(DO)); then \
-		  true; \
-		else \
-		  exit 1; \
-		fi; \
+				$(DO)) & \
 	      else true; \
 	      fi; \
 	    fi; \
-	  done; \
+	  done; wait; \
 	fi
 
 # FIXME: There should be an @-sign in front of the `if'.
@@ -660,8 +656,7 @@
   # cd to top-level-build-dir/${with_target_subdir}
   cd ..
 
-  for ml_dir in ${multidirs}; do
-
+  for ml_dir in ${multidirs}; do (
     if [ "${ml_verbose}" = --verbose ]; then
       echo "Running configure in multilib subdir ${ml_dir}"
       echo "pwd: `${PWDCMD-pwd}`"
@@ -874,9 +869,8 @@
       exit 1
     fi
 
-    cd "${ML_POPDIR}"
-
-  done
+    cd "${ML_POPDIR}" )&
+  done; wait
 
   cd "${ml_origdir}"
 fi
EOF
  fi

  make all ${__OPT_BUILD_MULTICORE}
  make install ${__OPT_BUILD_MULTICORE}
fi
touch $__BUILD_DIR/.built-newlib

# --------------------------------------------------------------------------------------------------------------------
# gcc stage 2
# --------------------------------------------------------------------------------------------------------------------

cd $__BUILD_DIR
if [ ! -f .built-gcc-stage2 ]; then
  __SRC_GCC_MULTILIB=$__SRC_DIR/src-gcc/gcc/config/riscv
  if [ ! -f $__SRC_GCC_MULTILIB/t-elf-multilib64 ]; then
    mv $__SRC_GCC_MULTILIB/t-elf-multilib $__SRC_GCC_MULTILIB/t-elf-multilib64
    $__SRC_GCC_MULTILIB/multilib-generator ${__OPT_TARGET_MULTILIB} \
      > $__SRC_GCC_MULTILIB/t-elf-multilib
  fi

  rm -rf build-gcc-stage2 || true
  mkdir build-gcc-stage2 && cd build-gcc-stage2
  $__SRC_DIR/src-gcc/configure \
    --target=${__OPT_TARGET_ARCH} \
    --prefix=${__OPT_TARGET_PATH} \
    --program-prefix=${__OPT_TARGET_PREFIX} \
    --without-headers --enable-languages=c,c++ --with-newlib \
    --with-arch=${__OPT_TARGET_MARCH} --with-abi=${__OPT_TARGET_MABI} \
    --enable-lto --enable-multilib --enable-initfini-array \
    --disable-nls --disable-wchar_t --disable-threads --disable-libstdcxx \
    --disable-shared --disable-libssp \
    --with-system-zlib --with-gnu-as --with-gnu-ld --enable-gold

  make all ${__OPT_BUILD_MULTICORE}
  make install ${__OPT_BUILD_MULTICORE}
fi
touch $__BUILD_DIR/.built-gcc-stage2

# --------------------------------------------------------------------------------------------------------------------
# checking gcc of stage 2
# --------------------------------------------------------------------------------------------------------------------

cd $__BUILD_DIR
if [ ! -f .checked-gcc-stage-2 ]; then
  rm -rf check-gcc-stage-2 || true
  mkdir check-gcc-stage-2 && cd check-gcc-stage-2

  check_gcc $__OPT_TARGET_MARCH $__OPT_TARGET_MABI "yes"

  for type in ${__OPT_TARGET_MULTILIB}; do
    march=`echo $type | sed 's/\(.*\)-\(.*\)--/\1/'`
    mabi=`echo $type | sed 's/\(.*\)-\(.*\)--/\2/'`

    check_gcc $march $mabi "yes"
  done
fi
touch $__BUILD_DIR/.checked-gcc-stage-2

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
  sed -i -E 's|.*DODEBUG.*|DODEBUG=y|' .config

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

cd $__BUILD_DIR
if [ ! -f .built-uclibc++ ]; then
  cd $__SRC_DIR/src-uclibc++
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

    if [ "yes" == $__OPT_BUILD_HACKY_MULTICORE ]; then
      __BUILD_UCLIBCPP_DIR=$__BUILD_DIR/build-uclibc++/$type
      mkdir -p $__BUILD_UCLIBCPP_DIR && cp -r . $__BUILD_UCLIBCPP_DIR
      (cd $__BUILD_UCLIBCPP_DIR && build_uclibcpp $march $mabi) &
    else
      build_uclibcpp $march $mabi
    fi
  done;

  if [ "yes" == $__OPT_BUILD_HACKY_MULTICORE ]; then
    # Wait for all build workers to finish
    wait < <(jobs -p)
  fi

  # Build default version last
  build_uclibcpp '' ''

  # Rename files to lower case
  cd ${__OPT_TARGET_PATH}/${__OPT_TARGET_ARCH}/lib
  for file in `find . -name libuClibc++.a`; do
    mv $file $(dirname $file)/`echo $(basename $file) | tr [:upper:] [:lower:]`
  done;
fi
touch $__BUILD_DIR/.built-uclibc++ | true

cd $__BUILD_DIR
echo "Done"
