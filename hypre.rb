require_relative "requirements/blas_requirement"

class Hypre < Formula
  desc "A library of high performance preconditioners that features parallel multigrid methods for both structured and unstructured grid problems"
  homepage "http://computation.llnl.gov/casc/hypre/software.html"
  url "http://ftp.mcs.anl.gov/pub/petsc/externalpackages/hypre-2.10.0b-p2.tar.gz"
  mirror "ftp://ftp.mirrorservice.org/sites/distfiles.gentoo.org/distfiles/hypre-2.10.0b-p2.tar.gz"
  sha256 "76414e693e5381e352e759c851c8cd5969dba7001b1dc153fe0f1ff60a5bb168"
  version "2.10.0b-p2"

  bottle do
    cellar :any_skip_relocation
    sha256 "8d99f0e0e1fa80601d5d3a7f793cc892eb2585ffe5f814130319f96c409f18c7" => :el_capitan
    sha256 "079c1cb42ba9a15b943d869f134145f997b3decc8df4735e82726eaf1507cc84" => :yosemite
    sha256 "ee7405e767f993c40db5a46009edf8351156707a2a2122de224ac684854224ad" => :mavericks
  end

  depends_on :fortran => :recommended
  depends_on :mpi => [:cc, :cxx, :f90, :f77, :recommended]
  depends_on BlasRequirement

  option "without-check", "Skip build-time tests (not recommended)"
  option "with-superlu", "Use internal SuperLU routines"
  option "with-fei", "Use internal FEI routines"
  option "with-mli", "Use internal MLI routines"
  option "without-accelerate", "Build without Accelerate framework (use internal BLAS routines)"
  option "with-debug", "Build with debug flags"
  option "with-bigint", "Build with 64-bit indices"

  def install
    cd "src" do
      config_args = ["--prefix=#{prefix}"]

      config_args << "--enable-debug" if build.with? "debug"

      blas_names = ENV["HOMEBREW_BLASLAPACK_NAMES"]
      blas_lib   = ENV["HOMEBREW_BLASLAPACK_LIB"]
      blas_names_split = blas_names.split(";").join(" ")
      config_args += ["--with-blas-libs=#{blas_names_split}",
                      "--with-blas-lib-dirs=#{blas_lib}",
                      "--with-lapack-libs=#{blas_names_split}",
                      "--with-lapack-lib-dirs=#{blas_lib}"]
      ENV.prepend "LDFLAGS", "-Wl,-rpath,#{blas_lib}" if blas_lib!=""

      config_args << "--disable-fortran" if build.without? :fortran
      config_args << "--without-superlu" if build.without? "superlu"
      config_args << "--without-fei" if build.without? "fei"
      config_args << "--without-mli" if build.without? "mli"

      # on Linux Homebrew formulae will fail to build
      # shared libraries without the dependent static libraries
      # compiled with -fPIC
      ENV.prepend "CFLAGS", "-fPIC"
      ENV.prepend "CXXFLAGS", "-fPIC"
      ENV.prepend "FFLAGS", "-fPIC"

      if build.with? :mpi
        ENV["CC"] = ENV["MPICC"]
        ENV["CXX"] = ENV["MPICXX"]
        ENV["F77"] = ENV["MPIF77"]
        ENV["FC"] = ENV["MPIFC"]
        config_args += ["--with-MPI",
                        "--with-MPI-include=#{HOMEBREW_PREFIX}/include",
                        "--with-MPI-lib-dirs=#{HOMEBREW_PREFIX}/lib",
                        # MPI library strings for linking depends on compilers
                        # enabled.  Only the C library strings are needed (without the
                        # lib), because hypre is a C library.
                        "--with-MPI-libs=mpi",
                       ]
      else
        config_args << "--without-MPI"
      end

      if build.with? "bigint"
        ENV.m64
        config_args << "--enable-bigint"
      end

      system "./configure", *config_args
      system "make", "all"
      system "make", "install"

      if build.with? "check"
        system "make", "check"
        system "make", "test"
        system "./test/ij"
        system "./test/struct"
        system "./test/sstruct", "-in", "test/sstruct.in.default", "-solver", "40", "-rhsone"

        cd "examples" do
          # The examples makefile does not use any of the variables from the
          # makefile in its parent directory. Examples that use the IJ
          # interface hang due to lack of LAPACK linkage, so a LAPACK
          # flag must be added; this method of doing so is the least
          # intrusive, and a patch is unlikely to be accepted upstream.
          # Overriding makefile variables at the command line is unworkable
          # here because the LFLAGS variable must be overridden, and LFLAGS
          # contains other makefile variable substitutions.
          lapack_flag = BlasRequirement.ldflags(ENV["HOMEBREW_BLASLAPACK_LIB"],ENV["HOMEBREW_BLASLAPACK_NAMES"],ENV["HOMEBREW_BLASLAPACK_EXTRA"])
          inreplace "Makefile", "-lstdc++", "-lstdc++ #{lapack_flag}"

          # Hack to excise Fortran examples from "make all"; they are still
          # in the "make fortran" target, thus making it easier to implement
          # conditional compilation and execution. Also won't be accepted
          # upstream.
          inreplace "Makefile", "ex5 ex5f", "ex5"
          inreplace "Makefile", "ex12 ex12f", "ex12"

          # Hack to excise FEI example from "make all"; to test, use
          # "make ex10" instead.
          inreplace "Makefile", "ex9 ex10", "ex9"

          # Now make all compiles all examples EXCEPT:
          # - Fortran examples (use "make fortran")
          # - 64-bit indexing examples (use "make 64bit")
          # - Babel examples (use "make babel", not implemented)
          # - FEI example (use "make ex10", requires Babel, not implemented)
          if build.without? "bigint"

            # For some reason, this Makefile doesn't include the settings of
            # the main Makefile.
            local_args = ["CC=#{ENV["MPICC"]}", "F77=#{ENV["MPIF77"]}", "CXX=#{ENV["MPICXX"]}", "F90=#{ENV["MPIFC"]}"]
            system "make", "all", *local_args

            # Example run commands taken from source file comments in headers
            system "mpiexec", "-np", "2", "./ex1"
            system "mpiexec", "-np", "2", "./ex2"
            system "mpiexec", "-np", "16", "./ex3", "-n", "33", "-solver", "-v", "1", "1"
            system "mpiexec", "-np", "16", "./ex4", "-n", "33", "-solver", "10", "-K", "3", "-B", "0", "-C", "1", "-U0", "2", "-F", "4"
            system "mpiexec", "-np", "4", "./ex5"
            system "mpiexec", "-np", "2", "./ex6"
            system "mpiexec", "-np", "16", "./ex7", "-n", "33", "-solver", "10", "-K", "3", "-B", "0", "-C", "1", "-U0", "2", "-F", "4"
            system "mpiexec", "-np", "2", "./ex8"
            system "mpiexec", "-np", "16", "./ex9", "-n", "33", "-solver", "0", "-v", "1", "1"
            system "mpiexec", "-np", "4", "./ex11"
            system "mpiexec", "-np", "2", "./ex12", "-pfmg"
            system "mpiexec", "-np", "2", "./ex12", "-boomeramg"
            system "mpiexec", "-np", "6", "./ex13", "-n", "10"
            system "mpiexec", "-np", "6", "./ex14", "-n", "10"
            system "mpiexec", "-np", "8", "./ex15", "-n", "10"

            if build.with? :fortran
              system "make", "fortran"

              system "mpiexec", "-np", "4", "./ex5f"
              system "mpiexec", "-np", "2", "./ex12f"
            end
          else
            system "make", "64bit"

            system "mpiexec", "-np", "4", "./ex5big"
            system "mpiexec", "-np", "8", "./ex15big", "-n", "10"
          end
        end if build.with? :mpi
      end
    end
  end

  def caveats; <<-EOS.undent
      Please register for hypre at:

      http://computation.llnl.gov/casc/hypre/download/hypre-2.10.0b_reg.html
    EOS
  end
end
