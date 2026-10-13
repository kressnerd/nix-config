# tests/assertions/thiniel-hm-invariants.nix
# Home-Manager-level invariants for the personal laptop's home profile.
#
# This module needs the home profile's `options` (to see whether a setting is
# stated by the device or resolved from a release default), which only exists
# inside the Home Manager evaluation — so `home/dan/thiniel.nix` imports it,
# mirroring `tests/assertions/J6G6Y9JK7L-invariants.nix`. It is deliberately not
# aggregated into the NixOS-level `tests/assertions/default.nix`.
{ config, options, lib, ... }:
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
in
{
  assertions = [
    {
      assertion = !(superseded [ "wayland" "windowManager" "hyprland" "configType" ] {
        value = "hyprlang";
      } { value = "lua"; });
      message = "thiniel: the compositor configuration format must be stated by the device, not resolved from the release's superseded default (set wayland.windowManager.hyprland.configType)";
    }
  ];
}
