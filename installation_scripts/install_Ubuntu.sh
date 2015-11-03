#!/bin/bash

# -----------------------------------------------------------------
# DISCLAIMER
# Adapted from http://michal.kosmulski.org/computing/shell-scripts/
# -----------------------------------------------------------------
# This script come without warranty of any kind. 
# You use it at your own risk. 
# We assume no liability for the accuracy, correctness, completeness, or usefulness of this script, nor for any sort of damages that using it may cause.

# ------------------------
# GENERIC WITH SYSTEM BLAS
# ------------------------
echo "You are about to be asked for your password so that essential system libraries can be installed."
sudo apt-get install \
build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion \
gcc g++ gfortran \
mpi-default-bin libopenmpi-dev \
cmake \
libblas-dev liblapack-dev
sudo -k # Safety first: Invalidate user timestep

# --------------
# LINUXBREW BASE
# --------------
export HOMEBREW_PREFIX=~/.linuxbrew
git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX

export HOMEBREW_LOGS=~/Logs/linuxbrew
export HOMEBREW_CACHE=~/Cache/linuxbrew
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"

brew install pkg-config && \
brew install openssl && brew postinstall openssl && \
brew install ruby

# -------------
# DEAL.II SUITE
# -------------
brew tap davydden/dealiisuite

brew install boost --with-mpi --without-single && \
brew install hdf5 --with-mpi --c++11 && \
brew install hypre --with-mpi --without-check && \
brew install metis && \
brew install parmetis && \
brew install superlu_dist && \
brew install scalapack --without-check && \
brew install mumps && \
brew install petsc --without-check && \
brew install arpack --with-mpi && \
brew install slepc --without-check && \
brew install p4est --without-check && \
HOMEBREW_MAKE_JOBS=1 brew install trilinos && \
brew install dealii --HEAD # Build problem related to C++11 detected by Trilinos and not deal.II 8.3.0

