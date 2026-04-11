# Scripts

Deployment and VM management scripts. These are complex shell scripts that have not yet been migrated to Nix derivations in `pkgs/`.

## build-vm-test.sh

Builds VM test images for `pronix-vm` and `cupix001-vm` configurations.

**Usage:**
```bash
scripts/build-vm-test.sh pronix-vm
scripts/build-vm-test.sh cupix001-vm
```

Runs `nix flake check --no-build` first, then builds system closures.

## build-vm.sh

Multi-purpose VM management script supporting multiple commands.

**Usage:**
```bash
scripts/build-vm.sh check
scripts/build-vm.sh build-iso
scripts/build-vm.sh build-vm
scripts/build-vm.sh generate-utm
scripts/build-vm.sh deploy
```

Generates UTM JSON config templates. Targets `nixos-vm-minimal` and `thiniel-vm` configurations.

## deploy-vm.sh

Deploys NixOS to VMs via nixos-anywhere. Handles SSH setup, LUKS encryption password provisioning, and nixos-anywhere orchestration.

**Usage:**
```bash
scripts/deploy-vm.sh deploy <host> <ip>
```

Default target: `nixos-vm-minimal` at `192.168.64.2`.

**Requirements:** `nixos-anywhere` (available via `nix-shell` or `nix develop`)

## netcup-firewall.py

Python CLI tool for managing the netcup SCP external firewall. Runs on the operator's workstation (thiniel) — **never on the VPS**.

### Prerequisites

- `nix develop` provides Python 3 + requests + pytest
- First run requires interactive browser auth (OIDC device code flow)
- Credentials stored at `~/.config/netcup-scp/credentials.json`

### Commands

**Backup** current firewall state:
```bash
python3 scripts/netcup_firewall.py backup --server cupix001
```
Saves all policies + interface assignments to `~/.local/share/netcup-scp/backups/cupix001-{timestamp}.json`.

**Lockdown** (kill switch — block ALL traffic):
```bash
python3 scripts/netcup_firewall.py lockdown --server cupix001 --yes
```
Creates an empty policy (implicit DROP ALL) and assigns it. Auto-backup is created first.

**Restore** from backup:
```bash
python3 scripts/netcup_firewall.py restore --server cupix001 --file ~/.local/share/netcup-scp/backups/cupix001-20260411-150000.json
```

**Apply** policy (stub — see Epic 15):
```bash
python3 scripts/netcup_firewall.py apply --server cupix001 --policy bootstrap
# Not implemented yet
```

### Security Notes

- SCP API credentials are **Tier 1 secrets** — never commit to git
- Credentials and backups are persisted via impermanence on thiniel
- The kill switch runs from thiniel only — credentials never reside on the VPS
- Add age encryption to credentials file later if needed (see Epic 15a plan)

### Running Tests

```bash
cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v
```
