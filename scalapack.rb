require_relative "requirements/blas_requirement"
require_relative "requirements/cmake_requirement"

class Scalapack < Formula
  desc "library of high-performance linear algebra routines for parallel distributed memory machines"
  homepage "http://www.netlib.org/scalapack/"
  url "http://www.netlib.org/scalapack/scalapack-2.0.2.tgz"
  sha256 "0c74aeae690fe5ee4db7926f49c5d0bb69ce09eea75beb915e00bba07530395c"
  head "https://icl.cs.utk.edu/svn/scalapack-dev/scalapack/trunk", :using => :svn
  revision 3

  bottle do
    cellar :any
    revision 1
    sha256 "80fd977c7637d131e186dc4a016416df1c00d4736cce881631b242c990adc4bd" => :yosemite
    sha256 "fb9b8db4347d67cc9f3bd9277a7b7026c1f03453e1f28afbf8af96ea96e4f117" => :mavericks
    sha256 "e0b122d96b125fa524023dc730564b9a45ddc134b1e025c464a4c8f1a7554dcd" => :mountain_lion
  end

  option "without-check", "Skip build-time tests (not recommended)"

  depends_on :mpi => [:cc, :f90]
  depends_on CmakeRequirement => ["2.8", :build]
  depends_on :fortran
  depends_on BlasRequirement => :fortran_single

  def install
    args = %W[
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DBUILD_SHARED_LIBS=ON
      -DBUILD_TESTING=ON
      -DCMAKE_BUILD_TYPE:STRING=Release
    ]
    # Accelerate uses the f2c/f77 complex return type conventions and so ScaLAPACK must be built with the -ff2c option. (see http://comments.gmane.org/gmane.comp.mathematics.elemental.devel/627)
    # same applied to MKL
    args << "-DCMAKE_Fortran_FLAGS=-ff2c -fno-second-underscore" if OS.mac?

    ldflags = BlasRequirement.ldflags(ENV["HOMEBREW_BLASLAPACK_LIB"],ENV["HOMEBREW_BLASLAPACK_NAMES"],ENV["HOMEBREW_BLASLAPACK_EXTRA"])
    args += ["-DBLAS_LIBRARIES:STRING=#{ldflags}", "-DLAPACK_LIBRARIES:STRING=#{ldflags}"]

    mkdir "build" do
      system "cmake", "..", *args
      system "make", "all"
      system "make", "test" if build.with? "check"
      system "make", "install"
    end
  end
end
