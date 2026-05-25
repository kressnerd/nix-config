# tests/assertions/thiniel-yazi-invariants.nix
# Yazi dual-pane assertions for thiniel — enforced at evaluation time via nix flake check
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.home-manager.users.dan.programs.yazi.plugins ? "dual-pane";
        message = "thiniel: yazi dual-pane plugin must be configured";
      }
      {
        assertion = config.home-manager.users.dan.programs.yazi.keymap != { };
        message = "thiniel: yazi keymap must include dual-pane keybindings";
      }
      {
        assertion =
          builtins.isString config.home-manager.users.dan.programs.yazi.initLua
          &&
            builtins.match ".*dual-pane.*setup.*" config.home-manager.users.dan.programs.yazi.initLua != null;
        message = "thiniel: yazi init.lua must call dual-pane setup";
      }
    ];
  };
}
