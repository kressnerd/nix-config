# tests/assertions/host-invariants.nix
# NixOS module assertions — enforced at evaluation time via nix flake check
{ config, ... }:
{
  config = {
    assertions = [
      {
        assertion = config.networking.hostName != "localhost" && config.networking.hostName != "";
        message = "Host invariant violated: networking.hostName must not be 'localhost' or empty";
      }
      {
        assertion = config.networking.firewall.enable;
        message = "Host invariant violated: networking.firewall must be enabled";
      }
      {
        assertion =
          !config.services.openssh.enable || config.services.openssh.settings.PermitRootLogin != "yes";
        message = "Host invariant violated: SSH root login must not be 'yes' when OpenSSH is enabled";
      }
    ];
  };
}
