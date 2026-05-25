# adlerkopf — Risks & Assumptions

## Risk register

| # | Risk | Phase | Likelihood | Impact | Mitigation |
|---|---|---|---|---|---|
| R1 | TPM PCR binding breaks after BIOS update | 1+ | Medium | Low (recovery PW works) | Store recovery passphrase in 1Password before nixos-anywhere; document re-enroll procedure in deploy-runbook |
| R2 | Secure Boot state changes → PCR 7 mismatch | 1+ | Medium | Low | Use PCR `0+2` only if Secure Boot is disabled; use `0+2+7` only if SB stays enabled |
| R3 | LE rate-limit (5 dup certs / 7 days) during Caddy iteration | 5, 6 | Low | Low | Use LE staging URL until first cert validates; switch to prod once stable |
| R4 | Node-RED credential secret lost / wrong | 5 | High (if forgotten) | High (flows undecryptable) | Extract from Pi's `settings.js` credentialSecret BEFORE migrating `flows_cred.json`; store in sops |
| R5 | Grafana DB schema incompatibility Pi→adlerkopf (9.x→10.x+) | 6 | Medium | Medium | Prefer declarative provisioning (dashboard JSON export); skip DB copy; fallback: run Grafana once to auto-migrate |
| R6 | DNS gap during AdGuard cutover | 2 | High if mistimed | Low (≤5 min if Pi-hole kept warm) | Keep Pi-hole running until adlerkopf acceptance; cut router DHCP DNS only after smoke-test |
| R7 | LUKS recovery passphrase lost | 1 | Low | Catastrophic (data loss) | Store in 1Password before provisioning; test recovery scenario once |
| R8 | WireGuard port-forward conflict with old OpenVPN | 3 | Low | Low | WG uses UDP 51820; OpenVPN uses UDP 1194 — different ports, can coexist during cut-over |
| R9 | Caddy plugin CVE (caddy-dns/netcup < 2.9.2) | 1+ | Low | Medium | Pin plugin version ≥ 2.9.2 in `caddy.withPlugins`; add assertion or comment |
| R10 | `ssh-to-age` public key derivation wrong → sops decryption fails on host | 1 | Low | Medium | Verify derived key against `sops -d hosts/adlerkopf/secrets.yaml` on-box before rotating dan_linux key |
| R11 | Mosquitto DB version mismatch Pi→adlerkopf | 4 | Low | Low | Mosquitto persistence format stable across minor versions; test with a single retained message after copy |
| R12 | NIC name not `eno1` | 1 | Medium | Low (fixable) | Check NIC name from installer: `ip link` or `ls /sys/class/net`; update `networking.nix` accordingly |
| R13 | M720q SKU missing TPM 2.0 chip | 1 | Low | Medium | Verify in BIOS before install: Security → TPM; some i3-8100T SKUs ship without TPM |
| R14 | `@root-blank` snapshot not created before first rollback boot | 1 | Medium | High (rollback fails; root gone) | Create `@root-blank` in nixos-anywhere `extraFiles` or disko `postCreateHook`; document in runbook |
| R15 | AdGuard `mutableSettings = false` discards runtime changes | 2+ | Certain | Low (expected) | Document: all AdGuard config changes go through Nix; no in-UI edits persist |

## Assumptions

| # | Assumption | Impact if wrong |
|---|---|---|
| A1 | M720q has TPM 2.0 and it is enabled in BIOS | Must use passphrase boot or initrd-SSH-unlock instead |
| A2 | NIC is Intel I219-V (driver: `e1000e`) | Add correct NIC driver to `hardware.nix`; verify from installer |
| A3 | Static IP `192.168.168.15` is free on the LAN | IP conflict on boot → change in `networking.nix` |
| A4 | Router allows static DHCP assignments and DNS override | Manual router admin access needed |
| A5 | Old Pi can remain online through the migration | No forced rollout; phased cut-over possible |
| A6 | Single admin user — no multi-tenancy for Grafana/Node-RED | If multi-user needed, PostgreSQL + LDAP adds complexity |
| A7 | Internet-facing domain for Netcup DNS-01 resolution exists | Caddy needs a real DNS zone to request LE certs for `.lan` names via DNS-01 |
| A8 | NixOS 25.11 `services.adguardhome` supports `mutableSettings = false` with full `settings` struct | Verify module options before implementing; fall back to `mutableSettings = true` with a one-time activation bootstrap if needed |
| A9 | Node-RED flows are self-contained (no external secrets embedded in flow JSON) | If flows reference secrets, those must be added to sops and injected via env vars |
