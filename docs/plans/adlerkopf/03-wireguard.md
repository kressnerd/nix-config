# Phase 3 — WireGuard (VPN server)

**Goal**: Replace the PiVPN/OpenVPN server on the Pi with a WireGuard server on adlerkopf.
Clients connect from the internet, reach the LAN, and resolve DNS via AdGuard Home.

New PKI, new client configs — no migration of PiVPN certs.

## Files

| File | Action |
|---|---|
| `hosts/adlerkopf/services/wireguard.nix` | create — import in `default.nix` |
| `hosts/adlerkopf/impermanence.nix` | extend — add `/var/lib/wireguard` if WG stores anything there |
| `hosts/adlerkopf/secrets.yaml` | extend — add `wireguard/server-private-key` |
| `tests/assertions/adlerkopf-invariants.nix` | extend — WG interface + port open + IP forward |

## Key generation (one-off, before committing config)

```fish
# Generate server keypair (run on workstation or adlerkopf):
wg genkey | tee /tmp/wg-server.key | wg pubkey > /tmp/wg-server.pub
# Add private key to sops:
sops hosts/adlerkopf/secrets.yaml
# → add: wireguard/server-private-key: <paste private key>
# Keep public key in the module in plaintext (public information)

# Per client:
wg genkey | tee /tmp/wg-<name>.key | wg pubkey > /tmp/wg-<name>.pub
```

## Module skeleton

```nix
# hosts/adlerkopf/services/wireguard.nix
{ config, lib, ... }: let
  listenPort = 51820;
  wgIface = "wg0";
  serverIP = "10.100.0.1";
  subnet = "10.100.0.0/24";
in {
  sops.secrets."wireguard/server-private-key" = {
    owner = "root";
    mode = "0400";
  };

  networking.wireguard.interfaces.${wgIface} = {
    ips = [ "${serverIP}/24" ];
    inherit listenPort;
    privateKeyFile = config.sops.secrets."wireguard/server-private-key".path;

    # Add one entry per client:
    peers = [
      {
        publicKey = "<phone-public-key>";
        allowedIPs = [ "10.100.0.10/32" ];
      }
      {
        publicKey = "<laptop-public-key>";
        allowedIPs = [ "10.100.0.20/32" ];
      }
    ];
  };

  # IP forwarding required for client → LAN traffic
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # NAT: masquerade WG subnet toward LAN
  networking.nat = {
    enable = true;
    externalInterface = "eno1";        # verify NIC name after first boot
    internalInterfaces = [ wgIface ];
    internalIPs = [ subnet ];
  };

  networking.firewall.allowedUDPPorts = [ listenPort ];
}
```

## Client config template

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.100.0.10/24
DNS = 192.168.168.15    # AdGuard Home via tunnel

[Peer]
PublicKey = <server-public-key>
Endpoint = <adlerkopf-public-ip>:51820
AllowedIPs = 0.0.0.0/0, ::/0     # full tunnel; use 10.100.0.0/24,192.168.168.0/24 for split
PersistentKeepalive = 25
```

Distribute via 1Password or QR code (qrencode). **Never commit client private keys**.

## Router change (manual step, after acceptance)

1. Add port-forward: UDP `51820` WAN → `192.168.168.15:51820`
2. Remove old OpenVPN port-forward (UDP `1194`) once the new WG endpoint is smoke-tested

## New assertions

```nix
{ assertion = config.networking.wireguard.interfaces ? wg0; message = "adlerkopf: wg0 interface must exist"; }
{ assertion = config.boot.kernel.sysctl."net.ipv4.ip_forward" == 1; message = "adlerkopf: IP forwarding must be enabled"; }
{ assertion = elem 51820 config.networking.firewall.allowedUDPPorts; message = "adlerkopf: WG port 51820/udp open"; }
```

## Acceptance criteria

- [ ] `nix flake check --no-build` green
- [ ] `sudo wg show wg0` shows server listening on UDP 51820 with peer entries
- [ ] One peer connects from outside the LAN (e.g. phone on mobile data)
- [ ] Peer pings `192.168.168.1` (LAN gateway) via tunnel
- [ ] Peer resolves `grafana.lan` → 192.168.168.15 (AdGuard via tunnel DNS)
- [ ] Peer reaches the internet (NAT masquerade working)
- [ ] No port 51820 leakage on `lo` or non-WAN interfaces

## Rollback

```fish
# Disable WG interface:
nixos-rebuild switch --flake .#adlerkopf --target-host dan@192.168.168.15
# (with networking.wireguard.interfaces = {} + UDP 51820 closed)
# Revert router port-forward to old PiVPN IP
```

Old PiVPN remains accessible at the old endpoint until router port-forward is removed.
