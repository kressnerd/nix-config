# Phase 2 — AdGuard Home (DNS resolver)

**Goal**: Replace Pi-hole on the old Pi with AdGuard Home running on adlerkopf.
LAN clients resolve DNS via `REDACTED-HOME-LAN-SUBNET`. Blocking works. Internal `.lan` A-records resolve.

## Files

| File | Action |
|---|---|
| `hosts/adlerkopf/services/adguard.nix` | create — import in `default.nix` |
| `hosts/adlerkopf/impermanence.nix` | extend — add `/var/lib/private/AdGuardHome` |
| `hosts/adlerkopf/secrets.yaml` | extend — add `adguard/admin-bcrypt-hash` |
| `tests/assertions/adlerkopf-invariants.nix` | extend — AdGuard enabled + port 53 open |

## Module skeleton

```nix
# hosts/adlerkopf/services/adguard.nix
{ config, lib, ... }: {
  sops.secrets."adguard/admin-bcrypt-hash" = {
    owner = "root";
    mode = "0400";
  };

  services.adguardhome = {
    enable = true;
    mutableSettings = false;    # fully declarative; runtime changes discarded on restart
    openFirewall = false;       # manage ports explicitly
    settings = {
      bind_host = "0.0.0.0";   # web UI; lock to LAN once behind Caddy
      bind_port = 3000;
      dns = {
        bind_hosts = [ "REDACTED-HOME-LAN-SUBNET" "127.0.0.1" ];
        port = 53;
        upstream_dns = [
          "https://dns.quad9.net/dns-query"
          "https://1.1.1.1/dns-query"
        ];
        bootstrap_dns = [ "9.9.9.9" "1.1.1.1" ];
        cache_size = 67108864;     # 64 MiB
        enable_dnssec = true;
        refuse_any = true;
      };
      filtering.rewrites = [
        { domain = "adlerkopf.lan"; answer = "REDACTED-HOME-LAN-SUBNET"; }
        { domain = "grafana.lan";   answer = "REDACTED-HOME-LAN-SUBNET"; }
        { domain = "nodered.lan";   answer = "REDACTED-HOME-LAN-SUBNET"; }
        { domain = "mqtt.lan";      answer = "REDACTED-HOME-LAN-SUBNET"; }
        { domain = "vpn.lan";       answer = "REDACTED-HOME-LAN-SUBNET"; }
      ];
      filters = [
        { enabled = true; id = 1; name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"; }
        { enabled = true; id = 2; name = "Dan Pollock hosts";
          url = "https://someonewhocares.org/hosts/zero/hosts"; }
        { enabled = true; id = 3; name = "URLhaus";
          url = "https://urlhaus.abuse.ch/downloads/hostfile/"; }
      ];
      # Admin password injected via sops.templates into config overlay
      # See note on password injection below
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
    # Port 3000 (web UI) intentionally NOT opened on WAN — access via LAN only until Caddy vhost added
    interfaces."eno1".allowedTCPPorts = [ 3000 ];
  };
}
```

### Admin password injection

`services.adguardhome` with `mutableSettings = false` writes the full settings YAML from Nix.
The `users` field expects a bcrypt hash. Two approaches:

**Option A (recommended)**: Generate bcrypt once, store hash in sops, inject via `sops.templates`
into a settings-override file that AdGuard merges at startup (if the module supports it) — or,
more simply, include the hash directly in the Nix settings after retrieving it from sops via
a `home.activation`-style one-shot. Practical approach:

```fish
# Generate hash (run once on workstation):
nix-shell -p apacheHttpd --run 'htpasswd -bnBC 10 "" "mypassword" | tr -d ":\n"'
# → $2y$10$...  — store in secrets.yaml under adguard/admin-bcrypt-hash
```

Then use `sops.templates` to write a partial settings override. **If `mutableSettings = false`
writes the entire file, include the hash inline in the module** guarded by a `sops.placeholder`:

```nix
sops.templates."adguardhome-users.json" = {
  owner = "root";
  path = "/run/adguardhome-users.json";     # tempfile, merged by activation script
  content = builtins.toJSON [{
    name = "admin";
    password = config.sops.placeholder."adguard/admin-bcrypt-hash";
  }];
};
```

