require_relative "requirements/cmake_requirement"

class Metis < Formula
  homepage "http://glaros.dtc.umn.edu/gkhome/views/metis"
  url "http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz"
  sha256 "76faebe03f6c963127dbb73c13eab58c9a3faeae48779f049066a21c087c5db2"

  bottle do
    cellar :any
    sha256 "1e127767a51ae71e36fee29e3f646dc038898c1cca7da5b707266456ff50f5ac" => :yosemite
    sha256 "da4e731c9c8c1b295e300eafe1851171cb08793484b0583ca6606a8344dae9ee" => :mavericks
    sha256 "5ab878427e696a9893aeb9c69b18938430adfd8d1cdfd37b0c7149aa5aa68e19" => :mountain_lion
  end

  option :universal
  depends_on CmakeRequirement => ["2.8",:build]

  def install
    ENV.universal_binary if build.universal?
    args = %W[
      -DCMAKE_VERBOSE_MAKEFILE=1
      -DCMAKE_BUILD_TYPE=Release
      -DCMAKE_INSTALL_PREFIX=#{prefix}
      -DSHARED=1
      -DOPENMP=0
      -DCMAKE_FIND_FRAMEWORK=LAST
      -Wno-dev      
      -DCMAKE_INSTALL_RPATH:STRING=#{lib}
      -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=ON
      -DGKLIB_PATH=../GKlib
    ]

    mkdir "_build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"

      (share / "metis").install "../graphs"
      doc.install "../manual"
    end
  end

  test do
    cp_r share, testpath
    ["4elt", "copter2", "mdual"].each do |g|
      system "#{bin}/graphchk", "#{testpath}/share/metis/graphs/#{g}.graph"
      system "#{bin}/gpmetis", "#{testpath}/share/metis/graphs/#{g}.graph", "2"
      system "#{bin}/ndmetis", "#{testpath}/share/metis/graphs/#{g}.graph"
    end
    system "#{bin}/gpmetis", "#{testpath}/share/metis/graphs/test.mgraph", "2"
    system "#{bin}/mpmetis", "#{testpath}/share/metis/graphs/metis.mesh", "2"
  end
end
