class Inplaceai < Formula
  desc "AI Hotkey - macOS background application for AI-powered text processing via global hotkeys"
  homepage "https://github.com/nemot/inplace_ai"
  url "https://github.com/nemot/inplace_ai/releases/download/v1.0.0/InplaceAI-v1.0.0.tar.gz"
  sha256 "f39fd44c6d6feac9348393dd95ffc46e2f14ac31011c24f94e135f7b60435fe3"
  license "MIT"

  depends_on :macos => :monterey

  def install
    bin.install "InplaceAI"
  end

  service do
    run [opt_bin/"InplaceAI"]
    keep_alive true
    log_path var/"log/inplaceai.log"
    error_log_path var/"log/inplaceai.log"
  end

  test do
    system "#{bin}/InplaceAI", "--version"
  end
end
