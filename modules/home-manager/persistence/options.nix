{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.myHome.persistence = {
    enable = mkEnableOption "Home Manager impermanence persistence";
    root = mkOption {
      type = types.str;
      default = "/persist";
      description = "Root mount point for Home Manager persistence bind mounts.";
    };
  };
}
