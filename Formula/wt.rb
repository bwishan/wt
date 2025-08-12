class Wt < Formula
  desc "Git Worktree Manager - A minimalist CLI for managing git worktrees"
  homepage "https://github.com/bwishan/wt"
  url "https://github.com/bwishan/wt/releases/download/v0.2.0/wt-0.2.0-universal.tar.gz"
  sha256 "8a51dbe83b654303481b5c316a2a5edbec2a9bab5a838e0c7f7ab857ef7d4d4d"
  version "0.2.0"
  license "MIT"

  depends_on "python@3.11"
  depends_on "git"

  def install
    bin.install "wt"
  end

  test do
    system "#{bin}/wt", "--version"
    assert_match "wt 0.2.0", shell_output("#{bin}/wt --version")
  end
end