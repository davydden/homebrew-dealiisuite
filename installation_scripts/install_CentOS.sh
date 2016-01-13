#!/bin/bash

# -----------------------------------------------------------------
# DISCLAIMER
# Adapted from http://michal.kosmulski.org/computing/shell-scripts/
# -----------------------------------------------------------------
# This script come without warranty of any kind.
# You use it at your own risk.
# We assume no liability for the accuracy, correctness, completeness, or usefulness of this script, nor for any sort of damages that using it may cause.

# see http://stackoverflow.com/a/29394504/888478
# print version number 2.1.8 to string for comparison
version() {
  printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' ')
}

# echo status
secho() {
  echo -e "\033[0;94m==> \033[1;37m$@\033[0m"
}

# echo status with 2 arguments
secho2() {
  echo -e "\033[0;94m==> \033[1;37m$1 \033[0;32m$2 \033[0m"
}

# echo warning
wecho() {
  echo -e "\033[4;33mWarning:\033[0m $@"
}

# error
becho() {
  echo -e "\033[4;31mError:\033[0m $@"
}

################################################################################
# --------
# SETTINGS
# --------

hbdir=~/.linuxbrew
bashfile=~/.bash_profile
useSystemLibs=true
useMKL=false

if [ $# -eq 0 ]; then
  secho "Using default installation and file paths."
fi

# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# > 0 ]]; do
  key="$1"

  case $key in
    -p|--prefix)
      hbdir="$2"
      shift # past argument
    ;;
    -b|--bashfile)
      bashfile="$2"
      shift # past argument
    ;;
    -n|--no_system_libraries)
      useSystemLibs=false
    ;;
    -m|--mkl)
      useMKL=true
    ;;
    *)
      becho "Unknown option. Exiting..."
      exit 1
    ;;
  esac

  shift # past argument or value
done

secho2 "Linuxbrew installation path:" "$hbdir"
secho2 "Bash file:" "$bashfile"

# -------------------------
# REQUIRES USER INTERACTION
# -------------------------

echo "Do you want to add Homebrew/Linuxbrew and deal.II paths to $bashfile? [Y/n]:"
read addHBpaths

# -----------------------------
# PREREQUISITE SYSTEM LIBRARIES
# -----------------------------
if [ "$useSystemLibs" = true ] ; then
  secho "Use system libraries..."
  if [ "$useMKL" = true ] ; then
    echo -e "The script assumes that the following modules are loaded: \033[0;32mgcc, openmpi, mkl, cmake, git\033[0m"
  else
    echo -e "The script assumes that the following modules are loaded: \033[0;32mgcc, openmpi, cmake, git\033[0m"
  fi
  echo ""
  echo "Before proceeding, make sure it is the case. Otherwise terminate the script (Ctrl+C), run equivalent of"
  if [ "$useMKL" = true ] ; then
    echo -e "\033[1;37mmodule load gcc openmpi/1.8.3-gcc mkl cmake git/2.2.1\033[0m"
  else
    echo -e "\033[1;37mmodule load gcc openmpi/1.8.3-gcc cmake git/2.2.1\033[0m"
  fi
  echo "and rerun the script again. Press any key when ready..."
  read
else
  secho "Will install all base libraries through Linuxbrew."
fi

# --------------
# LINUXBREW BASE
# --------------
export HOMEBREW_PREFIX=$hbdir
git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX

export HOMEBREW_LOGS=$HOMEBREW_PREFIX/_logs
export HOMEBREW_CACHE=$HOMEBREW_PREFIX/_cache
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"

if [ "$useMKL" = true ] ; then
  export HOMEBREW_BLASLAPACK_NAMES="mkl_intel_lp64;mkl_sequential;mkl_core"
  export HOMEBREW_BLASLAPACK_LIB="${MKLROOT}/lib/intel64"
  export HOMEBREW_BLASLAPACK_INC="${MKLROOT}/include"
fi

export CC=mpicc
export CXX=mpicxx
export FC=mpif90
export FF=mpif77

# check if we have recent enough ruby, otherwise build ourselves
install_ruby=false
secho "Check ruby version..."
if builtin command -v ruby > /dev/null; then
  ruby_version="$(ruby -e 'print RUBY_VERSION')"
  ruby_min=1.8.6
  if [ "$(version "$ruby_version")" -lt "$(version "$ruby_min")" ]; then
     install_ruby=true
     echo "$ruby_version is less than $ruby_min , required by Linuxbrew !"
  else
    echo "Found ruby $ruby_version"
  fi
