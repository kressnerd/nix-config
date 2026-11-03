# Maki overlay
# Maki is a terminal coding agent written in Rust; nixpkgs carries no package.
# Upstream publishes per-platform release binaries; build from source is not
# used because its flake builds with crane and advertises no binary cache.
# Bump version + both hashes to update.
final: _prev:
let
  version = "0.7.0";
  platforms = {
    aarch64-darwin = {
      slug = "aarch64-apple-darwin";
      hash = "sha256-z5lKDSrGS19rOL6UEGAuvScQp5JBSNQW72I99B1vemc=";
    };
    aarch64-linux = {
      slug = "aarch64-unknown-linux-musl";
      hash = "sha256-e07mVLDfRQd99nY2BGJ1T7nRxNygp2YvaPBe6CWTZUY=";
    };
    x86_64-linux = {
      slug = "x86_64-unknown-linux-musl";
      hash = "sha256-PgodGkvCu6r965TypVG8wtD27YHt/Z3RMnLZyqWt14c=";
    };
  };
  platform = platforms.${final.stdenv.hostPlatform.system} or null;
in
{
  maki = final.stdenvNoCC.mkDerivation {
    pname = "maki";
    inherit version;

    src = final.fetchurl {
      url = "https://github.com/tontinton/maki/releases/download/v${version}/maki-v${version}-${platform.slug}.tar.gz";
      inherit (platform) hash;
    };

    # The release tarball holds the binary at its root, with no directory.
    sourceRoot = ".";

    dontBuild = true;
    # Prebuilt: stripping a Rust release binary can break its embedded assets.
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 maki $out/bin/maki
      runHook postInstall
    '';

    meta = {
      description = "Efficient terminal coding agent written in Rust";
      homepage = "https://maki.sh";
      license = final.lib.licenses.mit;
      mainProgram = "maki";
      platforms = builtins.attrNames platforms;
    };
  };
}
