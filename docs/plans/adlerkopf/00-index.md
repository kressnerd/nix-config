# adlerkopf — Migration Plan Index

Migration of a Raspberry Pi 4 home server (PiVPN/OpenVPN, Grafana, Mosquitto, Node-RED, Pi-hole)
to a Lenovo ThinkCentre M720q (`adlerkopf`, x86_64, TPM 2.0) running NixOS.
Declarative rebuild from scratch; selective data migration for persistent state.

## Decisions

| Topic | Decision | Rationale |
|---|---|---|
| DNS resolver | AdGuard Home (`services.adguardhome`) | Native NixOS module; Pi-hole has none |
| VPN | WireGuard (new PKI, new clients) | Simpler than OpenVPN; cupix001 pattern reusable |
| LUKS unlock | TPM2 auto-unlock + recovery passphrase fallback | Passwordless boot; recovery slot kept |
| Reverse proxy | Caddy with `caddy-dns/netcup` plugin | DNS-01 for `.lan` TLS; same recipe as cupix001 plan |
| Grafana storage | SQLite in `@persist` | Single-user; PostgreSQL unnecessary |
| ACME DNS-01 provider | Netcup | Existing Netcup account; consistent with cupix001 |
| User access | SSH key only, user `dan`, `PasswordAuthentication = false` | Consistent with all other hosts; no password login |
| Update deploy | `nixos-rebuild --target-host` (manual); colmena (after Phase X) | Workstation-initiated push; no agent on host |

## Repo context

- Closest template host: `hosts/cupix001/` — btrfs + impermanence + disko + sops + systemd-boot
- cupix001's live implementation is in git-ignored `private.nix`; use `docs/plans/cupix001/00-..18-*.md` to reconstruct patterns
- **No** Caddy, WireGuard, AdGuard, Mosquitto, Node-RED, Grafana, or TPM2 patterns exist in the repo yet — all greenfield

## Phase table

| # | File | Scope | PR | Status |
|---|---|---|---|---|
| 0 | — | Inventory + decisions | PR-1 (planning only) | done |
| 1 | [01-base-os.md](./01-base-os.md) | hosts/adlerkopf scaffold, disko, LUKS+TPM2, impermanence, sops, Caddy skeleton | PR-2 | pending |
| 2 | [02-adguard.md](./02-adguard.md) | AdGuard Home DNS | PR-3 | pending |
| 3 | [03-wireguard.md](./03-wireguard.md) | WireGuard server | PR-4 | pending |
| 4 | [04-mosquitto.md](./04-mosquitto.md) | Mosquitto + retained-data migration | PR-5 | pending |
| 5 | [05-node-red.md](./05-node-red.md) | Node-RED + first Caddy vhost + LE DNS-01 | PR-6 | pending |
| 6 | [06-grafana.md](./06-grafana.md) | Grafana + declarative provisioning | PR-7 | pending |
| X | [X-cross-cutting.md](./X-cross-cutting.md) | restic, node_exporter, journald, colmena, Pi decommission | PR-8 | pending |

Supporting docs:
- [risks.md](./risks.md) — risk + assumption tracker
- [deploy-runbook.md](./deploy-runbook.md) — nixos-anywhere + TPM enroll + sops bootstrap

## PR sequencing

```
PR-1  docs/plans/adlerkopf/  (this file + siblings) — planning artifacts only
PR-2  Phase 1: hosts/adlerkopf/, .sops.yaml, flake.nix, assertions, integration test
PR-3  Phase 2: AdGuard Home module   → end: router DHCP DNS → 192.168.168.15
PR-4  Phase 3: WireGuard module      → end: router port-forward UDP 51820
PR-5  Phase 4: Mosquitto module      → end: clients repointed; Pi MQTT retired
PR-6  Phase 5: Node-RED + Caddy vhost (first real Caddy config here)
PR-7  Phase 6: Grafana + Caddy vhost
PR-8  Phase X: restic, monitoring, colmena, Pi retirement
```

## End-to-end acceptance (after all phases)

```fish
nix flake check
nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel
ssh dan@adlerkopf systemctl is-active adguardhome wg-quick-wg0 mosquitto node-red grafana caddy
dig @192.168.168.15 doubleclick.net       # blocked
dig @192.168.168.15 grafana.lan           # 192.168.168.15
curl -fsSI https://grafana.lan            # 200, valid LE cert
curl -fsSI https://nodered.lan            # 200, valid LE cert
wg show wg0                               # peers handshaked
sudo journalctl -u rollback               # rollback ran on boot
```
