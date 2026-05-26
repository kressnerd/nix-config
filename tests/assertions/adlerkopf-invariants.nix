{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.networking.hostName == "adlerkopf") {
    assertions = [
      {
        assertion = config.networking.hostName == "adlerkopf";
        message = "adlerkopf: hostName must be adlerkopf";
      }
      {
        assertion = config.networking.firewall.enable;
        message = "adlerkopf: firewall must be enabled";
      }
      {
        assertion = !config.networking.networkmanager.enable;
        message = "adlerkopf: NetworkManager must be disabled (server host)";
      }
      {
        assertion = config.adlerkopf.vmMode || (config.disko.devices.disk ? nvme0n1);
        message = "adlerkopf: disko must target nvme0n1 (NVMe disk) unless running as VM";
      }
      {
        assertion =
          config.adlerkopf.vmMode
          || (config.fileSystems ? "/persist" && config.fileSystems."/persist".neededForBoot);
        message = "adlerkopf: /persist must have neededForBoot = true";
      }
      {
        assertion =
          config.adlerkopf.vmMode || (config.fileSystems ? "/nix" && config.fileSystems."/nix".neededForBoot);
        message = "adlerkopf: /nix must have neededForBoot = true";
      }
      {
        assertion =
          config.adlerkopf.vmMode
          || (config.fileSystems ? "/var/log" && config.fileSystems."/var/log".neededForBoot);
        message = "adlerkopf: /var/log must have neededForBoot = true";
      }
      {
        assertion = config.services.openssh.enable;
        message = "adlerkopf: openssh must be enabled";
      }
      {
        assertion = config.services.openssh.settings.PermitRootLogin == "no";
        message = "adlerkopf: SSH PermitRootLogin must be no";
      }
      {
        assertion = !config.services.openssh.settings.PasswordAuthentication;
        message = "adlerkopf: SSH PasswordAuthentication must be false";
      }
      {
        assertion = !config.services.openssh.settings.KbdInteractiveAuthentication;
        message = "adlerkopf: SSH KbdInteractiveAuthentication must be false";
      }
      {
        assertion = !config.security.sudo.wheelNeedsPassword;
        message = "adlerkopf: wheel group must not require sudo password (nixos-rebuild --use-remote-sudo)";
      }
      {
        assertion = config.services.caddy.enable;
        message = "adlerkopf: Caddy must be enabled";
      }
      {
        assertion = config.sops.defaultSopsFile != null;
        message = "adlerkopf: sops.defaultSopsFile must be set";
      }
      {
        assertion = config.adlerkopf.vmMode || config.boot.lanzaboote.enable;
        message = "adlerkopf: lanzaboote Secure Boot must be enabled";
      }
      {
        assertion = config.adlerkopf.vmMode || !config.boot.loader.systemd-boot.enable;
        message = "adlerkopf: systemd-boot must be disabled on real host (lanzaboote replaces it)";
      }
      {
        assertion =
          config.adlerkopf.vmMode
          || builtins.any (
            d: d.directory == "/var/lib/sbctl"
          ) config.environment.persistence."/persist/system".directories;
        message = "adlerkopf: /var/lib/sbctl must be persisted (Secure Boot keys)";
      }
      {
        assertion =
          config.adlerkopf.vmMode
          || (
            config.boot.loader.systemd-boot.configurationLimit != null
            && config.boot.loader.systemd-boot.configurationLimit <= 5
          );
        message = "adlerkopf: ESP generation limit must be ≤5 (512 MiB ESP with lanzaboote UKIs)";
      }
    ];
  };
}
