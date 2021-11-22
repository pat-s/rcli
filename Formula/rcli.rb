class Rcli < Formula
  desc "Command Line tool to install and switch between R versions"
  homepage "https://github.com/pat-s/rcli"
  url "file:///Users/pjs/git/rcli/bin/rcli-v0.1.0.tar.gz"
  sha256 "e7efa5859e9c91a65dfdcf2d8122f95c48acf1d3679439cff0a26226c94fb265"
  head "https://github.com/pat-s/rcli.git"
  license "MIT License"

  depends_on "shc" => :build

  depends_on "bash"

  def install
    bin.install "rcli"
  end

end
