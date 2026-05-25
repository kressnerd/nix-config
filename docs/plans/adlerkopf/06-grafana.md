# Phase 6 — Grafana + declarative provisioning

**Goal**: Declare Grafana on adlerkopf. Dashboards and datasources are provisioned
declaratively from Nix/JSON. Editor reachable at `https://grafana.lan` via Caddy.

## Files

| File | Action |
|---|---|
| `hosts/adlerkopf/services/grafana.nix` | create — import in `default.nix` |
| `hosts/adlerkopf/caddy.nix` | extend — `grafana.lan` vhost |
| `hosts/adlerkopf/impermanence.nix` | extend — `/var/lib/grafana` |
| `hosts/adlerkopf/secrets.yaml` | extend — `grafana/admin-password` + datasource credentials |
| `hosts/adlerkopf/dashboards/` | create — committed dashboard JSON files |
| `tests/assertions/adlerkopf-invariants.nix` | extend — Grafana enabled + Caddy vhost |

## Migration strategy decision

**Recommended: declarative provisioning (no DB copy)**

Export each dashboard JSON from the Pi's Grafana UI (Dashboard → Share → Export → Save to file).
Commit them under `hosts/adlerkopf/dashboards/`. Grafana's `provision.dashboards` imports them
on startup. Skip copying `grafana.db` — avoids schema upgrade risk (Pi likely on 9.x, NixOS 25.11
ships 10.x or 11.x).

**Fallback (if dashboard recreation is too costly)**:
Copy `grafana.db` from Pi. Verify Grafana version on Pi first:

```fish
ssh pi@<pi-ip> grafana-server -version
```

If major version differs, run Grafana interactively once with the old DB to trigger auto-migration,
then verify in the UI before production cut-over. Document `grafana-cli admin reset-admin-password`
as recovery in case of login issues post-migration.

## Module skeleton

```nix
# hosts/adlerkopf/services/grafana.nix
{ config, lib, pkgs, ... }: {
  sops.secrets."grafana/admin-password" = {
    owner = "grafana";
    mode = "0400";
    restartUnits = [ "grafana.service" ];
  };

  services.grafana = {
    enable = true;
    dataDir = "/var/lib/grafana";

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        domain = "grafana.lan";
        root_url = "https://grafana.lan/";
        serve_from_sub_path = false;
      };
      database = {
        type = "sqlite3";
        path = "/var/lib/grafana/grafana.db";
      };
      security = {
        # $__file{} reads the secret from a file at runtime — sops-nix standard pattern
        admin_password = "$__file{${config.sops.secrets."grafana/admin-password".path}}";
        admin_user = "dan";
        disable_gravatar = true;
      };
      analytics.reporting_enabled = false;
    };

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Local Mosquitto";
          type = "grafana-mqtt-datasource";
          url = "tcp://192.168.168.15:1883";
          jsonData = { subscriptionQos = 0; };
          # secureJsonData.password injected separately if broker requires auth
        }
        # Add Prometheus, InfluxDB etc. here as needed
      ];

      dashboards.settings.providers = [
        {
          name = "adlerkopf";
          options.path = "${./dashboards}";   # committed JSON files
          allowUiUpdates = false;
        }
      ];
    };
  };

  # Port 3000 localhost only — not opened in firewall (Caddy proxies it)
}
```

## Caddy vhost extension

```nix
# in hosts/adlerkopf/caddy.nix — add to virtualHosts:
services.caddy.virtualHosts."grafana.lan" = {
  extraConfig = ''
    tls {
      dns netcup {
        customer_number {env.NETCUP_CUSTOMER_NUMBER}
        api_key         {env.NETCUP_API_KEY}
        api_password    {env.NETCUP_API_PASSWORD}
      }
    }
    reverse_proxy 127.0.0.1:3000
  '';
};
```

## Impermanence extension

```nix
"/var/lib/grafana"   # SQLite DB, alert state, rendered images
```

## Dashboards directory

```
hosts/adlerkopf/dashboards/
├── home-sensors.json       # exported from Pi Grafana
├── mqtt-overview.json
└── ...
```

Each file is a standard Grafana dashboard JSON (exported with `{uid: "...", ...}` preserved).
Grafana's provisioner imports them on startup; `allowUiUpdates = false` prevents dashboard drift.

## Pi data migration (if declarative provisioning)

1. In Pi Grafana: **Dashboards → Share → Export → Save JSON** — one file per dashboard
2. Commit to `hosts/adlerkopf/dashboards/`
3. Datasources: no migration needed — declared in Nix module
4. Alerts: re-create in provisioning YAML if any critical ones exist on the Pi

## New assertions

```nix
{ assertion = config.services.grafana.enable; message = "adlerkopf: Grafana must be enabled"; }
{ assertion = config.services.caddy.virtualHosts ? "grafana.lan"; message = "adlerkopf: Caddy vhost grafana.lan must exist"; }
{ assertion = config.services.grafana.settings.server.http_addr == "127.0.0.1"; message = "adlerkopf: Grafana must only bind localhost"; }
```

## Acceptance criteria

- [ ] `nix flake check --no-build` green
- [ ] `systemctl status grafana` → active
- [ ] `curl -fsSI https://grafana.lan` → 200, valid LE cert
- [ ] Login with `dan` + admin password from sops
- [ ] Provisioned dashboards appear in the UI and display panel data
- [ ] `Local Mosquitto` datasource status → OK (if broker running)
- [ ] Port 3000 not directly reachable from LAN
- [ ] State (`grafana.db`) survives a reboot

## Rollback

```fish
nixos-rebuild switch --flake .#adlerkopf --target-host dan@192.168.168.15
# (with services.grafana.enable = false + caddy vhost removed)
```

Pi Grafana remains live until all dashboards are verified on adlerkopf.
