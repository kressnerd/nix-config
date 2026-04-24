{ config, lib, ... }:
let
  cfg = config.myHome.persistence;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    home.persistence.${cfg.root} = {
      directories = [
        ".cache/mesa_shader_cache"
        ".cache/mesa_shader_cache_db"
        "dev"
        "Projects"
        ".config/sops/age"
        ".config/netcup-scp"
        ".local/share/netcup-scp"
      ];
      files = [
        ".bash_history"
      ];
    };
  };
}
