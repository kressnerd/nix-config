# tests/assertions/thiniel-boot-invariants.nix
# Thiniel boot/initrd invariants — enforced at evaluation time via nix flake check.
# Thiniel wipes its btrfs root subvolume from the initrd (impermanence). nixpkgs 26.05
# made the systemd-based stage 1 the default and the scripted stage 1 is removed in
# 26.11, so the wipe is a systemd oneshot that must run once the root device is available
# and before the root is mounted. `boot.initrd.postDeviceCommands` still exists but is
# ignored by the systemd stage 1, hence it must stay empty.
{ config, lib, ... }:
let
  rollback = config.boot.initrd.systemd.services.rollback or null;
in
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "Thiniel invariant violated: boot.initrd.systemd.enable must be true — the scripted stage 1 is deprecated and removed in 26.11";
      }
      {
        assertion = config.boot.initrd.postDeviceCommands == "";
        message = "Thiniel invariant violated: boot.initrd.postDeviceCommands must be empty — the systemd stage 1 ignores it; the btrfs root wipe runs as boot.initrd.systemd.services.rollback instead";
      }
      {
        assertion = rollback != null;
        message = "Thiniel invariant violated: boot.initrd.systemd.services.rollback must be defined — it wipes the btrfs root subvolume (impermanence)";
      }
      {
        assertion = rollback != null -> builtins.elem "initrd.target" rollback.requiredBy;
        message = "Thiniel invariant violated: the rollback service must be requiredBy initrd.target — with unitConfig.DefaultDependencies = \"no\" it would otherwise never be scheduled and the root would not be wiped";
      }
      {
        assertion = rollback != null -> builtins.elem "sysroot.mount" rollback.before;
        message = "Thiniel invariant violated: the rollback service must run before sysroot.mount so the freshly wiped root is what gets mounted";
      }
      {
        assertion = rollback != null -> builtins.elem "initrd-root-device.target" rollback.requires;
        message = "Thiniel invariant violated: the rollback service must require initrd-root-device.target so the LVM root device is active before it runs";
      }
      {
        assertion = rollback != null -> builtins.elem "initrd-root-device.target" rollback.after;
        message = "Thiniel invariant violated: the rollback service must be ordered after initrd-root-device.target so the LVM root device is active before the wipe runs";
      }
    ];
  };
}
