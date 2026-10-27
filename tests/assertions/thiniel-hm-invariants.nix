# tests/assertions/thiniel-hm-invariants.nix
# Home-Manager-level invariants for the personal laptop's home profile.
#
# This module needs the home profile's `options` (to see whether a setting is
# stated by the device or resolved from a release default), which only exists
# inside the Home Manager evaluation — so `home/dan/thiniel.nix` imports it,
# mirroring `tests/assertions/J6G6Y9JK7L-invariants.nix`. It is deliberately not
# aggregated into the NixOS-level `tests/assertions/default.nix`.
{
  config,
  options,
  lib,
  pkgs,
  rustToolchain,
  ...
}:
let
  # A release resolves a setting whose default it superseded through this
  # helper and emits its migration warning exactly when the option is left at
  # the default priority. Asserting the helper's own predicate therefore
  # asserts the absence of the diagnostic without matching its warning text.
  superseded =
    path: legacy: current:
    (lib.hm.deprecations.mkStateVersionOptionDefault {
      inherit (config.home) stateVersion;
      since = "26.05";
      optionPath = path;
      inherit config options;
      deferWarningToConfig = true;
      inherit legacy current;
    }).shouldWarn;

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
      assertion =
        !(superseded [ "wayland" "windowManager" "hyprland" "configType" ] {
          value = "hyprlang";
        } { value = "lua"; });
      message = "thiniel: the compositor configuration format must be stated by the device, not resolved from the release's superseded default (set wayland.windowManager.hyprland.configType)";
    }
    {
      assertion =
        !(superseded [ "programs" "firefox" "configPath" ] {
          value = ".mozilla/firefox";
        } { value = ".config/mozilla/firefox"; });
      message = "thiniel: the browser profile location must be stated by the device, not resolved from the release's superseded default (set programs.firefox.configPath)";
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
