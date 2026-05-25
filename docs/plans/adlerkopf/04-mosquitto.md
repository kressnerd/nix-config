# Phase 4 — Mosquitto (MQTT broker)

**Goal**: Declare a Mosquitto broker on adlerkopf bound to the LAN interface.
Auth enforced. Migrate retained messages from the Pi.

## Files

| File | Action |
|---|---|
| `hosts/adlerkopf/services/mosquitto.nix` | create — import in `default.nix` |
| `hosts/adlerkopf/impermanence.nix` | extend — add `/var/lib/mosquitto` |
| `hosts/adlerkopf/secrets.yaml` | extend — add `mosquitto/passwd-file` |
| `tests/assertions/adlerkopf-invariants.nix` | extend — Mosquitto enabled + port 1883 on LAN interface only |

## Password file

Generate `mosquitto_passwd`-format hashes for each client (use version that ships with NixOS
`pkgs.mosquitto`):

```fish
nix-shell -p mosquitto --run 'mosquitto_passwd -c /tmp/mqtt-passwd nodered'
nix-shell -p mosquitto --run 'mosquitto_passwd    /tmp/mqtt-passwd sensor1'
cat /tmp/mqtt-passwd
# → multi-line file: "user:hash\nuser2:hash2\n..."
```

Store the entire file as a single sops secret:

```yaml
# hosts/adlerkopf/secrets.yaml
mosquitto/passwd-file: |
  nodered:$7$...hash...
  sensor1:$7$...hash...
```

## Module skeleton

```nix
# hosts/adlerkopf/services/mosquitto.nix
{ config, lib, ... }: {
  sops.secrets."mosquitto/passwd-file" = {
    owner = "mosquitto";
    group = "mosquitto";
    mode = "0440";
    restartUnits = [ "mosquitto.service" ];
  };

  services.mosquitto = {
    enable = true;
    dataDir = "/var/lib/mosquitto";
    persistence = true;
    listeners = [
      {
        address = "192.168.168.15";  # LAN only — never 0.0.0.0 on this listener
        port = 1883;
        settings = {
          password_file = config.sops.secrets."mosquitto/passwd-file".path;
          allow_anonymous = false;
        };
        acl = [
          "user nodered"
          "topic readwrite #"
          "user sensor1"
          "topic readwrite sensors/sensor1/#"
          # Add more per device as needed
        ];
      }
    ];
  };

  # LAN interface only — deny WAN
  networking.firewall.interfaces."eno1".allowedTCPPorts = [ 1883 ];
}
```

Loopback binding for Node-RED (same host) is implicit — no extra rule needed since
`127.0.0.1` is always allowed.

## Optional: MQTTS (TLS on port 8883)

Defer to a follow-up. Options:
- Caddy Layer-4 TLS termination forwarding to `127.0.0.1:1883` (no Mosquitto TLS config needed)
- Mosquitto native TLS with cert from `/var/lib/private/acme/mqtt.lan/`

## Impermanence extension

```nix
# in hosts/adlerkopf/impermanence.nix — append:
"/var/lib/mosquitto"   # contains mosquitto.db (retained messages + persistence)
```

## Pi data migration (retained messages)

```fish
# 1. Stop Mosquitto on the Pi first (ensures clean DB flush)
ssh pi@<pi-ip> sudo systemctl stop mosquitto

# 2. Copy the persistence DB to adlerkopf's persist volume
scp pi@<pi-ip>:/var/lib/mosquitto/mosquitto.db \
    dan@192.168.168.15:/persist/system/var/lib/mosquitto/mosquitto.db

# 3. Fix ownership (mosquitto UID may differ — check /var/lib/nixos/uid-map)
ssh dan@192.168.168.15 \
    sudo chown mosquitto:mosquitto /persist/system/var/lib/mosquitto/mosquitto.db

# 4. Start Mosquitto on adlerkopf
ssh dan@192.168.168.15 sudo systemctl start mosquitto
```

Verify retained messages:

```fish
mosquitto_sub -h 192.168.168.15 -u nodered -P <pw> -t '#' -v --retained-only -C 20
```

## New assertions

```nix
{ assertion = config.services.mosquitto.enable; message = "adlerkopf: Mosquitto must be enabled"; }
{ assertion = config.services.mosquitto.persistence; message = "adlerkopf: Mosquitto persistence required for retained messages"; }
```

## Acceptance criteria

- [ ] `nix flake check --no-build` green
- [ ] `mosquitto_pub -h 192.168.168.15 -u sensor1 -P <pw> -t sensors/sensor1/temp -m 21.5 -r`
- [ ] `mosquitto_sub -h 192.168.168.15 -u nodered -P <pw> -t sensors/#` receives the message
- [ ] Retained topic from Pi appears on a fresh subscribe without a new publish
- [ ] Anonymous connection rejected: `mosquitto_sub -h 192.168.168.15 -t test` → error
- [ ] Port 1883 not reachable from WAN (test from outside LAN or via WG peer)
- [ ] State survives a reboot (`mosquitto.db` persisted, retained messages intact)

## Rollback

```fish
nixos-rebuild switch --flake .#adlerkopf --target-host dan@192.168.168.15
# (with services.mosquitto.enable = false)
# Pi MQTT keeps running until clients are repointed
```

Repoint existing clients (sensors, Node-RED on Pi) back to Pi's IP after rollback.
