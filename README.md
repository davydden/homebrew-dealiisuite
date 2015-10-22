# homebrew-dealIIsuite
A collection of formulae needed to install deal.II on OS-X / Linux clusters.

# Detailed usage instructions

Below is the detailed instruction to make it work with CentOS cluster and native `openmpi`, `gcc`, `cmake`, `git`, `MKL`. 

## 1. Put to your .bash_profile
```
# CentOS related:
module load gcc
module load openmpi/1.7.2-gcc
module load mkl
module load cmake
module load git/2.2.1

# Linuxbrew
export HOMEBREW_BUILD_FROM_SOURCE=1
export HOMEBREW_PREFIX=$WOODYHOME/.linuxbrew
export HOMEBREW_LOGS=$WOODYHOME/Logs/HOMEBREW
export HOMEBREW_CACHE=$WOODYHOME/Cache/HOMEBREW
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"

# BLAS-LAPACK
export HOMEBREW_BLASLAPACK_NAMES="mkl_intel_lp64;mkl_sequential;mkl_core"
export HOMEBREW_BLASLAPACK_LIB="${MKLROOT}/lib/intel64"
export HOMEBREW_BLASLAPACK_INC="${MKLROOT}/include"

# compilers
export CC=mpicc
export CXX=mpicxx
export FC=mpif90
export FF=mpif77
```
If you want to use blas/lapack from Ubuntu, it should be enough just to ignore setting `HOMEBREW_BLASLAPACK_XXX`. 
In order to use `openblas`, install it first (`brew install openblas`) and then it will be used automatically.


## 2. Get and configure linuxbrew
```
git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX
```

Linuxbrew needs ruby. If you do not have one on the front-end or it's too old, compile it yourself:
```
wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz
tar xvzf ruby-2.2.3.tar.gz ruby-2.2.3
cd ruby-2.2.3
./configure --prefix=$HOMEBREW_PREFIX
make
make install
```

Make simlinks for GCC to make sure linuxbrew picks it up
```
ln -s `which gcc` $HOMEBREW_PREFIX/bin/gcc-`gcc -dumpversion |cut -d. -f1,2`
ln -s `which g++` $HOMEBREW_PREFIX/bin/g++-`g++ -dumpversion |cut -d. -f1,2`
ln -s `which gfortran` $HOMEBREW_PREFIX/bin/gfortran-`gfortran -dumpversion |cut -d. -f1,2`
```

Finally, linuxbrew needs openssl
```
brew install openssl
brew postinstall openssl
```

## 3. Get this collection of formulae and install deal.II suite
```
brew tap davydden/dealiisuite

# untill this PR https://github.com/Homebrew/homebrew/pull/43535 is merged,
# we have a conflict with homebrew-science
brew untap homebrew/science

brew install hdf5 --with-mpi --c++11
brew install hypre --with-mpi --without-check
brew install metis
brew install parmetis
brew install superlu_dist
brew install scalapack --without-check
brew install mumps
brew install petsc --without-check
brew install arpack --with-mpi
brew install slepc --without-check
brew install p4est --without-check
brew install trilinos
brew install dealii --HEAD
```