# Phase 5 — Node-RED + first Caddy vhost + LE DNS-01

**Goal**: Declare Node-RED on adlerkopf. Existing flows and credentials from the Pi are migrated.
Editor is reachable at `https://nodered.lan` via Caddy with a valid Let's Encrypt certificate
issued via Netcup DNS-01 challenge.

This phase activates the first real Caddy virtualHost and wires up ACME globals.

## Files

| File | Action |
|---|---|
| `hosts/adlerkopf/services/node-red.nix` | create — import in `default.nix` |
| `hosts/adlerkopf/caddy.nix` | extend — ACME globals + `nodered.lan` vhost |
| `hosts/adlerkopf/impermanence.nix` | extend — `/var/lib/node-red` |
| `hosts/adlerkopf/secrets.yaml` | extend — `nodered/credential-secret`, `nodered/admin-password-hash`, netcup Caddy credentials |
| `tests/assertions/adlerkopf-invariants.nix` | extend — node-red enabled, 1880 not on WAN, Caddy vhost present |

## Pre-requisite: extract credential secret from Pi

**Before retiring the Pi**, retrieve the `credentialSecret` from the old Node-RED:

```fish
ssh pi@<pi-ip> grep credentialSecret ~/.node-red/settings.js
# → credentialSecret: "someSecretValue",
```

Store this value in sops as `nodered/credential-secret` **before** migrating `flows_cred.json`.
If the secret changes, `flows_cred.json` becomes undecryptable and flows must be re-entered manually.

## Module skeleton

```nix
# hosts/adlerkopf/services/node-red.nix
{ config, lib, ... }: {
  sops.secrets = {
    "nodered/admin-password-hash" = { owner = "node-red"; mode = "0400"; };
    "nodered/credential-secret"   = { owner = "node-red"; mode = "0400"; };
  };

  services.node-red = {
    enable = true;
    port = 1880;
    openFirewall = false;    # exposed only via Caddy reverse proxy
    userDir = "/var/lib/node-red";
    withNpmAndGcc = true;    # required for palettes that include native modules
  };

  # Inject credential secret into Node-RED environment
  systemd.services.node-red.serviceConfig.EnvironmentFile =
    config.sops.secrets."nodered/credential-secret".path;

  # settings.js with admin auth — shipped via sops template
  sops.templates."node-red-settings.js" = {
    owner = "node-red";
    path = "/var/lib/node-red/settings.js";
    content = ''
      module.exports = {
        credentialSecret: process.env.NODERED_CREDENTIAL_SECRET,
        adminAuth: {
          type: "credentials",
          users: [{
            username: "dan",
            password: "${config.sops.placeholder."nodered/admin-password-hash"}",
            permissions: "*"
          }]
        },
        httpAdminRoot: "/",
        ui: { path: "/ui" },
        logging: { console: { level: "info", metrics: false, audit: false } }
      };
    '';
  };

  # Port 1880 reachable from localhost only (Caddy proxy)
  # No explicit firewall rule needed — default policy is deny
}
```

Admin password hash (bcrypt):

```fish
nix-shell -p apacheHttpd --run 'htpasswd -bnBC 10 "" "mypassword" | tr -d ":\n"'
# → $2y$10$... — store in secrets.yaml as nodered/admin-password-hash
```

## Caddy ACME globals + vhost (`hosts/adlerkopf/caddy.nix`)

```nix
{ config, lib, ... }: {
  # Netcup credentials from sops (same pattern as cupix001/07-caddy.md)
  sops.secrets = {
    "caddy/netcup-api-key"         = { owner = "caddy"; };
    "caddy/netcup-api-password"    = { owner = "caddy"; };
    "caddy/netcup-customer-number" = { owner = "caddy"; };
  };

  systemd.services.caddy.serviceConfig.EnvironmentFile = [
    config.sops.secrets."caddy/netcup-api-key".path
    config.sops.secrets."caddy/netcup-api-password".path
    config.sops.secrets."caddy/netcup-customer-number".path
  ];

  services.caddy = {
    enable = true;
    # package = ... (already declared in Phase 1 caddy.nix)

    globalConfig = ''
      email dan@example.com
      # Use staging during initial setup, switch to prod once cert validates:
      # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
    '';

    virtualHosts."nodered.lan" = {
      extraConfig = ''
        tls {
          dns netcup {
            customer_number {env.NETCUP_CUSTOMER_NUMBER}
            api_key        {env.NETCUP_API_KEY}
            api_password   {env.NETCUP_API_PASSWORD}
          }
        }
        reverse_proxy 127.0.0.1:1880
      '';
    };
  };

  # Open HTTPS on all interfaces; HTTP redirect handled by Caddy
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

Sops secret key names for Caddy env:
- `NETCUP_CUSTOMER_NUMBER` → `caddy/netcup-customer-number`
- `NETCUP_API_KEY` → `caddy/netcup-api-key`
- `NETCUP_API_PASSWORD` → `caddy/netcup-api-password`

Use LE **staging** URL first. Once `curl -fsSI https://nodered.lan` returns 200 with a staging
cert, switch to the production ACME URL and rebuild.

## Pi migration

```fish
# On the Pi (stop Node-RED first to flush state):
ssh pi@<pi-ip> sudo systemctl stop nodered

# Copy flow files to adlerkopf:
scp pi@<pi-ip>:~/.node-red/flows.json \
    pi@<pi-ip>:~/.node-red/flows_cred.json \
    pi@<pi-ip>:~/.node-red/package.json \
    dan@192.168.168.15:/persist/system/var/lib/node-red/

# Fix ownership:
ssh dan@192.168.168.15 sudo chown -R node-red:node-red /persist/system/var/lib/node-red/
```

Installed palette packages: on first start, Node-RED reads `package.json` and installs
missing modules if `withNpmAndGcc = true`. Alternatively list them explicitly:

```nix
# Not yet a formal NixOS option; use postStart or activation script
systemd.services.node-red.postStart = ''
  cd /var/lib/node-red
  npm install --prefix . node-red-dashboard node-red-contrib-mqtt-broker 2>&1 | systemd-cat
'';
```

## Impermanence extension

```nix
"/var/lib/node-red"    # flows, credentials, installed palettes, settings.js
```

## New assertions

```nix
{ assertion = config.services.node-red.enable; message = "adlerkopf: Node-RED must be enabled"; }
{ assertion = config.services.caddy.virtualHosts ? "nodered.lan"; message = "adlerkopf: Caddy vhost nodered.lan must be configured"; }
{ assertion = elem 443 config.networking.firewall.allowedTCPPorts; message = "adlerkopf: HTTPS port 443 open"; }
```

## Acceptance criteria

- [ ] `nix flake check --no-build` green
- [ ] `systemctl status node-red caddy` → both active
- [ ] `curl -fsSI https://nodered.lan` → 200, valid LE cert (prod after staging passes)
- [ ] Node-RED editor opens; flows visible and functional
- [ ] `flows_cred.json` decrypts correctly (credential secret matches Pi value)
- [ ] Flow that publishes to MQTT `127.0.0.1:1883` completes without error
- [ ] Port 1880 not directly reachable from LAN (Caddy-only access)
- [ ] State survives reboot (flows intact, Caddy keeps cert, AdGuard DNSSEC resolves `nodered.lan`)

## Rollback

```fish
nixos-rebuild switch --flake .#adlerkopf --target-host dan@192.168.168.15
# (with services.node-red.enable = false + caddy vhost removed)
```
