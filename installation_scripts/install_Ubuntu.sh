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

# --------
# SETTINGS
# --------

hbdir=~/.linuxbrew
bashfile=~/.bashrc
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

if [ "$useSystemLibs" = true ] ; then
  secho "Using system libraries (GCC, MPI, CMake, BLAS/LAPACK)."
else
  secho "Will install all base libraries through Linuxbrew."
fi

# -------------------------
# REQUIRES USER INTERACTION
# -------------------------

echo "Do you want to add Homebrew/Linuxbrew and deal.II paths to $bashfile? [Y/n]:"
read addHBpaths

# -----------------------------
# PREREQUISITE SYSTEM LIBRARIES
# -----------------------------

# assume that if we run it once, we should have everything installed
if [[ ! -d $hbdir ]]; then
secho "Prerequisite system libraries"
echo "You are about to be asked for your password so that "
echo "essential system libraries can be installed."
echo "After this, the rest of the build should be automatic."

if [ "$useSystemLibs" = true ] ; then
  sudo apt-get install \
  build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion \
  gcc g++ gfortran \
  mpi-default-bin libopenmpi-dev \
  cmake \
  libblas-dev liblapack-dev > /dev/null
else
  sudo apt-get install \
  build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion \
  gcc g++ gfortran \
  default-jre > /dev/null
fi
sudo -k # Safety first: Invalidate user timestamp
fi

# --------------
# LINUXBREW BASE
# --------------
export HOMEBREW_PREFIX=$hbdir
if [[ ! -d $HOMEBREW_PREFIX ]]; then
  git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX
  cd $HOMEBREW_PREFIX
  git reset --hard ff7c44bf5766b8ab02c7e67cce64a3fba8b2f316
fi

export HOMEBREW_LOGS=$HOMEBREW_PREFIX/_logs
export HOMEBREW_CACHE=$HOMEBREW_PREFIX/_cache
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"

if [ "$useMKL" = true ] ; then
  secho "Use MKL..."
  echo -e "Before proceeding, make sure \033[0;92mMKLROOT\033[0m is set."
  echo "Otherwise terminate the script (Ctrl+C), run equivalent of"
  echo -e "\033[1;37m . ~/intel/bin/compilervars.sh --arch intel64 -platform linux\033[0m"
  echo "and rerun the script again. Press any key when ready..."
  read
fi

if [ "$useMKL" = true ] ; then
  export HOMEBREW_BLASLAPACK_NAMES="mkl_gf_lp64;mkl_sequential;mkl_core"
  export HOMEBREW_BLASLAPACK_EXTRA="pthread;m;dl"
  export HOMEBREW_BLASLAPACK_LIB="${MKLROOT}/lib/intel64"
  export HOMEBREW_BLASLAPACK_INC="${MKLROOT}/include"
fi

# check if we have recent enough ruby, otherwise build ourselves
install_ruby=false
secho "Check ruby version..."
if builtin command -v ruby > /dev/null; then
  ruby_version="$(ruby -e 'print RUBY_VERSION')"
  # due to require_relative bug in 1.9.2. up the min version to
  ruby_min=2.0.0
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

brew install pkg-config && \
brew install openssl && brew postinstall openssl

if [ "$install_ruby" = true ]; then
  brew install ruby
fi


if [ "$useSystemLibs" = false ] ; then
  # brew install xz gcc # Fixes issues installing Trilinos with GCC 4.8.4 (Fortran verification failure) [Fortran in Trilinos currently disabled by default]
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

# temporary hack
export LD_LIBRARY_PATH="$HOMEBREW_PREFIX/lib:$LD_LIBRARY_PATH"

brew install boost --with-mpi --without-single && \
brew install hdf5 --with-mpi --c++11 && \
brew test hdf5 && \
brew install hypre && \
brew install metis && \
brew test metis && \
brew install parmetis && \
brew test parmetis
brew install superlu_dist && \
brew test superlu_dist && \
brew install scalapack && \
brew install mumps && \
brew test mumps && \
brew install petsc && \
brew test petsc && \
brew install arpack --with-mpi && \
brew test arpack && \
brew install slepc && \
brew test slepc && \
brew install p4est && \
brew install suite-sparse && \
HOMEBREW_MAKE_JOBS=1 brew install trilinos && \
brew test trilinos && \
brew install numdiff && \
brew install oce --without-x11 && \
brew test oce && \
brew install dealii --without-netcdf --without-tbb --without-muparser && \
brew test dealii


if [[ -e $bashfile ]]; then
  if [[ (( $addHBpaths == "y" )) || (( $addHBpaths == "Y" )) || (( $addHBpaths == "Yes" )) || (( $addHBpaths == "yes" )) ]]; then
    secho2 "Adding Homebrew paths to" "$bashfile"

    echo "" >> $bashfile
    echo "## === LINUXBREW ===" >> $bashfile
    echo "HOMEBREW_PREFIX=$hbdir" >> $bashfile
    echo "HOMEBREW_LOGS=\$HOMEBREW_PREFIX/_logs" >> $bashfile
    echo "HOMEBREW_CACHE=\$HOMEBREW_PREFIX/_cache" >> $bashfile
    echo "PATH=\"\$HOMEBREW_PREFIX/bin:\$PATH\"" >> $bashfile
    echo "MANPATH=\"\$HOMEBREW_PREFIX/share/man:\$MANPATH\"" >> $bashfile
    echo "INFOPATH=\"\$HOMEBREW_PREFIX/share/info:\$INFOPATH\"" >> $bashfile
    echo "DEAL_II_DIR=\$HOMEBREW_PREFIX" >> $bashfile
  else
    wecho ""
    echo "To use deal.II you must pass the following flag to CMake when configuring your problems:"
    echo -e "\033[1;37m-DDEAL_II_DIR=$HOMEBREW_PREFIX\033[0m"
  fi
else
  becho "Bash file does not exist. Could not add paths as requested."
fi
