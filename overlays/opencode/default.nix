# OpenCode 2.x overlay
# nixpkgs ships OpenCode 1.x only; 2.x is distributed as prebuilt per-platform
# binaries via npm (@opencode/cli-<os>-<arch>). Bump version + both hashes to update.
final: _prev:
let
  version = "2.0.22";
  platforms = {
    aarch64-darwin = {
      slug = "darwin-arm64";
      hash = "sha512-NNg1VCCTWSfLlNKpRb4RA6IE7H67ZBLBYmfIWjP3CxR9NPtdROQFCL8lpPf+Tz2Qje4Bb27sQOLWanYyNT/9dQ==";
    };
    x86_64-linux = {
      slug = "linux-x64";
      hash = "sha512-DlV1qgEDDnVqpTWMPqv7tCHCcXodzZBFaMcxjsiYdY6E5gHH2Q68JfasVksyQ1nu6m1887WQKGhOsepE+oKyYw==";
    };
  };
  platform = platforms.${final.stdenv.hostPlatform.system} or null;
in
{
  opencode = final.stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit version;

    src = final.fetchurl {
      url = "https://registry.npmjs.org/@opencode/cli-${platform.slug}/-/cli-${platform.slug}-${version}.tgz";
      inherit (platform) hash;
    };

    sourceRoot = "package";

    nativeBuildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [
      final.autoPatchelfHook
    ];
    buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.stdenv.cc.cc.lib ];

    # bun-compiled binary: stripping/fixup corrupts the embedded JS payload
    dontStrip = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 bin/opencode $out/bin/opencode
      runHook postInstall
    '';

    meta = {
      description = "AI coding agent built for the terminal (2.x prebuilt binary)";
      homepage = "https://opencode.ai";
      license = final.lib.licenses.mit;
      mainProgram = "opencode";
      platforms = builtins.attrNames platforms;
    };
  };
}
