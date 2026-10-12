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
        default = "192.0.2.10";
        description = "Static LAN IPv4 address (documentation-range placeholder; the real value comes from the private flake input)";
      };
      lanPrefix = mkOption {
        type = types.int;
        default = 24;
        description = "LAN IPv4 prefix length";
      };
      gateway4 = mkOption {
        type = types.str;
        default = "192.0.2.1";
        description = "Default IPv4 gateway (documentation-range placeholder; the real value comes from the private flake input)";
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
        default = "10.0.0.0/24";
        description = "WireGuard VPN subnet (generic placeholder; the real value comes from the private flake input)";
      };
      wgServerIPv4 = mkOption {
        type = types.str;
        default = "10.0.0.1";
        description = "Server WireGuard tunnel IP (generic placeholder; the real value comes from the private flake input)";
      };
      wgListenPort = mkOption {
        type = types.port;
        default = 51820;
        description = "WireGuard UDP listen port (Phase 3)";
      };
    };
  };
}
