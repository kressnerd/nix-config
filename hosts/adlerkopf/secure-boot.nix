{ lib, config, ... }:
{
  # Secure Boot only applies to the real host; the VM variant boots via
  # systemd-boot and disables lanzaboote.
  boot = lib.mkIf (!config.adlerkopf.vmMode) {
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
