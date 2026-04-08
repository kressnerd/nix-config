# tests/assertions/thiniel-services-invariants.nix
# Thiniel-specific service assertions — enforced at evaluation time via nix flake check
# Characterizes services from hosts/thiniel/default.nix
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "thiniel") {
    assertions = [
      {
        assertion = config.services.btrfs.autoScrub.enable;
        message = "Thiniel invariant violated: services.btrfs.autoScrub.enable must be true (data integrity)";
      }
      {
        assertion = config.services.btrfs.autoScrub.interval == "weekly";
        message = "Thiniel invariant violated: services.btrfs.autoScrub.interval must be weekly";
      }
      {
        assertion = config.services.thermald.enable;
        message = "Thiniel invariant violated: services.thermald.enable must be true (ThinkPad thermal management)";
      }
      {
        assertion = config.services.auto-cpufreq.enable;
        message = "Thiniel invariant violated: services.auto-cpufreq.enable must be true";
      }
      {
        assertion = config.services.pipewire.enable;
        message = "Thiniel invariant violated: services.pipewire.enable must be true (audio)";
      }
      {
        assertion = config.services.pipewire.pulse.enable;
        message = "Thiniel invariant violated: services.pipewire.pulse.enable must be true (PulseAudio compat)";
      }
      {
        assertion = config.services.openssh.enable;
        message = "Thiniel invariant violated: services.openssh.enable must be true";
      }
      {
        assertion = config.programs.fuse.userAllowOther;
        message = "Thiniel invariant violated: programs.fuse.userAllowOther must be true (required for impermanence bind mounts)";
      }
      {
        assertion = config.virtualisation.libvirtd.enable;
        message = "Thiniel invariant violated: virtualisation.libvirtd.enable must be true (VM support)";
      }
    ];
  };
}
