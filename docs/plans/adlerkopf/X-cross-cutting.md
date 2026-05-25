# Phase X — Cross-cutting concerns

These items are not blocking for any single phase but should be completed before decommissioning
the Pi. They can be done as sub-tasks within each phase's PR or grouped into one final PR (PR-8).

## Restic backup

**Target**: NAS (SFTP) or another host. Confirm target before implementing. TBD.

```nix
# hosts/adlerkopf/services/backup.nix
{ config, lib, ... }: {
  sops.secrets = {
    "restic/repository-url"  = { owner = "root"; };
    "restic/password-file"   = { owner = "root"; };
    "restic/sftp-private-key" = { owner = "root"; mode = "0400"; };
  };

  services.restic.backups.adlerkopf-persist = {
    repository = "sftp://nas.lan/backups/adlerkopf";
    passwordFile = config.sops.secrets."restic/password-file".path;
    paths = [ "/persist/system" ];
    timerConfig = { OnCalendar = "04:00"; Persistent = true; };
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    extraBackupArgs = [ "--exclude=/persist/system/var/log" ];
  };
}
```

Pre-phase snapshot (btrfs, manual before each risky phase):

```fish
sudo btrfs subvolume snapshot /persist /persist/.snapshots/pre-phase-N-(date +%Y%m%d-%H%M)
```

## node_exporter (metrics)

```nix
# hosts/adlerkopf/services/monitoring.nix
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";   # or WireGuard IP if pulled externally
    enabledCollectors = [ "systemd" "processes" "filesystem" "cpu" "meminfo" "netdev" ];
  };
  # Only open 9100 if scraped by external Prometheus over WG; otherwise keep it localhost-only
}
```

Scrape target decision: external Prometheus (e.g. on another host) via WireGuard, or a local
Prometheus on adlerkopf scraping itself. Defer until a monitoring host is determined.

## Persistent journald

```nix
# In hosts/adlerkopf/default.nix (or a logging.nix):
services.journald.extraConfig = ''
  Storage=persistent
  SystemMaxUse=500M
  SystemKeepFree=1G
'';
```

`/var/log/journal` is on the `@log` btrfs subvolume (persisted, mounted at `/var/log`).
Already included in the impermanence list in Phase 1.

## Colmena registration

Register `adlerkopf` in the `colmenaHive` block (`flake.nix:393-422` currently empty):

```nix
colmenaHive = colmena.lib.makeHive {
  meta = { ... };   # existing meta block
  adlerkopf = {
    nixpkgs.system = "x86_64-linux";
    deployment = {
      targetHost = "192.168.168.15";
      targetUser = "dan";
      tags = [ "home-server" ];
    };
    imports = [ ./hosts/adlerkopf ];
  };
};
```

After this, `colmena apply --on @home-server` deploys all home-server nodes.
The `cda` alias (defined in workstation HM config) wraps `colmena apply`.

## Auto-updates (optional)

```nix
system.autoUpgrade = {
  enable = true;
  flake = "github:dkressner/nix-config#adlerkopf";   # or local path
  flags = [ "--update-input" "nixpkgs" ];
  dates = "Sun 03:00";
  allowReboot = false;   # set true only when confident about boot stability
};
```

Consider gating this behind a flag until the host has proven stable for 30 days.

## Pi decommission checklist

Before powering off the Pi, confirm all of the following:

- [ ] DNS: All LAN clients resolve via adlerkopf (`dig @192.168.168.15 google.com` from each device)
- [ ] VPN: WireGuard client connects; no route to old PiVPN endpoint
- [ ] MQTT: All sensors publishing to `192.168.168.15:1883`; Pi MQTT has zero active clients
- [ ] Node-RED: Flows running on adlerkopf; Pi Node-RED idling with no MQTT connections
- [ ] Grafana: All dashboards green on adlerkopf; Pi Grafana idling
- [ ] Backup: First restic snapshot completed successfully on adlerkopf
- [ ] Port-forwards on router updated: old PiVPN UDP 1194 removed, Pi SSH removed
- [ ] DHCP reservation: old Pi entry removed or IP reassigned

Once all items checked: `ssh pi@<pi-ip> sudo shutdown now`.