else
  echo "Did not find ruby"
  install_ruby=true
fi

if [ "$install_ruby" = true ]; then
  secho "Compiling ruby..."
  cd $HOMEBREW_PREFIX && \
  mkdir -p _cache && \
  cd _cache && \
  wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz &> wget.log && \
  tar xvzf ruby-2.2.3.tar.gz ruby-2.2.3 &> tar.log && \
  cd ruby-2.2.3 && \
  ./configure --prefix=$HOMEBREW_PREFIX &> config.log && \
  make &> make.log && \
  make install &> install.log
fi

secho "Make simlinks for GCC to make sure Linuxbrew picks it up..."
ln -s `which gcc` $HOMEBREW_PREFIX/bin/gcc-`gcc -dumpversion |cut -d. -f1,2`
ln -s `which g++` $HOMEBREW_PREFIX/bin/g++-`g++ -dumpversion |cut -d. -f1,2`
ln -s `which gfortran` $HOMEBREW_PREFIX/bin/gfortran-`gcc -dumpversion |cut -d. -f1,2`

brew install pkg-config && \
brew install openssl && brew postinstall openssl

if [ "$useSystemLibs" = false ] ; then
   brew install openmpi --c++11 # Requires a Java Runtime
   brew install cmake --without-docs # Currently fails with docs
fi

# -------------
# DEAL.II SUITE
# -------------
brew tap davydden/dealiisuite

if [ "$useSystemLibs" = false ] ; then
  brew install openblas
fi

brew install boost --with-mpi --without-single && \
brew install hdf5 --with-mpi --c++11 --without-cxx && \
brew install hypre --with-mpi --without-check && \
brew install metis && \
brew install parmetis && \
brew install superlu_dist && \
brew install scalapack --without-check && \
brew install mumps && \
brew install petsc --without-check && \
brew install slepc --without-check --without-arpack && \
brew install p4est --without-check && \
HOMEBREW_MAKE_JOBS=2 brew install trilinos --without-fortran && \
brew install numdiff && \
brew install dealii --without-arpack --HEAD # Build problem related to C++11 detected by Trilinos and not deal.II 8.3.0

if [[ -e $bashfile ]]; then
  if [[ (( $addHBpaths == "y" )) || (( $addHBpaths == "Y" )) || (( $addHBpaths == "Yes" )) || (( $addHBpaths == "yes" )) ]]; then
    secho "Adding Homebrew paths to $bashfile"

    echo "" >> $bashfile
    echo "## === LINUXBREW ===" >> $bashfile
    echo "HOMEBREW_PREFIX=$hbdir" >> $bashfile
    echo "HOMEBREW_LOGS=\$HOMEBREW_PREFIX/_logs" >> $bashfile
    echo "HOMEBREW_CACHE=\$HOMEBREW_PREFIX/_cache" >> $bashfile
    echo "PATH=\"\$HOMEBREW_PREFIX/bin:\$PATH\"" >> $bashfile
    echo "MANPATH=\"\$HOMEBREW_PREFIX/share/man:\$MANPATH\"" >> $bashfile
    echo "INFOPATH=\"\$HOMEBREW_PREFIX/share/info:\$INFOPATH\"" >> $bashfile
    echo "DEAL_II_DIR=\$HOMEBREW_PREFIX" >> $bashfile

    if [ "$useMKL" = true ] ; then
      echo "HOMEBREW_BLASLAPACK_NAMES=\"mkl_intel_lp64;mkl_sequential;mkl_core\"" >> $bashfile
      echo "HOMEBREW_BLASLAPACK_LIB=\"\${MKLROOT}/lib/intel64\"" >> $bashfile
      echo "HOMEBREW_BLASLAPACK_INC=\"\${MKLROOT}/include\"" >> $bashfile
    fi
  else
    wecho ""
    echo "To use deal.II you must pass the following flag to CMake when configuring your problems:"
    echo -e "\033[1;37m-DDEAL_II_DIR=$HOMEBREW_PREFIX\033[0m"
  fi
else
  becho "Bash file does not exist. Could not add paths as requested."
fi
