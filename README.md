# homebrew-dealIIsuite

### IMPORTANT NOTICE
```bash
This repository is no longer being maintained. 
The authors have switched to Spack https://github.com/LLNL/spack .
```

A collection of formulae needed to install `deal.II` on OS-X, as well as Linux
desktop machines and clusters.
For Linux users, provided below are instructions on how to install on:
* [A. Ubuntu 14.04 (desktop version)](#a-ubuntu-1404-desktop-version)
* [B. Mac OS-X](#b-mac-os-x)
* [C. CentOS cluster](#c-centos-cluster)

### Caveats
You cannot have homebrew-science tapped at the same as this repository.
Until [this PR](https://github.com/Homebrew/homebrew/pull/43535) is merged,
we have a conflict with homebrew-science.
If you encounter any conflicts due to duplicate formulae, then please
untap the problematic (other) repositories.
```bash
brew untap homebrew/science
```

There are several packages that cannot be installed on Linux at the moment.
When these issues are solved then this README will be updated to include the
most comprehensive set of build options for `deal.II` on Linux.

Known problem libraries include:
* `freeimage` does not build on Ubuntu, and therefore `opencascade`
cannot be built.
* `netcdf` requires manual intervention to be built. To install it, you must
use a along the lines of
```
LD_LIBRARY_PATH=~/.linuxbrew/Cellar/netcdf/4.3.3.1/lib brew install netcdf --with-fortran --with-cxx-compat
```
See [here](https://github.com/Homebrew/homebrew-science/issues/2521#issuecomment-122032005)
for a discussion.


# A. Ubuntu 14.04 desktop version
Note that you can choose to use either the BLAS/LAPACK libraries that are
provided by the system or install them through Linuxbrew with the `openblas`
package.

For the full list of instructions as to how to install Linuxbrew, please see
[this link](https://github.com/Homebrew/linuxbrew#installation).
The instructions given here are what we personally consider to be the least
invasive.

For your convenience, the instructions that follow in the next few sections have
been compiled into a script that can be extracted from the
`installation_scripts` directory inside this repository or [downloaded](https://raw.githubusercontent.com/davydden/homebrew-dealiisuite/master/installation_scripts/install_Ubuntu.sh), made executable through the command
```bash
chmod +x <path_to_script>/install_Ubuntu.sh
```
and run to install `deal.II` with minimal intervention.
However, you **use this script at your own risk**.
It will ask for the administrator password once up front in order to install
some essential build packages.
Of course, you can modify the script to set any personal preferences that you
may have with respect to the installed packages.

##  1. Install system packages
Firstly there are some mandatory packages that are required for the build
process
```bash
# Essential build packages
sudo apt-get install build-essential curl git m4 ruby texinfo libbz2-dev libcurl4-openssl-dev libexpat-dev libncurses-dev zlib1g-dev csh subversion
# Compilers
sudo apt-get install gcc g++ gfortran
```

### 1.1. Install optional system packages
Optional `MPI` packages:
```bash
# Use system MPI
sudo apt-get install mpi-default-bin libopenmpi-dev
```

Optional `cmake` package:
```bash
# System CMake
sudo apt-get install cmake
```

Optional `BLAS/LAPACK` packages:
```bash
# Extra packages for system blas/lapack
sudo apt-get install libblas-dev liblapack-dev
```

## 2. Get and configure Linuxbrew

### 2.1. Put to your .bash_profile or .bashrc
These (or comparable) lines must be put into `.bash_profile` or `.bashrc` to set
the  installation path for Linuxbrew as well as certain environment variables.
```bash
# Linuxbrew
export HOMEBREW_PREFIX=~/.linuxbrew
export HOMEBREW_LOGS=~/Logs/linuxbrew
export HOMEBREW_CACHE=~/Cache/linuxbrew
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"
```
You can also enable bash auto-completion if you install the `bash-completion`
package.
```bash
## If possible, enable bash completion
if [ -f $HOMEBREW_PREFIX/etc/bash_completion ]; then
    . $HOMEBREW_PREFIX/etc/bash_completion
fi
```
The following lines are optional (dependent on whether you'll be using some
system-provided `BLAS/LAPACK` that is NOT in the system path).
To give some idea as to how one would set this up, here is the equivalent for
using the Ubuntu-provided libraries (which would be redundant to add since
Linuxbrew will pick these ones up automatically.)
```bash
## Optional [for when using system BLAS/LAPACK]
export HOMEBREW_BLASLAPACK_NAMES="blas;lapack"
export HOMEBREW_BLASLAPACK_LIB="/usr/lib"
export HOMEBREW_BLASLAPACK_INC="/usr/include"
```
That is to say that if you want to use `BLAS/LAPACK` from Ubuntu, it should be
enough just to ignore setting `HOMEBREW_BLASLAPACK_XXX`.
In order to use `openblas`, install it first (`brew install openblas`) and then
it will be used automatically.
In order to use another library (such as Intel MKL), you need to fill out the
above settings accordingly.

### 2.2 Install Linuxbrew and basic packages
Now that the environmental variables have been set we can install Linuxbrew
itself.
```bash
git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX
```

You may wish to install bash-completion to assist you with filling out Linuxbrew
commands if you do any customisation of the commands listed hereafter.
```bash
brew install bash-completion
```

Before we can install the `deal.II` packages, Linuxbrew needs some basic
packages
```bash
brew install pkg-config
brew install openssl && brew postinstall openssl
```

A more recent version of `ruby` (circa 2.2) is needed for the formulae in this
repository.
For Ubuntu 14.04, we need to update it.
```bash
brew install ruby
```

Should you not have installed the system `cmake` then you should install it now.
```bash
brew install cmake --without-docs
```

Should you wish to make use of `openmpi` instead of the system libraries, then
we need to first install a Java runtime environment as well
```bash
# Install the Java runtime environment
sudo apt-get install default-jre
# Install OpenMPI
brew install openmpi --c++11
```

## 3. Get this collection of formulae and install the deal.II suite
Firstly we need to tap the various repositories from which to fetch the packages
and build information.
```bash
# Tap this repository
brew tap davydden/dealiisuite
```

Now you might optionally install `openblas` (should you not wish to use the
  system-provided `BLAS/LAPACK`)
```bash
brew install openblas
```

The optional `boost` libraries can be configured with `C++11` support if you
have installed, or are willing to install, `openmpi`.
```bash
# Boost configuration if OpenMPI has been installed
brew install boost --with-mpi --c++11 --without-single
```
Otherwise this should not be selected (as `openmpi` is currently a dependency)
```bash
# Boost configuration if OpenMPI installation is not desired
brew install boost --with-mpi --without-single
```
Now we can install all of the other (optional) dependencies of `deal.II`
```bash
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
```

Installing `trilinos` is very resource intensive (it consumes a lot of memory
  when linking, especially with `GCC`).
It may be useful to limit the number of make jobs to lighten the memory load, at
the expense of build time.
```bash
HOMEBREW_MAKE_JOBS=2 brew install trilinos
```

Finally you can build the latest stable release of build `deal.II`
```bash
# Latest stable release
brew install dealii
```
or the developer version (which may be necessary at this moment due to a bug in
  the configure script for `deal.II` 8.3.0)
```bash
# Developer version
brew install dealii --HEAD
```

# B. Mac OS-X
Note that you can choose to use either the BLAS/LAPACK libraries that are
provided by the system (`veclibfort`) or install them through Homebrew with the
`openblas` package.

For the full list of instructions as to how to install Homebrew, please see
[this link](https://github.com/Homebrew/homebrew/blob/master/share/doc/homebrew/Installation.md).
The instructions given here are what we personally consider to be the least
invasive.

##  1. Install external software
Mandatory software which installs `clang`, the C++ compiler
```
xcode-select --install
```
You then "need" to accept the `xcode` licence
```bash
xcodebuild -license
```

## 2. Get and configure Homebrew

### 2.1. Put to your .bash_profile or .bashrc
These (or comparable) lines must be put into `.bash_profile` or `.bashrc` to set
the  installation path for Homebrew as well as certain environment variables.
```bash
# Homebrew
export HOMEBREW_PREFIX=~/.homebrew
export PATH="$HOMEBREW_PREFIX/bin:$PATH"
export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
export INFOPATH="$HOMEBREW_PREFIX/share/info:$INFOPATH"

## Enable bash completion
if [ -f $HOMEBREW_PREFIX/etc/bash_completion ]; then
    . $HOMEBREW_PREFIX/etc/bash_completion
fi
```

### 2.2 Install Homebrew and basic packages
Now that the environmental variables have been set we can install Homebrew
itself.
```bash
git clone https://github.com/Homebrew/homebrew.git $HOMEBREW_PREFIX
```

You may wish to install bash-completion to assist you with filling out Homebrew
commands if you do any customisation of the commands listed hereafter.
```bash
brew install bash-completion
```

Before we can install the `deal.II` packages, Homebrew needs some basic packages
```bash
brew install openssl && brew postinstall openssl
brew install cmake
brew install openmpi --c++11
```

## 4. Get a collection of formulae and install the deal.II suite
Note that for OS-X the homebrew-science repository has a fully functional
set of formulae that work both with the system BLAS/LAPACK libraries as well
as OpenBLAS.
There are an additional set of dependencies that `deal.II` can be safely be
built against.
So we can happily use it as a repository instead of this one and therefore
recommend it
```bash
# Untap this repository to prevent conflicting packages
brew untap davydden/dealiisuite
# Tap the more complete Homebrew-Science repository
brew tap homebrew/science
```

#### 4.1. With system BLAS/LAPACK
```bash
brew install boost --with-mpi --c++11
brew install gsl
brew install scalapack
brew install mumps
brew install metis
brew install parmetis
brew install hypre --with-mpi
brew install superlu43
brew install superlu_dist
brew install arpack --with-mpi --without-check
brew install hdf5 --with-mpi --c++11
brew install netcdf --with-fortran --with-cxx-compat
brew install suite-sparse
brew install hwloc
brew install sundials --with-mpi
brew install fftw --with-mpi --with-fortran
brew install petsc
brew install slepc
brew install p4est
brew install adol-c
brew install cppunit
brew install doxygen --with-graphviz
brew install glpk
brew install glm
brew install trilinos
brew install dealii
```

#### 4.2. With OpenBLAS
```bash
brew install boost --with-mpi --c++11
brew install gsl
brew install openblas
brew install scalapack --with-openblas
brew install mumps --with-openblas
brew install metis
brew install parmetis
brew install hypre --with-mpi --with-openblas
brew install superlu43 --with-openblas
brew install superlu_dist --with-openblas
brew install arpack --with-mpi --with-openblas --without-check
brew install hdf5 --with-mpi --c++11
brew install netcdf --with-fortran --with-cxx-compat
brew install suite-sparse --with-openblas
brew install hwloc
brew install sundials --with-mpi
brew install fftw --with-mpi --with-fortran
brew install petsc --with-openblas
brew install slepc --with-openblas
brew install p4est --with-openblas
brew install adol-c
brew install cppunit
brew install doxygen --with-graphviz
brew install glpk
brew install glm
brew install trilinos --with-openblas
brew install dealii --with-openblas
```

# C. CentOS cluster

For your convenience, the instructions that follow in the next few sections have
been compiled into a script that can be extracted from the
`installation_scripts` directory inside this repository or [downloaded](https://raw.githubusercontent.com/davydden/homebrew-dealiisuite/master/installation_scripts/install_CentOS.sh), made executable through the command
```bash
chmod +x <path_to_script>/install_CentOS.sh
```
and run to install `deal.II` with minimal intervention.
However, you **use this script at your own risk**.
Of course, you can modify the script to set any personal preferences that you
may have with respect to the installed packages.

Below is the detailed instruction to make it work with CentOS cluster and native
`openmpi`, `gcc`, `cmake`, `git`, `MKL`.

## 1. Put to your .bash_profile
```bash
# CentOS related:
module load gcc
module load openmpi/1.8.3-gcc
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

## 2. Get and configure Linuxbrew
```bash
git clone https://github.com/Homebrew/linuxbrew.git $HOMEBREW_PREFIX
```

Linuxbrew needs `ruby`. If you do not have one on the front-end or it's too old,
compile it yourself:
```bash
wget https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz
tar xvzf ruby-2.2.3.tar.gz ruby-2.2.3
cd ruby-2.2.3
./configure --prefix=$HOMEBREW_PREFIX
make
make install
```

Make simlinks for GCC to make sure Linuxbrew picks it up
```bash
ln -s `which gcc` $HOMEBREW_PREFIX/bin/gcc-`gcc -dumpversion |cut -d. -f1,2`
ln -s `which g++` $HOMEBREW_PREFIX/bin/g++-`g++ -dumpversion |cut -d. -f1,2`
ln -s `which gfortran` $HOMEBREW_PREFIX/bin/gfortran-`gfortran -dumpversion |cut -d. -f1,2`
```

Finally, Linuxbrew needs `openssl`
```bash
brew install openssl && brew postinstall openssl
```

## 3. Get this collection of formulae and install the deal.II suite
```bash
brew tap davydden/dealiisuite

brew install boost --with-mpi --without-single
brew install hdf5 --with-mpi --c++11 --without-cxx
brew install hypre --with-mpi --without-check
brew install metis
brew install parmetis
brew install superlu_dist
brew install scalapack --without-check
brew install mumps
brew install petsc --without-check
brew install slepc --without-check --without-arpack
brew install p4est --without-check
brew install trilinos
brew install numdiff
brew install oce
brew install dealii --without-arpack --HEAD
```
