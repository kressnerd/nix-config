{ config, ... }:
let
  cfg = config.networking.adlerkopf;
in
{
  networking = {
    useDHCP = false;
    useNetworkd = true;
    nftables.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    networkmanager.enable = false;
  };

  systemd.network.networks."10-lan" = {
    matchConfig.Name = cfg.interfaceName;
    address = [ "${cfg.lanIPv4}/${toString cfg.lanPrefix}" ];
    gateway = [ cfg.gateway4 ];
    inherit (cfg) dns;
    DHCP = "no";
  };
}
