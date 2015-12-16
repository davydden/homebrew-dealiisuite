require_relative "requirements/blas_requirement"
require_relative "requirements/cmake_requirement"

class Dealii < Formula
  desc "open source finite element library"
  homepage "http://www.dealii.org"
  url "https://github.com/dealii/dealii/releases/download/v8.3.0/dealii-8.3.0.tar.gz"
  sha256 "4ddf72632eb501e1c814e299f32fc04fd680d6fda9daff58be4209e400e41779"
  revision 1

  bottle do
    cellar :any
    sha256 "2b194b50ae1648f1c869a639cca60ff6e1976f7e734efd0580afb0967cabaf10" => :el_capitan
    sha256 "32907efdf770f4aaf4d519bb8682c9e0e25379edb6b9e735f8f5e4de6866a0f6" => :yosemite
    sha256 "4de1c4e2db3bd4fe4195851f6e3f52e2f8959c52d5832e4633c896ff0d47dd51" => :mavericks
  end

  head do
    url "https://github.com/dealii/dealii.git"
  end

  option "with-testsuite", "Run full test suite (7000+ tests). Takes a lot of time."

  depends_on CmakeRequirement => ["2.8",:build]
  depends_on BlasRequirement
  depends_on :mpi           => [:cc, :cxx, :f90, :recommended]

  mpidep      = (build.with? "mpi")      ? ["with-mpi"]      : []

  depends_on "arpack"       => [:recommended] + mpidep
  depends_on "boost"        => :recommended
  #-depends_on "doxygen"      => :optional # installation error: CMake Error at doc/doxygen/cmake_install.cmake:31 (file)
  depends_on "hdf5"         => [:recommended] + mpidep
  depends_on "metis"        => :recommended
  #-depends_on "muparser"     => :recommended if MacOS.version != :mountain_lion # Undefined symbols for architecture x86_64
  #-depends_on "netcdf"       => [:recommended, "with-fortran", "with-cxx-compat"]
  #-depends_on "opencascade"  => :recommended
  depends_on "p4est"        => :recommended if build.with? "mpi"
  depends_on "parmetis"     => :recommended if build.with? "mpi"
  depends_on "petsc"        => :recommended
  depends_on "slepc"        => :recommended
  depends_on "suite-sparse" => :recommended
  #-depends_on "tbb"          => :recommended
  depends_on "trilinos"     => :recommended

  needs :cxx11
  def install
    ENV.cxx11
    args = %W[
      -DCMAKE_BUILD_TYPE=DebugRelease
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DCMAKE_FIND_FRAMEWORK=LAST
      -Wno-dev
      -DDEAL_II_COMPONENT_COMPAT_FILES=OFF
      -DDEAL_II_COMPONENT_EXAMPLES=ON
      -DDEAL_II_COMPONENT_MESH_CONVERTER=ON
    ]
    # constrain Cmake to look for libraries in homebrew's prefix
    args << "-DCMAKE_PREFIX_PATH=#{HOMEBREW_PREFIX}"

    args << "-DDEAL_II_COMPONENT_DOCUMENTATION=ON" if build.with? "doxygen"

    blas_inc   = ENV["HOMEBREW_BLASLAPACK_INC"]
    blas_processed = BlasRequirement.full_path(ENV["HOMEBREW_BLASLAPACK_LIB"],ENV["HOMEBREW_BLASLAPACK_NAMES"],";")
    args << "-DLAPACK_FOUND=true"
    args << "-DLAPACK_INCLUDE_DIRS=#{blas_inc}"
    args << "-DLAPACK_LIBRARIES=#{blas_processed}"

    if build.with? "mpi"
      args << "-DCMAKE_C_COMPILER=mpicc"
      args << "-DCMAKE_CXX_COMPILER=mpicxx"
      args << "-DCMAKE_Fortran_COMPILER=mpif90"
    end

    args << "-DARPACK_DIR=#{Formula["arpack"].opt_prefix}" if build.with? "arpack"
    args << "-DBOOST_DIR=#{Formula["boost"].opt_prefix}" if build.with? "boost"
    args << "-DHDF5_DIR=#{Formula["hdf5"].opt_prefix}" if build.with? "hdf5"
    args << "-DMETIS_DIR=#{Formula["metis"].opt_prefix}" if build.with? "metis"
    args << "-DMUPARSER_DIR=#{Formula["muparser"].opt_prefix}" if build.with? "muparser"
    args << "-DNETCDF_DIR=#{Formula["netcdf"].opt_prefix}" if build.with? "netcdf"
    args << "-DOPENCASCADE_DIR=#{Formula["opencascade"].opt_prefix}" if build.with? "opencascade"
    args << "-DP4EST_DIR=#{Formula["p4est"].opt_prefix}" if build.with? "p4est"
    args << "-DPETSC_DIR=#{Formula["petsc"].opt_prefix}" if build.with? "petsc"
    args << "-DSLEPC_DIR=#{Formula["slepc"].opt_prefix}" if build.with? "slepc"
    args << "-DUMFPACK_DIR=#{Formula["suite-sparse"].opt_prefix}" if build.with? "suite-sparse"
    args << "-DTBB_DIR=#{Formula["tbb"].opt_prefix}" if build.with? "tbb"
    args << "-DTRILINOS_DIR=#{Formula["trilinos"].opt_prefix}" if build.with? "trilinos"

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      # run minimal test cases (8 tests)
      log_name = "make-test.log"
      system "make test 2>&1 | tee #{log_name}"
      ohai `grep "tests passed" "#{log_name}"`.chomp
      prefix.install "#{log_name}"
      # run full test suite if really needed
      if build.with? "testsuite"
        system "make", "setup_tests"
        system "ctest", "-j", Hardware::CPU.cores
      end
      system "make", "install"
    end
  end
end
