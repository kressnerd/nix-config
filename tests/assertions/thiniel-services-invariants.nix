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
      {
        assertion = config.virtualisation.podman.enable;
        message = "thiniel: Podman virtualisation must be enabled for container development";
      }
      {
        assertion = config.programs.hyprland.withUWSM;
        message = "programs.hyprland.withUWSM must be true for proper Hyprland session management via UWSM";
      }
      {
        assertion = config.home-manager.users.dan.wayland.windowManager.hyprland.systemd.enable;
        message = "Hyprland systemd integration must be enabled for session-target-dependent services (waybar)";
      }
      {
        assertion = config.services.smartd.enable;
        message = "thiniel: smartd must monitor the NVMe that carries root, /nix and /persist";
      }
      {
        assertion = !config.services.openssh.settings.PasswordAuthentication;
        message = "thiniel: SSH password authentication must stay disabled";
      }
      {
        assertion = !config.services.openssh.settings.KbdInteractiveAuthentication;
        message = "thiniel: SSH keyboard-interactive authentication must stay disabled";
      }
      {
        assertion = config.services.openssh.settings.PermitRootLogin == "no";
        message = "thiniel: root SSH login must stay disabled";
      }
      {
        assertion = builtins.length config.users.users.dan.openssh.authorizedKeys.keys > 0;
        message = "thiniel: dan needs at least one authorized SSH key because password authentication is disabled";
      }
      {
        assertion = !(config.virtualisation.oci-containers.containers ? qdrant_roo);
        message = "thiniel: the qdrant_roo OCI container was withdrawn and must not come back";
      }
      {
        assertion = config.services.gvfs.enable;
        message = "thiniel: services.gvfs.enable must be true for VS Code trash functionality and GLib file operations";
      }
    ];
  };
}
