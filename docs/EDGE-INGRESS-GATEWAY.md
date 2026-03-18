# Aufgabe: NixOS VPS-Konfiguration in bestehendes Multi-Host-Flake integrieren

## Kontext

Bestehende Infrastruktur:
- Home-Lab: bare-metal Storage-Host, 3 Compute-Hosts, ipfire Firewall, managed Switch mit VLANs
- DSL 100/50, kein Port-Forwarding mehr gewünscht
- VPS bei netcup mit fester IPv4, aktuell Debian, Ziel: NixOS
- Zentrale Nix-Konfiguration als Flake unter: `TODO: Pfad zum Repo, z.B. ~/nix-config`

## Zielarchitektur VPS

Der VPS ist ein Edge-Ingress-Gateway. Kein Bastion-Host. Folgende Services laufen auf dem VPS:

1. **Headscale** — Tailnet Control Plane, lauscht auf 127.0.0.1:8080
2. **Tailscale-Daemon** — registriert VPS als Node im eigenen Headscale
3. **Nginx** — Reverse-Proxy + TLS-Termination (Let's Encrypt via ACME)
   - `hs.example.com` → `http://127.0.0.1:8080` (Headscale, inkl. WebSockets)
   - `public.example.com` → `http://100.64.x.y:80` (Tailscale-IP des Home-Lab Reverse-Proxy)
4. **Uptime Kuma** oder **Gatus** — Monitoring (läuft lokal auf VPS, unabhängig vom Home-Lab)
5. **ntfy** — Push-Notification-Relay

## Netzwerkdaten VPS (netcup)
```
IPv4:            TODO
IPv4-Präfix:     TODO (vermutlich /22)
IPv4-Gateway:    TODO
IPv6:            TODO
IPv6-Präfix:     /64
IPv6-Gateway:    TODO (vermutlich fe80::1)
DNS:             TODO (z.B. 46.38.225.18, 46.38.252.230)
Interface:       TODO (z.B. ens3)
Disk:            TODO (z.B. /dev/vda)
Bootmodus:       TODO (vermutlich BIOS/Legacy)
```

## Verwendete Tools

- **nixos-anywhere** für Remote-Installation
- **disko** für deklaratives Disk-Layout
- **impermanence** für ephemeres Root-Filesystem

## Anforderungen


### Repo-Struktur

Erweitere die bestehende Flake-Struktur um den Host `vps`. Zielstruktur:
```
flake.nix
flake.lock
hosts/
  vps/
    default.nix          # Host-spezifische Konfiguration
    hardware.nix         # hardware-configuration (generiert oder manuell)
    disko.nix            # Disk-Layout mit btrfs mit Subvolumes für impermanence für nixos-anywhere
    networking.nix       # Statische Netzwerkkonfiguration
    persist.nix           # NEU: alle persistenten Pfade zentral
modules/
  server/
    headscale.nix            # Headscale-Service-Modul
    nginx-reverse-proxy.nix  # Nginx + ACME
    tailscale-client.nix     # Tailscale-Daemon
    hardening.nix            # Kernel- und Systemd-Härtung
    monitoring.nix           # Uptime Kuma oder Gatus
    ntfy.nix                 # ntfy Notification-Relay
    impermanence.nix         # Basis-Modul für impermanence
  common/
    base.nix             # Gemeinsame Basis aller Hosts
    ssh.nix              # SSH-Konfiguration
tests/
  vm-vps.nix             # Libvirt-VM-Testkonfiguration
```

Falls eine andere Struktur im Repo bereits existiert, integriere dich in die bestehende Konvention, statt eine neue aufzuzwingen. Frage nach, falls unklar.

### Disko-Konfiguration (`hosts/vps/disko.nix`)

Das Root-Subvolume wird bei jedem Boot gelöscht. `/nix` und `/persist` überleben.

Zielstruktur auf `/dev/vda`:
```
GPT
├── 1 MB   BIOS-Boot (ef02)
├── btrfs  Label &quot;nixos&quot;
│   ├── @root     → /        (wird bei Boot gelöscht)
│   ├── @nix      → /nix     (persistent)
│   ├── @persist  → /persist (persistent)
│   ├── @log      → /var/log (persistent, damit Logs Boot überleben)
│   └── @swap     → /swap    (optional, Swapfile)
```

Referenz-Implementierung:

```nix
# hosts/vps/disko.nix
{ ... }:
{
  disko.devices.disk.main = {
    type = &quot;disk&quot;;
    device = &quot;/dev/vda&quot;;  # TODO: prüfen
    content = {
      type = &quot;gpt&quot;;
      partitions = {
        bios = {
          size = &quot;1M&quot;;
          type = &quot;EF02&quot;;
        };
        root = {
          size = &quot;100%&quot;;
          content = {
            type = &quot;btrfs&quot;;
            extraArgs = [ &quot;-f&quot; &quot;-L&quot; &quot;nixos&quot; ];
            subvolumes = {
              &quot;@root&quot; = {
                mountpoint = &quot;/&quot;;
                mountOptions = [ &quot;compress=zstd&quot; &quot;noatime&quot; ];
              };
              &quot;@nix&quot; = {
                mountpoint = &quot;/nix&quot;;
                mountOptions = [ &quot;compress=zstd&quot; &quot;noatime&quot; ];
              };
              &quot;@persist&quot; = {
                mountpoint = &quot;/persist&quot;;
                mountOptions = [ &quot;compress=zstd&quot; &quot;noatime&quot; ];
              };
              &quot;@log&quot; = {
                mountpoint = &quot;/var/log&quot;;
                mountOptions = [ &quot;compress=zstd&quot; &quot;noatime&quot; ];
              };
              &quot;@swap&quot; = {
                mountpoint = &quot;/swap&quot;;
                swap.swapfile.size = &quot;2G&quot;;
              };
            };
          };
        };
      };
    };
  };

  fileSystems.&quot;/persist&quot;.neededForBoot = true;
  fileSystems.&quot;/var/log&quot;.neededForBoot = true;
}
```

## Root-Wipe-Mechanismus

Bei jedem Boot das `@root`-Subvolume löschen und neu erstellen.
Zwei Varianten — wähle eine:

**Variante A: `boot.initrd.postResumeCommands`** (einfacher)

```nix
boot.initrd = {
  supportedFilesystems = [ &quot;btrfs&quot; ];
  postResumeCommands = lib.mkAfter &#x27;&#x27;
    mkdir -p /mnt
    mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
    btrfs subvolume delete /mnt/@root || true
    btrfs subvolume create /mnt/@root
    umount /mnt
  &#x27;&#x27;;
};
```

**Variante B: Blank-Snapshot-Rollback** (sauberer, empfohlen)

Beim ersten Setup einen leeren Snapshot von `@root` erstellen:

```bash
btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
```

Dann im initrd:

```nix
boot.initrd.postResumeCommands = lib.mkAfter &#x27;&#x27;
  mkdir -p /mnt
  mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
  btrfs subvolume delete /mnt/@root
  btrfs subvolume snapshot /mnt/@root-blank /mnt/@root
  umount /mnt
&#x27;&#x27;;
```

Dokumentiere in `disko.nix` oder `docs/vps-deployment.md`, dass der Blank-Snapshot
im Post-Deployment-Schritt von nixos-anywhere erstellt werden muss. <kcite ref="230"/>

## Impermanence-Modul (`modules/server/impermanence.nix`)

```nix
# modules/server/impermanence.nix
{ config, lib, inputs, ... }:
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence.&quot;/persist&quot; = {
    hideMounts = true;

    directories = [
      &quot;/etc/nixos&quot;           # optional: lokale Config-Kopie
      &quot;/var/lib/nixos&quot;       # NixOS state (uid/gid map)
      &quot;/var/lib/systemd&quot;     # systemd persistent state (timers, journals)
    ];

    files = [
      &quot;/etc/machine-id&quot;
    ];
  };

  # Sicherstellen, dass /persist vor allem anderen da ist
  fileSystems.&quot;/persist&quot;.neededForBoot = true;
}
```

## Persist-Deklaration (`hosts/vps/persist.nix`) — NEU

Zentrale Datei, die **alle** Service-spezifischen persistenten Pfade deklariert.
Jeder Service, der Zustand hat, muss hier aufgeführt sein — sonst sind die
Daten nach Reboot weg.

```nix
# hosts/vps/persist.nix
{ ... }:
{
  environment.persistence.&quot;/persist&quot; = {
    directories = [
      # --- Headscale ---
      &quot;/var/lib/headscale&quot;       # SQLite-DB, private keys, OIDC state

      # --- Tailscale ---
      &quot;/var/lib/tailscale&quot;       # Node-Keys, State

      # --- ACME / Let&#x27;s Encrypt ---
      &quot;/var/lib/acme&quot;            # Zertifikate + Account-Keys

      # --- SSH Host Keys ---
      &quot;/etc/ssh&quot;                 # ssh_host_*_key — KRITISCH

      # --- fail2ban ---
      &quot;/var/lib/fail2ban&quot;        # Ban-DB

      # --- Monitoring (Uptime Kuma oder Gatus) ---
      &quot;/var/lib/uptime-kuma&quot;     # oder /var/lib/gatus — je nach Wahl

      # --- ntfy ---
      &quot;/var/lib/ntfy-sh&quot;         # Cache + Attachments

      # --- Secrets (agenix/sops-nix) ---
      # agenix entschlüsselt nach /run/agenix, braucht aber
      # /persist/etc/ssh für Host-Keys als Entschlüsselungskey
    ];

    files = [
      # Falls Root-Passwort-Hash gebraucht wird
      # &quot;/etc/shadow&quot;  # Nur wenn nicht rein key-basiert
    ];
  };
}
```

**Regel für den Agenten**: Wenn ein neuer Service zum VPS hinzugefügt wird,
MUSS ein entsprechender Eintrag in `persist.nix` ergänzt werden. Ohne
Persist-Eintrag = Datenverlust bei Reboot.

## Secrets-Handling mit impermanence — Besonderheit

`agenix` oder `sops-nix` verwenden SSH-Host-Keys zur Entschlüsselung.
Diese Host-Keys müssen unter `/persist/etc/ssh` liegen und beim Boot
verfügbar sein, **bevor** Secrets entschlüsselt werden.

```nix
# In persist.nix ist /etc/ssh bereits gelistet.
# Zusätzlich in der agenix/sops-nix-Config:
age.identityPaths = [
  &quot;/persist/etc/ssh/ssh_host_ed25519_key&quot;
];
```

Dokumentiere, dass nach dem ersten Deployment die generierten
SSH-Host-Keys (`/etc/ssh/ssh_host_ed25519_key.pub`) in die
`.agenix.nix` / `sops.yaml` eingetragen werden müssen.

## Flake-Input — NEU

```nix
# flake.nix (Auszug)
{
  inputs = {
    nixpkgs.url = &quot;github:NixOS/nixpkgs/nixos-unstable&quot;; # oder stable
    disko = {
      url = &quot;github:nix-community/disko&quot;;
      inputs.nixpkgs.follows = &quot;nixpkgs&quot;;
    };
    impermanence.url = &quot;github:nix-community/impermanence&quot;;
    agenix.url = &quot;github:ryantm/agenix&quot;;  # oder sops-nix
    # ... weitere bestehende Inputs
  };
}
```

### Härtung (`modules/server/hardening.nix`)

- `boot.kernelPackages = pkgs.linuxPackages_hardened`
- Kernel-sysctl: `kptr_restrict=2`, `yama.ptrace_scope=2`, `bpf_jit_harden=2`, `unprivileged_bpf_disabled=1`, `rp_filter=1`, `accept_redirects=0`, `send_redirects=0`, `tcp_syncookies=1`
- `security.protectKernelImage = true`
- Systemd-Service-Hardening für jeden Service: `PrivateTmp`, `ProtectHome`, `ProtectSystem=strict`, `NoNewPrivileges`, `PrivateDevices`, `ProtectKernelTunables`, `ProtectKernelModules`, `ProtectKernelLogs`, `ProtectControlGroups`, `RestrictNamespaces`, `LockPersonality`, `RestrictRealtime`, `RestrictSUIDSGID`, `MemoryDenyWriteExecute`, `SystemCallArchitectures=native`
- `environment.defaultPackages = []`
- fail2ban aktiviert
- Automatische Sicherheitsupdates via `system.autoUpgrade`

### SSH

- Nur auf Tailscale-IP lauschen (`100.64.x.x:22`)
- `PermitRootLogin = "prohibit-password"`
- `PasswordAuthentication = false`
- Authorized Key: `TODO: ssh-ed25519 AAAA...`

### Firewall

- Nur TCP 80, 443 und UDP 3478, 41641 öffentlich
- SSH NICHT öffentlich (nur Tailnet)

### Nginx + ACME

- `security.acme.acceptTerms = true`, `defaults.email = "TODO"`
- `recommendedTlsSettings`, `recommendedProxySettings`, `recommendedGzipSettings`, `recommendedOptimisation` aktiviert
- Virtual Hosts wie oben beschrieben
- WebSocket-Support für Headscale-Endpoint

### Headscale

- `server_url = "https://hs.example.com"` (TODO: echte Domain)
- MagicDNS aktiviert, `base_domain = "tail.example.com"` (TODO)
- Eingebetteter DERP-Server aktiviert, `stun_listen_addr = "0.0.0.0:3478"`, `region_id = 900`
- SQLite als DB (default)

### Tailscale-Client

- `services.tailscale.enable = true`
- Registrierung am eigenen Headscale-Server (Hinweis als Kommentar im Code: manueller Schritt nach erstem Boot)

## Lokaler VM-Test (`tests/vm-vps.nix`)

Erstelle eine Konfiguration, mit der die VPS-Konfiguration lokal in einer libvirt/QEMU-VM getestet werden kann:

- Nutze `nixos-generators` oder ein NixOS-VM-Build (`config.system.build.vm`) für ein qcow2-Image
- Überschreibe in der VM-Testkonfiguration:
  - Netzwerk: DHCP statt statische netcup-IP
  - Bootloader: passend für QEMU (kann UEFI sein)
  - SSH: auf allen Interfaces lauschen (zum Testen)
  - Headscale `server_url`: `https://localhost` oder ein Testname
  - ACME: `security.acme.defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory"` oder Self-Signed
  - Tailscale: deaktiviert oder Mock
- Erstelle ein Shell-Skript `tests/run-vm.sh`:
  ```bash
  #!/usr/bin/env bash
  # Baut das VM-Image und startet es mit libvirt/virsh
  nix build .#nixosConfigurations.vps-vm.config.system.build.vm -o result
  # oder qcow2 via nixos-generators
  # Start mit virt-install oder virsh
```
- Dokumentiere die Voraussetzungen (libvirtd aktiv, Nutzer in libvirt-Gruppe)

Der VM-Test muss impermanence einschließen, damit das Wipe-Verhalten
lokal validiert werden kann:

- Disko-Config überschreiben: Disk-Device auf `/dev/vda` (QEMU-Default)
- Root-Wipe im initrd aktiv
- **Testfall**: VM starten → Datei in `/tmp/test` anlegen → VM rebooten →
  verifizieren, dass Datei weg ist. Datei in `/persist/test` anlegen →
  VM rebooten → verifizieren, dass Datei noch da ist.
- SSH-Host-Keys unter `/persist/etc/ssh` prüfen
- `systemctl status headscale` etc. nach Reboot prüfen

Ergänze im `tests/run-vm.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo &quot;Building VM image...&quot;
nix build .#nixosConfigurations.vps-vm.config.system.build.vm -o result

echo &quot;Starting VM...&quot;
QEMU_OPTS=&quot;-m 2048 -smp 2&quot; ./result/bin/run-vps-vm-vm &amp;
VM_PID=$!

echo &quot;VM PID: $VM_PID&quot;
echo &quot;Warte 30s auf Boot...&quot;
sleep 30

echo &quot;=== Impermanence-Test ===&quot;
echo &quot;Erstelle Datei in / und /persist...&quot;
ssh -o StrictHostKeyChecking=no -p 2222 root@localhost \
  &#x27;echo &quot;ephemeral&quot; &gt; /root/test.txt &amp;&amp; echo &quot;persistent&quot; &gt; /persist/test.txt&#x27;

echo &quot;Reboote VM...&quot;
ssh -o StrictHostKeyChecking=no -p 2222 root@localhost &#x27;reboot&#x27; || true
sleep 30

echo &quot;Prüfe nach Reboot...&quot;
ssh -o StrictHostKeyChecking=no -p 2222 root@localhost &#x27;
  [ ! -f /root/test.txt ] &amp;&amp; echo &quot;PASS: /root/test.txt gelöscht&quot; || echo &quot;FAIL&quot;
  [ -f /persist/test.txt ] &amp;&amp; echo &quot;PASS: /persist/test.txt vorhanden&quot; || echo &quot;FAIL&quot;
  systemctl is-active headscale &amp;&amp; echo &quot;PASS: headscale aktiv&quot; || echo &quot;FAIL&quot;
  systemctl is-active nginx &amp;&amp; echo &quot;PASS: nginx aktiv&quot; || echo &quot;FAIL&quot;
&#x27;

kill $VM_PID 2&gt;/dev/null || true
```


## Deployment-Anleitung

Erstelle eine Datei `docs/vps-deployment.md` mit:

1. Voraussetzungen (Netzwerkdaten gesammelt, VNC getestet, SSH-Key bereit)
2. Lokaler VM-Test: wie man `tests/run-vm.sh` ausführt und was man prüfen soll
3. Deployment via nixos-anywhere:
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  root@&lt;DEBIAN-IP&gt;
```
4. Post-Deployment: Tailscale registrieren, Headscale-User anlegen, DNS-Records setzen
5. Validierung: `systemd-analyze security`, Uptime-Check, HTTPS-Test
6. Rollback-Strategie

Ergänze in `docs/vps-deployment.md`:

### Post-Deployment (nach nixos-anywhere)

1. SSH auf VPS via VNC-Konsole (SSH-Host-Keys sind neu generiert)
2. Blank-Snapshot erstellen (einmalig):
```bash
mount -t btrfs -o subvol=/ /dev/disk/by-label/nixos /mnt
btrfs subvolume snapshot -r /mnt/@root /mnt/@root-blank
umount /mnt
```
3. SSH-Host-Public-Key aus `/persist/etc/ssh/ssh_host_ed25519_key.pub` holen
4. In `secrets/` den Public Key für agenix/sops-nix eintragen, Secrets re-encrypten
5. Erneutes `nixos-rebuild switch` oder erneutes nixos-anywhere-Deployment
6. Reboot, verifizieren, dass alle Services nach Root-Wipe starten

## Constraints

- Kein Docker/Podman. Alle Services nativ als NixOS-Module.
- Keine Secrets im Repo. Verwende `agenix` oder `sops-nix` für Headscale-Private-Key, OIDC-Secrets etc. Platzhalter einfügen und dokumentieren, welche Secrets benötigt werden.
- Code muss `nix flake check` bestehen.
- Jedes Modul soll eigenständig aktivierbar/deaktivierbar sein (`enable = true/false`).

## Nicht im Scope

- Home-Lab Tailscale-Subnet-Router-Konfiguration (kommt später)
- Familien-Standort-Konfiguration
- OIDC-Provider-Setup
- DNS-Konfiguration beim Domain-Registrar

## Abnahmekriterien

1. `nix flake check` erfolgreich
2. `nix build .#nixosConfigurations.vps.config.system.build.toplevel` baut ohne Fehler
3. VM-Test startet, Nginx antwortet auf Port 443 (Self-Signed), Headscale-Health-Endpoint erreichbar
4. Alle Services haben Systemd-Hardening (verifizierbar mit `systemd-analyze security <service>`)
5. SSH ist nur auf Tailscale-Interface gebunden
6. Firewall lässt nur TCP 80/443 und UDP 3478/41641 durch
7. Secrets-Platzhalter dokumentiert, keine Klartext-Secrets im Repo
8. Nach Reboot ist `/` leer (kein Zustand aus vorherigem Boot)
9. Alle Services starten nach Reboot korrekt (Zustand in `/persist`)
10. SSH-Host-Keys bleiben über Reboots identisch (kein Fingerprint-Wechsel)
11. ACME-Zertifikate überleben Reboot (kein erneutes Ausstellen)
12. Headscale-DB überlebt Reboot (Nodes bleiben registriert)
