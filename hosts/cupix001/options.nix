{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.networking.cupix001 = {
    publicIPv4 = mkOption {
      type = types.str;
      default = "";
      description = "Public IPv4 address of the VPS";
    };

    publicIPv6 = mkOption {
      type = types.str;
      default = "";
      description = "Public IPv6 address of the VPS";
    };

    prefixLengthV4 = mkOption {
      type = types.int;
      default = 24;
      description = "IPv4 prefix length (e.g. 22)";
    };

    prefixLengthV6 = mkOption {
      type = types.int;
      default = 64;
      description = "IPv6 prefix length";
    };

    gateway4 = mkOption {
      type = types.str;
      default = "";
      description = "Default IPv4 gateway";
    };

    gateway6 = mkOption {
      type = types.str;
      default = "";
      description = "Default IPv6 gateway";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "DNS resolver IPs";
    };

    wgListenPort = mkOption {
      type = types.port;
      default = 51820;
      description = "WireGuard listen port";
    };

    wgTunnelIPv4 = mkOption {
      type = types.str;
      default = "";
      description = "WireGuard tunnel IPv4 address for this host";
    };

    wgPeerTunnelIPv4 = mkOption {
      type = types.str;
      default = "";
      description = "WireGuard tunnel IPv4 address of the homelab peer";
    };

    enablePublicSSH = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSH on the public interface (for bootstrap; disable after WireGuard is verified)";
    };

    sshBootstrapPort = mkOption {
      type = types.port;
      default = 22;
      description = "SSH port on the public interface during bootstrap";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "ens3";
      description = "Primary network interface name (gather via 'ip -br link' on the VPS)";
    };
  };
}
