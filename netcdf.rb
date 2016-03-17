class Netcdf < Formula
  desc "Libraries and data formats for array-oriented scientific data"
  homepage "http://www.unidata.ucar.edu/software/netcdf"
  url "ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.3.3.1.tar.gz"
  mirror "http://www.gfd-dennou.org/library/netcdf/unidata-mirror/netcdf-4.3.3.1.tar.gz"
  sha256 "bdde3d8b0e48eed2948ead65f82c5cfb7590313bc32c4cf6c6546e4cea47ba19"
  revision 4

  bottle do
    cellar :any
    sha256 "9417a3dfd9e47bf1f744964f4c515a5838f1101c04a8910d1db6b80f0c8fb39b" => :el_capitan
    sha256 "de2a9557f2eec6ec682b4fef4ac6b2d12a461089267133e9d408d682cf3f404e" => :yosemite
    sha256 "b807d5fd18583e30e8d00d5b754cf6ad6f5ccbd95e6d56f007b83c911911be22" => :mavericks
  end

  deprecated_option "enable-fortran" => "with-fortran"
  deprecated_option "disable-cxx" => "without-cxx"
  deprecated_option "enable-cxx-compat" => "with-cxx-compat"

  option "without-cxx", "Don't compile C++ bindings"
  option "with-cxx-compat", "Compile C++ bindings for compatibility"
  option "without-check", "Disable checks (not recommended)"

  depends_on :fortran => :optional
  depends_on "hdf5"

  resource "cxx" do
    url "https://github.com/Unidata/netcdf-cxx4/archive/v4.2.1.tar.gz"
    sha256 "bad56abfc99f321829070c04aebb377fc8942a4d09e5a3c88ad2b6547ed50ebc"
  end

  resource "cxx-compat" do
    url "http://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-cxx-4.2.tar.gz"
    mirror "http://www.gfd-dennou.org/arch/netcdf/unidata-mirror/netcdf-cxx-4.2.tar.gz"
    sha256 "95ed6ab49a0ee001255eac4e44aacb5ca4ea96ba850c08337a3e4c9a0872ccd1"
  end

  resource "fortran" do
    url "ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-fortran-4.4.2.tar.gz"
    mirror "http://www.gfd-dennou.org/arch/netcdf/unidata-mirror/netcdf-fortran-4.4.2.tar.gz"
    sha256 "ad6249b6062df6f62f81d1cb2a072e3a4c595f27f11fe0c5a79726d1dad3143b"
  end

  def install
    if build.with? "fortran"
      # fix for ifort not accepting the --force-load argument, causing
      # the library libnetcdff.dylib to be missing all the f90 symbols.
      # http://www.unidata.ucar.edu/software/netcdf/docs/known_problems.html#intel-fortran-macosx
      # https://github.com/mxcl/homebrew/issues/13050
      ENV["lt_cv_ld_force_load"] = "no" if ENV.fc == "ifort"
    end

    # Intermittent availability of the DAP endpoints tested means that sometimes
    # a perfectly working build fails. This has been documented
    # [by others](http://www.unidata.ucar.edu/support/help/MailArchives/netcdf/msg12090.html),
    # and distributions like PLD linux
    # [also disable these tests](http://lists.pld-linux.org/mailman/pipermail/pld-cvs-commit/Week-of-Mon-20110627/314985.html)
    # because of this issue.

    common_args = %W[
      --disable-dependency-tracking
      --disable-dap-remote-tests
      --prefix=#{prefix}
      --enable-static
      --enable-shared
    ]

    args = common_args.clone
    args << "--enable-netcdf4" << "--disable-doxygen"

    system "./configure", *args
    system "make"
    ENV.deparallelize if build.with? "check" # Required for `make check`.
    system "make", "check" if build.with? "check"
    system "make", "install"

    # Add newly created installation to paths so that binding libraries can
    # find the core libs.
    ENV.prepend_path "PATH", bin
    ENV.prepend "CPPFLAGS", "-I#{include}"
    ENV.prepend "LDFLAGS", "-L#{lib}"

    if build.with? "cxx"
      resource("cxx").stage do
        system "./configure", *common_args
        system "make"
        system "make", "check" if build.with? "check"
        system "make", "install"
      end
    end

    if build.with? "cxx-compat"
      resource("cxx-compat").stage do
        system "./configure", *common_args
        system "make"
        system "make", "check" if build.with? "check"
        system "make", "install"
      end
    end

    if build.with? "fortran"
      resource("fortran").stage do
        # fixes "error while loading shared libraries: libnetcdf.so.7".
        # see https://github.com/Homebrew/homebrew-science/issues/2521#issuecomment-121851582
        # this should theoretically be enough: ENV.prepend "LDFLAGS", "-L#{lib}", but it is not.
        ENV.prepend "LD_LIBRARY_PATH", "#{lib}"
        system "./configure", *common_args
        system "make"
        system "make", "check" if build.with? "check"
        system "make", "install"
      end
    end
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <stdio.h>
      #include "netcdf_meta.h"
      int main()
      {
        printf(NC_VERSION);
        return 0;
      }
    EOS
    system ENV.cc, "test.c", "-L#{lib}", "-I#{include}", "-lnetcdf", "-o", "test"
    assert_equal `./test`, version.to_s
  end
end
