{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options = {
    adlerkopf.vmMode = mkOption {
      type = types.bool;
      default = false;
      description = "True when building the VM test image (disables hardware-specific assertions)";
    };
    networking.adlerkopf = {
      interfaceName = mkOption {
        type = types.str;
        default = "eno1";
        description = "Primary network interface (Intel I219-V; verify after first boot)";
      };
      lanIPv4 = mkOption {
        type = types.str;
        default = "192.168.168.15";
        description = "Static LAN IPv4 address";
      };
      lanPrefix = mkOption {
        type = types.int;
        default = 24;
        description = "LAN IPv4 prefix length";
      };
      gateway4 = mkOption {
        type = types.str;
        default = "192.168.168.1";
        description = "Default IPv4 gateway";
      };
      dns = mkOption {
        type = types.listOf types.str;
        default = [
          "1.1.1.1"
          "9.9.9.9"
        ];
        description = "DNS resolvers (replaced by 127.0.0.1 in Phase 2 after AdGuard Home)";
      };
      wgSubnet = mkOption {
        type = types.str;
        default = "10.100.0.0/24";
        description = "WireGuard VPN subnet (Phase 3)";
      };
      wgServerIPv4 = mkOption {
        type = types.str;
        default = "10.100.0.1";
        description = "Server WireGuard tunnel IP (Phase 3)";
      };
      wgListenPort = mkOption {
        type = types.port;
        default = 51820;
        description = "WireGuard UDP listen port (Phase 3)";
      };
    };
  };
}
