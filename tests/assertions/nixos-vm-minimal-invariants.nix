# tests/assertions/nixos-vm-minimal-invariants.nix
# nixos-vm-minimal-specific assertions — enforced at evaluation time via nix flake check
# Characterizes SSH hardening from hosts/nixos-vm-minimal/default.nix
{ config, lib, ... }:
{
  config = lib.mkIf (config.networking.hostName == "nixos-vm-minimal") {
    assertions = [
      {
        assertion = !config.services.openssh.settings.PasswordAuthentication;
        message = "nixos-vm-minimal invariant violated: SSH PasswordAuthentication must be false";
      }
      {
        assertion = !config.services.openssh.settings.KbdInteractiveAuthentication;
        message = "nixos-vm-minimal invariant violated: SSH KbdInteractiveAuthentication must be false";
      }
      {
        assertion = config.services.openssh.settings.PermitRootLogin == "no";
        message = "nixos-vm-minimal invariant violated: SSH PermitRootLogin must be no";
      }
      {
        assertion = !config.security.sudo.wheelNeedsPassword;
        message = "nixos-vm-minimal invariant violated: wheel group must not require sudo password";
      }
      {
        assertion = config.nix.gc.automatic;
        message = "nixos-vm-minimal invariant violated: nix.gc.automatic must be true";
      }
    ];
  };
}
