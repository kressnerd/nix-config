# tests/assertions/thiniel-hm-invariants.nix
# Home-Manager-level invariants for the personal laptop's home profile.
#
# This module needs the home profile's evaluation, which only exists inside the
# Home Manager evaluation — so `home/dan/thiniel.nix` imports it, mirroring
# `tests/assertions/J6G6Y9JK7L-invariants.nix`. It is deliberately not
# aggregated into the NixOS-level `tests/assertions/default.nix`.
{
  config,
  lib,
  pkgs,
  rustToolchain,
  ...
}:
let
  hmPkgNames = builtins.map (p: p.pname or p.name or "") config.home.packages;
in
{
  assertions = [
    {
      # The declared toolchain is the aggregated release derivation (its name
      # carries no "rustc"/"cargo"), so assert the declaration itself is what
      # the profile installs. See the change `rust-coverage-toolchain`, F1.
      assertion = builtins.elem rustToolchain config.home.packages;
      message = "thiniel: the declared Rust toolchain (compiler, Cargo, formatter, lint driver and coverage tools of one release) must be installed";
    }
    {
      assertion = builtins.any (n: lib.strings.hasInfix "gcc" n) hmPkgNames;
      message = "thiniel: a C linker (gcc) must be installed so a Rust build can link its program";
    }
    {
      assertion = builtins.any (n: lib.strings.hasInfix "pkg-config" n) hmPkgNames;
      message = "thiniel: pkg-config must be installed so Rust crates can discover system libraries";
    }
    {
      assertion = builtins.any (
        d: (if builtins.isString d then d else d.directory or "") == ".cargo"
      ) config.home.persistence."/persist".directories;
      message = "thiniel: .cargo must be persisted so the Cargo home survives the root wipe";
    }
    {
      # Home Manager exports MOZ_APP_DATA to the browser wrapper only when
      # configPath differs from its resolved (relative) default, so the
      # absolute XDG path must stay stated or the browser falls back to
      # ~/.mozilla/firefox while the profiles.ini is rendered under XDG.
      assertion = config.programs.firefox.configPath == "${config.xdg.configHome}/mozilla/firefox";
      message = "thiniel: the browser profile location must be the absolute XDG path so the wrapper exports MOZ_APP_DATA";
    }
    # Guards for this change's boundary: withdrawing the empty fleet hive must
    # not take the operator's fleet tooling with it. They hold before and after
    # the change, so they carry no RED phase of their own.
    {
      assertion = lib.elem pkgs.colmena config.home.packages;
      message = "thiniel: the fleet deployment tool (Colmena) must stay installed although the hive output is withdrawn";
    }
    {
      assertion = builtins.all (a: builtins.hasAttr a config.programs.fish.shellAliases) [
        "cs"
        "ct"
        "cb"
        "cda"
        "call"
      ];
      message = "thiniel: the fleet deployment aliases (cs/ct/cb/cda/call) must stay declared although the hive output is withdrawn";
    }
  ];
}
