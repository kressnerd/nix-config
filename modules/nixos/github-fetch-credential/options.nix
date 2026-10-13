{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.mySystem.githubFetchCredential = {
    enable = mkEnableOption "the per-machine GitHub fetch credential for nix";

    user = mkOption {
      type = types.str;
      default = "dan";
      description = "Account that must be able to read the rendered credential fragment.";
    };
  };
}
