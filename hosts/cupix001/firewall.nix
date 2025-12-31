{
  config,
  lib,
  ...
}: {
  networking.firewall = {
    enable = true;

    # Allow SSH
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP (ACME challenges)
      443 # HTTPS
    ];

    # Headscale DERP/STUN
    allowedUDPPorts = [
      3478 # STUN
    ];

    # Log refused connections
    logRefusedConnections = true;
    logRefusedPackets = false;

    # Reject instead of drop for better UX
    rejectPackets = false;

    # Extra configuration
    extraCommands = ''
      # Rate limit SSH connections
      iptables -A nixos-fw -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH
      iptables -A nixos-fw -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

      # Allow established connections
      iptables -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # Enable nftables for better performance (optional, but recommended)
  networking.nftables.enable = lib.mkDefault false; # Keep iptables for now
}
