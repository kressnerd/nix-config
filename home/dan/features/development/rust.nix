{
  config,
  lib,
  pkgs,
  rustToolchain,
  ...
}:
{
  home = {
    # One released Rust toolchain: compiler, Cargo, formatter and lint driver
    # (the coverage tools are added by the change `rust-coverage-toolchain`).
    # The derivation is declared once in `flake.nix` and passed in, so the
    # booted check proves exactly what the device installs.
    packages = [
      rustToolchain
      pkgs.gcc
      pkgs.pkg-config
    ];
  }
  // lib.optionalAttrs config.myHome.persistence.enable {
    persistence.${config.myHome.persistence.root}.directories = [ ".cargo" ];
  };
}
