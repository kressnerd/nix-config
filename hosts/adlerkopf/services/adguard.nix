{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets."adguard/admin-bcrypt-hash" = {
    owner = "root";
    mode = "0400";
  };

  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    openFirewall = false;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = [
          "REDACTED-HOME-LAN-SUBNET"
          "127.0.0.1"
        ];
        port = 53;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://1.1.1.1/dns-query"
        ];
        bootstrap_dns = [
          "9.9.9.9"
          "1.1.1.1"
        ];
        cache_size = 67108864;
        enable_dnssec = true;
        refuse_any = true;
      };
      filtering.rewrites = [
        {
          domain = "adlerkopf.lan";
          answer = "REDACTED-HOME-LAN-SUBNET";
        }
        {
          domain = "grafana.lan";
          answer = "REDACTED-HOME-LAN-SUBNET";
        }
        {
          domain = "nodered.lan";
          answer = "REDACTED-HOME-LAN-SUBNET";
        }
        {
          domain = "mqtt.lan";
          answer = "REDACTED-HOME-LAN-SUBNET";
        }
        {
          domain = "vpn.lan";
          answer = "REDACTED-HOME-LAN-SUBNET";
        }
      ];
      filters = [
        {
          enabled = true;
          id = 1;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
        {
          enabled = true;
          id = 2;
          name = "Dan Pollock hosts";
          url = "https://someonewhocares.org/hosts/zero/hosts";
        }
        {
          enabled = true;
          id = 3;
          name = "URLhaus";
          url = "https://urlhaus.abuse.ch/downloads/hostfile/";
        }
      ];
    };
  };

  # Inject admin password hash from sops secret into AdGuardHome.yaml before service starts.
  # The adguardhome module's own preStart writes the YAML from settings;
  # mkAfter ensures our patch runs after that.
  systemd.services.adguardhome.preStart = lib.mkAfter ''
    HASH=$(cat ${config.sops.secrets."adguard/admin-bcrypt-hash".path})
    ${pkgs.yq-go}/bin/yq -i '.users = [{"name": "admin", "password": "'"$HASH"'"}]' \
      /var/lib/AdGuardHome/AdGuardHome.yaml
  '';

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
    interfaces."eno1".allowedTCPPorts = [ 3000 ];
  };
}
