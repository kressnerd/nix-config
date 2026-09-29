# tests/assertions/thiniel-boot-invariants.nix
# Thiniel boot/initrd invariants — enforced at evaluation time via nix flake check.
# Thiniel wipes its btrfs root subvolume from the initrd (impermanence). That wipe
# lives in `boot.initrd.postDeviceCommands`, which only exists in the scripted
# stage 1. nixpkgs 26.05 made the systemd stage 1 the default, so the scripted
# implementation must be selected explicitly until the wipe is migrated to
# `boot.initrd.systemd.services` (scheduled for removal in 26.11).
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = !config.boot.initrd.systemd.enable;
        message = "Thiniel invariant violated: boot.initrd.systemd.enable must be false — the btrfs root wipe relies on boot.initrd.postDeviceCommands, which the systemd stage 1 does not support";
      }
      {
        assertion = config.boot.initrd.postDeviceCommands != "";
        message = "Thiniel invariant violated: boot.initrd.postDeviceCommands must not be empty — impermanence wipes the btrfs root subvolume there";
      }
    ];
  };
}
