require "requirement"

# This class aims to wrap all possible Blas/lapack libraries.
# The most difficult one is MKL.
# The MKL link advisor https://software.intel.com/en-us/articles/intel-mkl-link-line-advisor/ recommends
# LDFLAGS:
#  -L${MKLROOT}/lib -Wl,-rpath,${MKLROOT}/lib -lmkl_intel_lp64 -lmkl_core -lmkl_sequential -lpthread -lm -ldl
# CFLAGS:
#  -m64 -I${MKLROOT}/include
#
# To implement this we define the following environment variables:
#   HOMEBREW_BLASLAPACK_LIB    -- localtion of MKL libraires (e.g. ""${MKLROOT}/lib")
#   HOMEBREW_BLASLAPACK_NAMES  -- names of MKL libraries (e.g. "mkl_intel_lp64;mkl_core;mkl_sequential")
#   HOMEBREW_BLASLAPACK_EXTRA  -- extra (system) libraries' names (e.g. "pthread;m;dl")
#   HOMEBREW_BLASLAPACK_INC    -- include folder (e.g. ""${MKLROOT}/include")
#
# These variables also cover less compilcated cases (e.g. system-provided blas/lapack, veclibfort or openblas)
#
class BlasRequirement < Requirement
  fatal true
  # on OSX -lblas and -llapack should work OOB.
  # the only case when test should fail is when we
  # need BLAS with single precision or complex with Fortran =>
  # use veclibfort
  default_formula "veclibfort" if OS.mac?
  # On Linux we can always fallback to openblas
  default_formula "openblas"   unless OS.mac?

  def initialize(tags = [])
    # if openblas is installed, use it on OS-X/Linux
    if Formula["openblas"].installed?
      @default_names = "openblas"
      @default_lib   = "#{Formula["openblas"].opt_lib}"
      @default_inc   = "#{Formula["openblas"].opt_include}"
      @default_extra = ""
    # if we are on OSX and need fortran and veclibfort is installed use it
    elsif tags.include?(:fortran_single) && OS.mac? && Formula["veclibfort"].installed?
      @default_names = "veclibfort"
      @default_lib   = "#{Formula["veclibfort"].opt_lib}"
      @default_inc   = "#{Formula["veclibfort"].opt_include}"
      @default_extra = ""
    # Otherwise do standard "blas;lapack"
    else
      @default_names = "blas;lapack"
      @default_lib   = ""
      @default_inc   = ""
      @default_extra = ""
    end
    super(tags)
  end

  # This ensures that HOMEBREW_BLASLAPACK_NAMES, HOMEBREW_BLASLAPACK_LIB
  # and HOMEBREW_BLASLAPACK_INC are always set. It does _not_ add them to
  # CFLAGS or LDFLAGS; that should happen inside the formula.
  env do
    if @satisfied_result
      ENV["HOMEBREW_BLASLAPACK_NAMES"] ||= @default_names
      ENV["HOMEBREW_BLASLAPACK_LIB"]   ||= @default_lib
      ENV["HOMEBREW_BLASLAPACK_INC"]   ||= @default_inc
      ENV["HOMEBREW_BLASLAPACK_EXTRA"] ||= @default_extra
    else
      ENV["HOMEBREW_BLASLAPACK_NAMES"]   = "#{self.class.default_formula}"
      ENV["HOMEBREW_BLASLAPACK_LIB"]     = "#{Formula[self.class.default_formula].opt_lib}"
      ENV["HOMEBREW_BLASLAPACK_INC"]     = "#{Formula[self.class.default_formula].opt_include}"
      ENV["HOMEBREW_BLASLAPACK_EXTRA"]   = ""
    end
  end

  # A static function to create linking flags
  # In case library folder is provided, assume that its location is general,
  # and add  "rpath" flags
  def self.ldflags(blas_lib,blas_names,blas_extra)
    res  = blas_lib != "" ? "-L#{blas_lib} -Wl,-rpath,#{blas_lib} " : ""
    res += blas_names.split(";").map { |word| "-l#{word}" }.join(" ")
    res += " "
    res += blas_extra.split(";").map { |word| "-l#{word}" }.join(" ")
    return res
  end

  # A static function to create compiler flags
  def self.cflags(blas_inc)
    return blas_inc != "" ? "-I#{blas_inc}"  : ""
  end

  # A static function to create full path to blas-lapack libraries separated by @p separator .
  def self.full_path(blas_lib,blas_names,blas_extra,separator)
    exten = (OS.mac?) ? "dylib" : "so"
    tmp = blas_lib.chomp("/")
    tmp = "#{tmp}/" if tmp != ""
    res = blas_names.split(";").map { |word| "#{tmp}lib#{word}.#{exten}" }.join(separator)
    # as for extra librareis, we need to assume that their location is inside PATH,
    # so just add them at the end of the list
    res+= separator;
    res+= blas_extra.split(";").map { |word| "lib#{word}.#{exten}" }.join(separator)
    return res
  end

  satisfy :build_env => true do
    blas_names = ENV["HOMEBREW_BLASLAPACK_NAMES"] || @default_names
    blas_lib   = ENV["HOMEBREW_BLASLAPACK_LIB"]   || @default_lib
    blas_inc   = ENV["HOMEBREW_BLASLAPACK_INC"]   || @default_inc
    blas_extra = ENV["HOMEBREW_BLASLAPACK_EXTRA"] || @default_extra
    cflags     = BlasRequirement.cflags(blas_inc)
    ldflags    = BlasRequirement.ldflags(blas_lib,blas_names,blas_extra)
    success = nil
    Dir.mktmpdir do |tmpdir|
      tmpdir = Pathname.new tmpdir
      (tmpdir/"blastest.c").write <<-EOS.undent
        double cblas_ddot(const int, const double*, const int, const double*, const int);
        int main() {
          double x[] = {1.0, 2.0, 3.0}, y[] = {4.0, 5.0, 6.0};
          cblas_ddot(3, x, 1, y, 1);
          return 0;
        }
      EOS
      success = system "#{ENV["CC"]} #{cflags} #{tmpdir}/blastest.c -o #{tmpdir}/blastest #{ldflags}",
                :err => "/dev/null"
      # test fortran to invoke libveclibfort on OS-X
      if @tags.include?(:fortran_single)
        (tmpdir/"blastest.f90").write <<-EOS.undent
          program test
          implicit none
          integer, parameter :: dp = kind(1.0d0)
          real(dp), external :: ddot
          real, external :: sdot
          real, dimension(3) :: a,b
          real(dp), dimension(3) :: d,e
          integer :: i
          do i = 1,3
            a(i) = 1.0*i
            b(i) = 3.5*i
            d(i) = 1.0d0*i
            e(i) = 3.5d0*i
          end do
          if (ABS(ddot(3,d,1,e,1)-sdot(3,a,1,b,1))>1E-10) then
            call exit(1)
          endif
          end program test
        EOS
        fortran = which(ENV["FC"] || "gfortran")
        success2 = system "#{fortran} #{cflags} #{tmpdir}/blastest.f90 -o #{tmpdir}/blastest #{ldflags}",
               :err => "/dev/null"
        success3 = system "#{tmpdir}/blastest",
               :err => "/dev/null"
        success = ( success && success2 ) && success3
      end
    end
    if !success
      opoo "BLAS not configured"
      puts <<-EOS.undent
        Falling back to brewed #{self.class.default_formula}. If you prefer to use a system BLAS, please set
          HOMEBREW_BLASLAPACK_NAMES (e.g. "mkl_intel_lp64;mkl_sequential;mkl_core")
          HOMEBREW_BLASLAPACK_LIB   (e.g. "${MKLROOT}/lib/intel64")
          HOMEBREW_BLASLAPACK_INC   (e.g. "${MKLROOT}/include")
          HOMEBREW_BLASLAPACK_EXTRA (e.g. "pthread;m")
        to correct values.
      EOS
    end
    success
  end
end
