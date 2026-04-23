# tests/assertions/thiniel-libreoffice-invariants.nix
# LibreOffice assertions for thiniel — enforced at evaluation time via nix flake check
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
          assertion = builtins.any (
            p: lib.hasPrefix "libreoffice" (p.pname or p.name or "")
          ) config.home-manager.users.dan.home.packages;
          message = "thiniel: LibreOffice must be installed via Home Manager for office productivity";
        }
        {
          assertion = hmHasDir ".config/libreoffice";
          message = "thiniel: .config/libreoffice must be persisted for LibreOffice user settings and recent documents";
        }
      ];
  };
}
