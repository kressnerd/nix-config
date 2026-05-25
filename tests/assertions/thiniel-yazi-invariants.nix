# tests/assertions/thiniel-yazi-invariants.nix
# Yazi dual-pane assertions for thiniel — enforced at evaluation time via nix flake check
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions =
      let
        hmPersistDirs = config.home-manager.users.dan.home.persistence."/persist".directories;
        hmHasDir =
          path:
          builtins.any (
            d: if builtins.isString d then d == path else (d.directory or "") == path
          ) hmPersistDirs;
      in
      [
        {
          assertion = config.home-manager.users.dan.programs.yazi.enable;
          message = "thiniel: yazi must be enabled";
        }
        {
          assertion = config.home-manager.users.dan.stylix.targets.yazi.enable;
          message = "thiniel: stylix.targets.yazi must remain enabled after refactor";
        }
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
        {
          assertion = hmHasDir ".local/share/yazi";
          message = "thiniel: .local/share/yazi must be persisted for history and bookmarks";
        }
      ];
  };
}
