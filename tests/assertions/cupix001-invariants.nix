# tests/assertions/cupix001-invariants.nix
# cupix001-specific NixOS module assertions — enforced at evaluation time via nix flake check
# Guarded by hostname to avoid failures on other hosts that import tests/assertions
{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.networking.hostName == "cupix001") {
    assertions = [
      {
        assertion = config.networking.firewall.enable;
        message = "cupix001: firewall must be enabled (public-facing server)";
      }
      {
        assertion = !config.networking.networkmanager.enable;
        message = "cupix001: NetworkManager must be disabled (server host)";
      }
      {
        assertion = config.sops.defaultSopsFile != null;
        message = "cupix001: sops.defaultSopsFile must be set (SOPS secrets configuration required)";
      }
      {
        assertion = config.disko.devices.disk ? vda;
        message = "cupix001: disko device 'vda' must be configured (disk layout required for btrfs subvolumes)";
      }
      {
        assertion = config.fileSystems."/persist".neededForBoot;
        message = "cupix001: /persist must have neededForBoot = true — sops-nix requires /persist before secrets decryption";
      }
      {
        assertion = config.fileSystems."/var/log".neededForBoot;
        message = "cupix001: /var/log must have neededForBoot = true — persistent logs require early mount";
      }
    ];
  };
}
