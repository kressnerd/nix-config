{ lib, ... }:
{
  boot = {
    loader.systemd-boot = {
      enable = lib.mkForce false;
      # lanzaboote reads configurationLimit to cap UKIs on 512 MiB ESP
      configurationLimit = 5;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
  };
}
