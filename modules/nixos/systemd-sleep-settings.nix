# modules/nixos/systemd-sleep-settings.nix
# Provides systemd.sleep.settings.Sleep.* as a structured option, translating
# it into systemd.sleep.extraConfig (raw INI key=value pairs inside [Sleep]).
# Required because nixpkgs 25.11 only exposes systemd.sleep.extraConfig (a raw string).
{ config, lib, ... }:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    mkIf
    mkOption
    types
    ;
  cfg = config.systemd.sleep.settings;
  sleepSection = cfg.Sleep or { };
in
{
  options.systemd.sleep.settings = mkOption {
    type = types.attrsOf (types.attrsOf types.str);
    default = { };
    description = "Structured settings for systemd-sleep.conf, keyed by section name (e.g. Sleep).";
  };

  config = mkIf (sleepSection != { }) {
    systemd.sleep.extraConfig = concatStringsSep "\n" (mapAttrsToList (k: v: "${k}=${v}") sleepSection);
  };
}
