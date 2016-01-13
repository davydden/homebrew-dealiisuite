#!/bin/bash

# -----------------------------------------------------------------
# DISCLAIMER
# Adapted from http://michal.kosmulski.org/computing/shell-scripts/
# -----------------------------------------------------------------
# This script come without warranty of any kind. 
# You use it at your own risk. 
# We assume no liability for the accuracy, correctness, completeness, or usefulness of this script, nor for any sort of damages that using it may cause.

# --------
# SETTINGS
# --------

hbdir=~/.linuxbrew
bashfile=~/.bashrc
useSystemLibs=true

echo ""
if [ $# -eq 0 ]; then
  echo "Using default installation and file paths."
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
    *)
      echo "Unknown option. Exiting..."
      exit 1
    ;;
  esac

  shift # past argument or value
done

if [ "$useSystemLibs" = true ] ; then
  echo "Using system libraries (GCC, MPI, CMake, BLAS/LAPACK)."
else
  echo "Will install all base libraries through Linuxbrew."
fi

echo ""
echo "Linuxbrew installation path: $hbdir"
echo "Bash file: $bashfile"

# -------------------------
# REQUIRES USER INTERACTION
# -------------------------

echo ""
echo "Do you want to add Homebrew/Linuxbrew and deal.II paths"
echo "to $bashfile? [Y/n]:"
read addHBpaths

echo "You are about to be asked for your password so that "
echo "essential system libraries can be installed."
echo "After this, the rest of the build should be automatic."

# -----------------------------
# PREREQUISITE SYSTEM LIBRARIES
# -----------------------------
if [ "$useSystemLibs" = true ] ; then
  sudo apt-get install \
  build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion \
  gcc g++ gfortran \
  mpi-default-bin libopenmpi-dev \
  cmake \
  libblas-dev liblapack-dev
else
  sudo apt-get install \
  build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion \
  gcc g++ gfortran \
  default-jre
fi
sudo -k # Safety first: Invalidate user timestamp

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

brew install pkg-config && \
brew install openssl && brew postinstall openssl && \
brew install ruby

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

brew install boost --with-mpi --without-single && \
brew install hdf5 --with-mpi --c++11 && \
brew install hypre --with-mpi --without-check && \
brew install metis && \
brew install parmetis && \
brew install superlu_dist && \
brew install scalapack --without-check && \
brew install mumps && \
brew install petsc && \
brew test petsc && \
brew install arpack --with-mpi && \
brew install slepc && \
brew test slepc && \
brew install p4est --without-check && \
HOMEBREW_MAKE_JOBS=1 brew install trilinos --without-fortran && \
brew install numdiff && \
brew install oce && \
brew install dealii --HEAD && \
brew test dealii

# Note: install HEAD version of dealii as build problem related to C++11 detected by Trilinos and not deal.II 8.3.0

if [[ -e $bashfile ]]; then
  if [[ (( $addHBpaths == "y" )) || (( $addHBpaths == "Y" )) || (( $addHBpaths == "Yes" )) || (( $addHBpaths == "yes" )) ]]; then
    echo "Adding Homebrew paths to $bashfile"

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
    echo "To use deal.II you must pass the following flag to CMake"
    echo "when configuring your problems:"
    echo "-DDEAL_II_DIR=$HOMEBREW_PREFIX"
  fi
else
  echo "Error: Bash file does not exist. Could not add paths"
  echo "as requested."
fi
