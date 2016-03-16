require_relative "requirements/blas_requirement"
require_relative "requirements/cmake_requirement"

class Trilinos < Formula
  desc "Algorithms for the solution of large-scale, complex multi-physics engineering and scientific problems"
  homepage "http://trilinos.sandia.gov"
  url "https://github.com/trilinos/Trilinos/archive/trilinos-release-12-6-1.tar.gz"
  sha256 "176fd6e778aa86d13405bd6663d61cc11e6f69c01be7e4bd5a7a6d8243c55b63"
  head "https://software.sandia.gov/trilinos/repositories/publicTrilinos", :using => :git
  revision 1

  bottle do
    sha256 "e317149a9d2e66e80d1dea72e85163d6100e5d50f98e24440b0980bed8df677a" => :el_capitan
    sha256 "1156e876092f7f21c20594b484b7cb668811dc1a2b57542447462ef15f076358" => :yosemite
    sha256 "070c7d52fbbe501d7cfbdbae6b3a68d3b01bc242a45dde462b00aa577e3981a9" => :mavericks
  end

  option "with-check", "Perform build time checks (time consuming and contains failures)"

  # options and dependencies not supported in the current version
  # are commented out with #- and failure reasons are documented.

  #-option "with-csparse", "Build with CSparse (Experimental TPL) from suite-sparse" # Undefined symbols for architecture x86_64: "Amesos_CSparse::Amesos_CSparse(Epetra_LinearProblem const&)"

  depends_on :mpi           => [:cc, :cxx, :recommended]
  depends_on :fortran       => :recommended
  #-depends_on :x11           => :recommended

  #-depends_on :python        => :recommended
  depends_on "homebrew/python/numpy"  if build.with? "python"
  depends_on "swig"         => :build if build.with? "python"

  depends_on CmakeRequirement => "2.8"
  depends_on "pkg-config"   => :build

  depends_on BlasRequirement

  mpidep      = (build.with? "mpi")      ? ["with-mpi"]      : []

  #-depends_on "adol-c"       => :recommended
  depends_on "boost"        => :recommended
  #-depends_on "cppunit"      => :recommended
  #-depends_on "doxygen"      => ["with-graphviz", :recommended]
  #-depends_on "hwloc"        => :recommended
  #-depends_on "libmatio"     => [:recommended] + ((build.with? "hdf5") ? ["with-hdf5"] : [])
  depends_on "metis"        => :recommended
  depends_on "mumps"        => :recommended
  #-depends_on "netcdf"       => ["with-fortran", :recommended]
  depends_on "parmetis"     => :recommended if build.with? "mpi"
  depends_on "scalapack"    => :recommended
  #-depends_on "scotch"       => :recommended
  depends_on "suite-sparse" => :recommended
  #-depends_on "superlu"      => :recommended // Amesos2_Superlu_FunctionMap.hpp:83:14: error: no type named 'superlu_options_t' in namespace 'SLU'
  depends_on "superlu_dist" => [:recommended] if build.with? "parmetis"

  #-depends_on "petsc"        => :optional # ML packages currently do not compile with PETSc >= 3.3
  #-depends_on "qd"           => :optional # Fails due to global namespace issues (std::pow vs qd::pow)
  #-depends_on "binutils"     => :optional # libiberty is deliberately omitted in Homebrew (see PR #35881)

  # Experimental TPLs:
  #-depends_on "eigen"        => :recommended
  depends_on "hypre"        => [:recommended] + ((build.with? "mpi") ? [] : ["without-mpi"]) # EpetraExt tests fail to compile
  #-depends_on "glpk"         => :recommended
  depends_on "hdf5"         => [:recommended] + mpidep
  #-depends_on "tbb"          => :recommended # do NOT use as PETSc is not thread-safe anyway!
  #-depends_on "glm"          => :recommended
  #-depends_on "yaml-cpp"     => :recommended

  #-depends_on "lemon"        => :optional # lemon is currently built as executable only, no libraries
  #-depends_on "cask"         => :optional # cask  is currently built as executable only, no libraries

  # Missing TPLS:
  # BLACS, Y12M, XDMF, tvmet, thrust, taucs, SPARSEKIT, qpOASES, Portals,
  # Pnetcdf, Peano, PaToH, PAPI, Pablo, Oski, OVIS, OpenNURBS, Nemesis, MF,
  # MA28, LibTopoMap, InfiniBand, HPCToolkit, HIPS, gtest, gpcd, Gemini,
  # ForUQTK, ExodusII, CUSPARSE, Cusp, CrayPortals, Coupler, Clp, CCOLAMD,
  # BGQPAMI, BGPDCMF, ARPREC, ADIC

  def onoff(s, cond)
    s + ((cond) ? "ON" : "OFF")
  end

  # Patch FindTPLUMFPACK to work with UMFPACK>=5.6.0
  patch :DATA

  # Kokkos, Tpetra and Sacado will be OFF without cxx11
  needs :cxx11
  def install
    ENV.cxx11
    # Trilinos supports only Debug or Release CMAKE_BUILD_TYPE!
    args  = %W[-DCMAKE_INSTALL_PREFIX=#{prefix} -DCMAKE_BUILD_TYPE=Release]
    args += %w[-DBUILD_SHARED_LIBS=ON
               -DTPL_ENABLE_BLAS=ON
               -DTPL_ENABLE_LAPACK=ON
               -DTPL_ENABLE_Zlib:BOOL=ON
               -DTrilinos_ENABLE_ALL_PACKAGES=ON
               -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=ON
               -DTrilinos_ENABLE_EXAMPLES:BOOL=ON
               -DTrilinos_VERBOSE_CONFIGURE:BOOL=OFF
               -DTrilinos_WARNINGS_AS_ERRORS_FLAGS=""]

    # Explicit instantiation will build object files for the Trilinos templated classes with the most common types.
    # That should speed up compilation time for librareis/driver programs which use Trilinos.
    # see https://trilinos.org/pipermail/trilinos-users/2015-September/005146.html
    args << "-DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON"

    # enable tests only when we inted to run checks.
    # that reduced the build time from 130 min to 51 min.
    args << onoff("-DTrilinos_ENABLE_TESTS:BOOL=",  (build.with? "check"))
    # some tests are needed to have binaries in the "test do" block:
    # args << "-DEpetra_ENABLE_TESTS=ON"
    args << "-DTrilinos_ENABLE_EXAMPLES:BOOL=OFF" # fix MKL linking errors

    # constrain Cmake to look for libraries in homebrew's prefix
    args << "-DCMAKE_PREFIX_PATH=#{HOMEBREW_PREFIX}"

    # on Linux Trilinos might pick up wrong MPI.
    # Can't specify "open-mpi" location as other (mpich)
    # implementations may be used.
    args << "-DMPI_BASE_DIR:PATH=#{HOMEBREW_PREFIX}" if build.with? "mpi"

    # BLAS / LAPACK support
    blas_names = ENV["HOMEBREW_BLASLAPACK_NAMES"]
    blas_lib   = ENV["HOMEBREW_BLASLAPACK_LIB"]
    blas_inc   = ENV["HOMEBREW_BLASLAPACK_INC"]
    args << "-DBLAS_LIBRARY_NAMES=#{blas_names}"
    args << "-DBLAS_LIBRARY_DIRS=#{blas_lib}"
    args << "-DLAPACK_LIBRARY_NAMES=#{blas_names}"
    args << "-DLAPACK_LIBRARY_DIRS=#{blas_lib}"
    ENV.prepend "LDFLAGS", "-Wl,-rpath,#{blas_lib}" if blas_lib != ""

    # TODO: check that it's MKL
    args << "-DTPL_ENABLE_MKL:BOOL=ON"
    args << "-DMKL_LIBRARY_DIRS:FILEPATH=#{blas_lib}"
    args << "-DMKL_LIBRARY_NAMES=#{blas_names}"
    args << "-DMKL_INCLUDE_DIRS=#{blas_inc}"

    args << "-DTrilinos_ASSERT_MISSING_PACKAGES=OFF" if build.head?

    args << onoff("-DTPL_ENABLE_MPI:BOOL=",         (build.with? "mpi"))
    # TODO:
    # OpenMP leads deal.II to fail with compiler errors in trilinos headers even though trilinos compiles fine
    # It could be that there is a missing #include somewhere in Trilinos which becames visible when we
    # try to use it.
    # For now disable OpenMP:
    args << "-DTrilinos_ENABLE_OpenMP:BOOL=OFF"
    args << "-DTrilinos_ENABLE_CXX11:BOOL=ON"

    # Extra non-default packages
    args << "-DTrilinos_ENABLE_ShyLU:BOOL=ON"
    args << "-DTrilinos_ENABLE_Teko:BOOL=ON"

    # Temporary disable due to compiler errors:
    # packages:
    args << "-DTrilinos_ENABLE_FEI=OFF"
    args << "-DTrilinos_ENABLE_Pike=OFF" # 12.4.2
    args << "-DTrilinos_ENABLE_Piro=OFF"
    args << "-DTrilinos_ENABLE_SEACAS=OFF"
    args << "-DTrilinos_ENABLE_STK=OFF"
    args << "-DTrilinos_ENABLE_Stokhos=OFF"
    args << "-DTrilinos_ENABLE_Sundance=OFF" if !OS.mac? || MacOS.version < :mavericks
    args << "-DTrilinos_ENABLE_Zoltan2=OFF" # 12.4.2
    args << "-DTrilinos_ENABLE_Amesos2=OFF" # compiler error with explicit instantiation
    # Amesos, conflicting types of double and complex SLU_D
    # see https://trilinos.org/pipermail/trilinos-users/2015-March/004731.html
    # and https://trilinos.org/pipermail/trilinos-users/2015-March/004802.html
    if build.with? "superlu_dist"
      args << "-DTeuchos_ENABLE_COMPLEX:BOOL=OFF"
      args << "-DKokkosTSQR_ENABLE_Complex:BOOL=OFF"
    end
    # tests:
    args << "-DIntrepid_ENABLE_TESTS=OFF"
    args << "-DSacado_ENABLE_TESTS=OFF"
    args << "-DEpetraExt_ENABLE_TESTS=OFF" if build.with? "hypre"
    args << "-DMesquite_ENABLE_TESTS=OFF"
    args << "-DIfpack2_ENABLE_TESTS=OFF"

    # Third-party libraries
    args << onoff("-DTPL_ENABLE_Boost:BOOL=",       (build.with? "boost"))
    args << onoff("-DTPL_ENABLE_Scotch:BOOL=",      (build.with? "scotch"))
    args << onoff("-DTPL_ENABLE_Netcdf:BOOL=",      (build.with? "netcdf"))
    args << onoff("-DTPL_ENABLE_ADOLC:BOOL=",       (build.with? "adol-c"))
    args << onoff("-DTPL_ENABLE_AMD:BOOL=",         (build.with? "suite-sparse"))
    args << onoff("-DTPL_ENABLE_Matio:BOOL=",       (build.with? "libmatio"))
    args << onoff("-DTPL_ENABLE_yaml-cpp:BOOL=",    (build.with? "yaml-cpp"))

    # if (build.with? "suite-sparse") && (build.with? "csparse")
    #   args << "-DTPL_ENABLE_CSparse:BOOL=ON"
    #   args << "-DCSparse_LIBRARY_NAMES=cxsparse;amd;colamd;suitesparseconfig"
    # else
    args << "-DTPL_ENABLE_CSparse:BOOL=OFF"
    # end
    args << onoff("-DTPL_ENABLE_Cholmod:BOOL=",     (build.with? "suite-sparse"))

    args << onoff("-DTPL_ENABLE_UMFPACK:BOOL=",     (build.with? "suite-sparse"))
    args << "-DUMFPACK_LIBRARY_NAMES=umfpack;amd;colamd;cholmod;suitesparseconfig" if build.with? "suite-sparse"

    args << onoff("-DTPL_ENABLE_CppUnit:BOOL=",     (build.with? "cppunit"))
    args << "-DCppUnit_LIBRARY_DIRS=#{Formula["cppunit"].opt_lib}" if build.with? "cppunit"

    args << onoff("-DTPL_ENABLE_Eigen:BOOL=",       (build.with? "eigen"))
    args << "-DEigen_INCLUDE_DIRS=#{Formula["eigen"].opt_include}/eigen3" if build.with? "eigen"

    args << onoff("-DTPL_ENABLE_GLPK:BOOL=",        (build.with? "glpk"))
    args << onoff("-DTPL_ENABLE_HWLOC:BOOL=",       (build.with? "hwloc"))
    args << onoff("-DTPL_ENABLE_HYPRE:BOOL=",       (build.with? "hypre"))

    # Even though METIS seems to conflicts with ParMETIS in Trilinos config (see TPLsList.cmake in the source folder),
    # we still need to provide METIS_INCLUDE_DIRS so that metis.h is picked up on Linuxbrew.
    if build.with? "metis"
      args << "-DTPL_ENABLE_METIS:BOOL=ON"
      args << "-DMETIS_LIBRARY_DIRS=#{Formula["metis"].opt_lib}"
      args << "-DMETIS_LIBRARY_NAMES=metis"
      args << "-DTPL_METIS_INCLUDE_DIRS=#{Formula["metis"].opt_include}"
    else
      args << "-DTPL_ENABLE_METIS:BOOL=OFF"
    end

    # A hack for mumps 5.0
    # TODO: use extra LIBRARY_NAMES with 5.0 only?
    if build.with? "mumps"
      args << "-DTPL_ENABLE_MUMPS:BOOL=ON"
      args << "-DMUMPS_LIBRARY_DIRS=#{Formula["mumps"].opt_lib}"
      args << "-DMUMPS_LIBRARY_NAMES=dmumps;mumps_common;pord"
    end

    args << onoff("-DTPL_ENABLE_PETSC:BOOL=", false) #       (build.with? "petsc"))
    args << onoff("-DTPL_ENABLE_HDF5:BOOL=",        (build.with? "hdf5"))

    if build.with? "parmetis"
      # Ensure CMake picks up METIS 5 and not METIS 4.
      args << "-DTPL_ENABLE_ParMETIS:BOOL=ON"
      args << "-DParMETIS_LIBRARY_DIRS=#{Formula["parmetis"].opt_lib};#{Formula["metis"].opt_lib}"
      args << "-DParMETIS_LIBRARY_NAMES=parmetis;metis"
      args << "-DTPL_ParMETIS_INCLUDE_DIRS=#{Formula["parmetis"].opt_include}"
    else
      args << "-DTPL_ENABLE_ParMETIS:BOOL=OFF"
    end

    args << onoff("-DTPL_ENABLE_SCALAPACK:BOOL=",   (build.with? "scalapack"))

    args << onoff("-DTPL_ENABLE_SuperLU:BOOL=", false) #   (build.with? "superlu"))
    # args << "-DSuperLU_INCLUDE_DIRS=#{Formula["superlu"].opt_include}/superlu" if build.with? "superlu"

    # fix for 4.0:
    args << "-DHAVE_SUPERLUDIST_LUSTRUCTINIT_2ARG:BOOL=ON" if build.with? "superlu_dist"
    args << onoff("-DTPL_ENABLE_SuperLUDist:BOOL=", (build.with? "superlu_dist"))
    args << "-DSuperLUDist_INCLUDE_DIRS=#{Formula["superlu_dist"].opt_include}/superlu_dist" if build.with? "superlu_dist"

    args << onoff("-DTPL_ENABLE_QD:BOOL=", false) #        (build.with? "qd"))
    args << onoff("-DTPL_ENABLE_Lemon:BOOL=", false) #     (build.with? "lemon"))
    args << onoff("-DTPL_ENABLE_GLM:BOOL=",        (build.with? "glm"))
    args << onoff("-DTPL_ENABLE_CASK:BOOL=", false) #      (build.with? "cask"))
    args << onoff("-DTPL_ENABLE_BinUtils:BOOL=", false) #  (build.with? "binutils"))

    args << onoff("-DTPL_ENABLE_TBB:BOOL=",         (build.with? "tbb"))
    args << onoff("-DTPL_ENABLE_X11:BOOL=",         (build.with? "x11"))

    args << onoff("-DTrilinos_ENABLE_Fortran=",     (build.with? "fortran"))
    #if build.with? "fortran"
    #  libgfortran = `$FC --print-file-name libgfortran.a`.chomp
    #  ENV.append "LDFLAGS", "-L#{File.dirname libgfortran} -lgfortran"
    #end

    args << onoff("-DTrilinos_ENABLE_PyTrilinos:BOOL=", (build.with? "python"))
    args << "-DPyTrilinos_INSTALL_PREFIX:PATH=#{prefix}" if build.with? "python"

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "VERBOSE=1"
      system ("ctest -j" + Hardware::CPU.cores) if build.with? "check"
      system "make", "install"
      # When trilinos is built with Python, libpytrilinos is included through
      # cmake configure files. Namely, Trilinos_LIBRARIES in TrilinosConfig.cmake
      # contains pytrilinos. This leads to a run-time error:
      # Symbol not found: _PyBool_Type
      # and prevents Trilinos to be used in any C++ code, which links executable
      # against the libraries listed in Trilinos_LIBRARIES.
      # See https://github.com/Homebrew/homebrew-science/issues/2148#issuecomment-103614509
      # A workaround it to remove PyTrilinos from the COMPONENTS_LIST :
      if build.with? "python"
        inreplace "#{lib}/cmake/Trilinos/TrilinosConfig.cmake" do |s|
          s.gsub! "PyTrilinos;", "" if s.include? "COMPONENTS_LIST"
        end
      end
    end
  end

  def caveats; <<-EOS
    The following Trilinos packages were disabled due to compile errors:
      FEI, Piro, SEACAS, STK, Stokhos
    EOS
  end

  test do
    # system "#{bin}/Epetra_BasicPerfTest_test.exe", "16", "12", "1", "1", "25", "-v"
    # system "mpirun", "-np", "2", "#{bin}/Epetra_BasicPerfTest_test.exe", "10", "12", "1", "2", "9", "-v" if build.with? "mpi"
    # system "#{bin}/Epetra_BasicPerfTest_test_LL.exe", "16", "12", "1", "1", "25", "-v"
    # system "mpirun", "-np", "2", "#{bin}/Epetra_BasicPerfTest_test_LL.exe", "10", "12", "1", "2", "9", "-v" if build.with? "mpi"
    # system "#{bin}/Ifpack2_BelosTpetraHybridPlatformExample.exe"                    # this file is not there
    # system "#{bin}/KokkosClassic_SerialNodeTestAndTiming.exe"                       # this file is not there
    # system "#{bin}/KokkosClassic_TPINodeTestAndTiming.exe"                          # this file is not there
    # system "#{bin}/KokkosClassic_TBBNodeTestAndTiming.exe" if build.with? "tbb"     # this file is not there
    # system "#{bin}/Tpetra_GEMMTiming_TBB.exe" if build.with? "tbb"                  # this file is not there
    # system "#{bin}/Tpetra_GEMMTiming_TPI.exe"                                       # this file is not there
  end
end

__END__
diff --git a/cmake/TPLs/FindTPLUMFPACK.cmake b/cmake/TPLs/FindTPLUMFPACK.cmake
index 963eb71..998cd02 100644
--- a/cmake/TPLs/FindTPLUMFPACK.cmake
+++ b/cmake/TPLs/FindTPLUMFPACK.cmake
@@ -55,6 +55,6 @@


 TRIBITS_TPL_FIND_INCLUDE_DIRS_AND_LIBRARIES( UMFPACK
-  REQUIRED_HEADERS umfpack.h amd.h UFconfig.h
+  REQUIRED_HEADERS umfpack.h amd.h SuiteSparse_config.h
   REQUIRED_LIBS_NAMES umfpack amd
   )
