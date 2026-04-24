{ config, lib, ... }:
let
  cfg = config.mySystem.persistence;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable {
    environment.persistence.${cfg.root} = {
      hideMounts = true;
      directories = [
        "/etc/nixos"
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
      ];
      files = [
        "/etc/machine-id"
        "/var/lib/sops-nix/key.txt"
      ];
    };
  };
}