Activation script merges it into the AdGuardHome.yaml before the service starts.
Verify the exact knob with the nixpkgs `services.adguardhome.settings` module source before implementing.

## Impermanence extension

```nix
# in hosts/adlerkopf/impermanence.nix — append to directories list:
"/var/lib/private/AdGuardHome"   # AdGuard stores its runtime config + query log here
```

## Migration from Pi-hole

Pi-hole's "Teleporter" export format is **not compatible** with AdGuard Home.
Manual translation required:

1. In Pi-hole admin → **Local DNS → DNS Records**: export or screenshot all A-records.
   Add each as a `filtering.rewrites` entry in the Nix module.
2. In Pi-hole admin → **Blacklist/Whitelist**: copy any custom regex patterns to `user_rules`.
3. Block statistics and query log from Pi-hole: non-migrated (accept clean slate).

## Router DHCP change (manual step, after acceptance)

Change the **primary DNS server** in the router's DHCP settings from the Pi's IP to
`REDACTED-HOME-LAN-SUBNET`. This is the DNS cut-over. Keep Pi-hole running until smoke-test passes.

## New assertions

```nix
{ assertion = config.services.adguardhome.enable; message = "adlerkopf: AdGuard Home must be enabled"; }
{ assertion = elem 53 config.networking.firewall.allowedTCPPorts; message = "adlerkopf: port 53/tcp open"; }
{ assertion = elem 53 config.networking.firewall.allowedUDPPorts; message = "adlerkopf: port 53/udp open"; }
```

## Acceptance criteria

- [x] `nix flake check --no-build` green
- [ ] `dig @REDACTED-HOME-LAN-SUBNET doubleclick.net` → blocked (NXDOMAIN or 0.0.0.0)
- [ ] `dig @REDACTED-HOME-LAN-SUBNET google.com` → real answer (upstream DoH resolves)
- [ ] `dig @REDACTED-HOME-LAN-SUBNET grafana.lan` → REDACTED-HOME-LAN-SUBNET (rewrite works)
- [ ] AdGuard web UI reachable at `http://REDACTED-HOME-LAN-SUBNET:3000`
- [ ] After router DHCP DNS change: a LAN client resolves `grafana.lan` without manual DNS override
- [ ] AdGuard state survives a reboot (query log, custom rewrites intact)

## Completion Summary

- **Completed Date**: 2026-05-28
- **Status**: IMPLEMENTATION COMPLETE (pre-deployment)
- **Commits**:
  - `6108209` — `test(adlerkopf): RED — add AdGuard Home assertions`
  - `744bd1b` — `feat(adlerkopf): GREEN — add AdGuard Home service module`
  - `5a88ded` — `refactor(adlerkopf): address review findings F-001/F-002/F-003`
- **Deviations from plan**:
  - `settings.bind_host` / `settings.bind_port` deprecated in current nixpkgs → replaced with top-level `services.adguardhome.host` / `services.adguardhome.port`
  - Plan specified `sops.templates` for password injection → implemented via `systemd.services.adguardhome.preStart` with `lib.mkAfter` + `yq-go` (simpler, no extra template file needed)
  - Hardcoded IP `REDACTED-HOME-LAN-SUBNET` replaced with `config.networking.adlerkopf.lanIPv4` option reference (DRY improvement from review)
  - Service file placed in `hosts/adlerkopf/services/adguard.nix` as planned (introduces new `services/` subdirectory pattern)
- **Remaining before deployment**:
  - Add bcrypt hash to `hosts/adlerkopf/secrets.yaml` via `sops hosts/adlerkopf/secrets.yaml` under key `adguard/admin-bcrypt-hash`
  - Deploy: `sudo nixos-rebuild switch --flake .#adlerkopf`
  - Verify acceptance criteria (dig tests, web UI, router DHCP change)
  - Update `private.nix` to set system DNS to `127.0.0.1` (F-005 follow-up)

## Rollback

```fish
# Disable AdGuard, revert router DHCP DNS to Pi's IP — takes effect on next DHCP lease renewal
nixos-rebuild switch --flake .#adlerkopf --target-host dan@REDACTED-HOME-LAN-SUBNET
# (with services.adguardhome.enable = false + port 53 closed)
```
