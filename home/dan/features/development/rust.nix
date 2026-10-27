{
  config,
  lib,
  pkgs,
  rustToolchain,
  cargoLlvmCov,
  ...
}:
{
  home = {
    # One released Rust toolchain: compiler, Cargo, formatter, lint driver and
    # the coverage tools of that release, plus the command that reads them.
    # The derivation is declared once in `flake.nix` and passed in, so the
    # booted check proves exactly what the device installs.
    packages = [
      rustToolchain
      cargoLlvmCov
      pkgs.gcc
      pkgs.pkg-config
    ];
  }
  // lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [ ".cargo" ];
  };
}
