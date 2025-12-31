# Simplified firewall for VM testing
{
  config,
  lib,
  ...
}: {
  networking.firewall = {
    enable = true;

    # Allow SSH, HTTP, HTTPS
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP (ACME challenges)
      443 # HTTPS
    ];

    # Headscale DERP/STUN
    allowedUDPPorts = [
      3478 # STUN
    ];

    # Log refused connections for debugging
    logRefusedConnections = true;
  };
}
