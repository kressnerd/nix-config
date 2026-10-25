# tests/assertions/thiniel-boot-invariants.nix
# Thiniel boot/initrd invariants — enforced at evaluation time via nix flake check.
# Thiniel wipes its btrfs root subvolume from the initrd (impermanence). The systemd
# stage 1 is the only stage 1 left, so the wipe is a systemd oneshot that must run once
# the root device is available and before the root is mounted.
{ config, lib, ... }:
let
  rollback = config.boot.initrd.systemd.services.rollback or null;
in
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
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
