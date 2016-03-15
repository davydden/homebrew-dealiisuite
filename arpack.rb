require_relative "requirements/blas_requirement"

class Arpack < Formula
  desc "ARPACK is a collection of Fortran77 subroutines designed to solve large scale eigenvalue problems."
  homepage "https://github.com/opencollab/arpack-ng"
  url "https://github.com/opencollab/arpack-ng/archive/3.3.0.tar.gz"
  sha256 "ad59811e7d79d50b8ba19fd908f92a3683d883597b2c7759fdcc38f6311fe5b3"
  head "https://github.com/opencollab/arpack-ng.git"

  bottle do
    sha256 "eda08d15be408cb40b882913c0d1420f503b6700ec4dadbfa1eca1c596088b06" => :yosemite
    sha256 "6336c1f26b5559afc0c8568c87d00e7a77467a28e7486c86ca724366a53399f6" => :mavericks
    sha256 "2ea9e43da77b36845c044e4d9d95b1e0b7fe1f4a18bd3ff4c5ff715c1fab23de" => :mountain_lion
  end

  option "without-check", "skip tests (not recommended)"

  #-depends_on "autoconf" => :build
  #-depends_on "automake" => :build

  depends_on :fortran
  depends_on :mpi => [:optional, :f77]
  depends_on BlasRequirement => :fortran_single

  patch :DATA

  def install
    #-ENV.m64 if MacOS.prefer_64_bit?

    cc_args = (build.with? :mpi) ? ["F77=#{ENV["MPIF77"]}"] : []
    cc_args << "FFLAGS=-ff2c -fno-second-underscore"
    args = cc_args + ["--disable-dependency-tracking", "--prefix=#{libexec}"]
    args << "--enable-mpi" if build.with? :mpi
    ldflags = BlasRequirement.ldflags(ENV["HOMEBREW_BLASLAPACK_LIB"],ENV["HOMEBREW_BLASLAPACK_NAMES"],ENV["HOMEBREW_BLASLAPACK_EXTRA"])
    args << "--with-blas=#{ldflags}"

    # since 3.3.0 Arpack does not contain generated configure scirpt
    # must bootstrap first:
    system "./bootstrap"

    system "./configure", *args
    system "make"
    system "make", "check" if build.with? "check"
    system "make", "install"
    lib.install_symlink Dir["#{libexec}/lib/*"].select { |f| File.file?(f) }
    (lib / "pkgconfig").install_symlink Dir["#{libexec}/lib/pkgconfig/*"]
    (libexec / "share").install "TESTS/testA.mtx"
  end

  test do
    # TODO: need to enable in 3.3.0
    #if build.with? "mpi"
    #  cd libexec/"bin" do
    #    ["pcndrv1", "pdndrv1", "pdndrv3", "pdsdrv1", "psndrv3", "pssdrv1", "pzndrv1"].each do |slv|
    #      system "mpirun -np 4 #{slv}" if build.with? "mpi"
    #    end
    #  end
    #end
  end
end

__END__
diff --git a/PARPACK/SRC/MPI/pdlamch10.f b/PARPACK/SRC/MPI/pdlamch10.f
index 6571da9..2882c2e 100644
--- a/PARPACK/SRC/MPI/pdlamch10.f
+++ b/PARPACK/SRC/MPI/pdlamch10.f
@@ -86,8 +86,8 @@
           TEMP = TEMP1
       END IF
 *
-      PDLAMCH = TEMP
+      PDLAMCH10 = TEMP
 *
-*     End of PDLAMCH
+*     End of PDLAMCH10
 *
       END
