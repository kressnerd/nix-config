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

- **Run all commands inside `nix develop`** — the script requires `requests` and `secretstorage`, which are only available in the flake's devShell. Running with the system Python will fail with `ModuleNotFoundError: No module named 'requests'`.
- `nix develop` provides: Python 3, `requests`, `secretstorage`, `pytest`, `mypy`, `ruff`
- First run requires interactive browser auth (OIDC device code flow)
- Credentials stored at `~/.config/netcup-scp/credentials.json` (default) or gnome-keyring (see `--keyring`)

`--server` is the **name of the vServer as it appears in the netcup Server Control Panel (SCP)**. The tool uses this name to look up the server's numeric ID via the SCP REST API.

### Commands

**Backup** current firewall state:
```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the command
python3 scripts/netcup_firewall.py backup --server cupix001
```
Saves all policies + interface assignments to `~/.local/share/netcup-scp/backups/cupix001-{timestamp}.json`.

**Lockdown** (kill switch — block ALL traffic):
```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the command
python3 scripts/netcup_firewall.py lockdown --server cupix001 --yes
```
Creates a policy with explicit DROP rules for all protocols (TCP, UDP, ICMP, ICMPv6) and assigns it to all interfaces. Auto-backup is created first.

**Restore** from backup:
```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the command
python3 scripts/netcup_firewall.py restore --server cupix001 --file ~/.local/share/netcup-scp/backups/cupix001-20260411-150000.json
```

**Apply** policy (stub — see Epic 15):
```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the command
python3 scripts/netcup_firewall.py apply --server cupix001 --policy bootstrap
# Not implemented yet
```

### CLI Reference

> **Tip:** `python3 scripts/netcup_firewall.py --help` and `python3 scripts/netcup_firewall.py <subcommand> --help` show the full help text.

**Global options** (apply to all subcommands):

| Option | Description |
|--------|-------------|
| `--verbose` | Enable verbose output (INFO level logging) |
| `--quiet` | Suppress all output except errors |
| `--keyring` | Use gnome-keyring (Secret Service API) instead of file-based credential storage. Requires `secretstorage` |

**Subcommands:**

| Subcommand | Synopsis | Notes |
|------------|----------|-------|
| `backup` | `backup --server NAME` | Save current firewall rules to a timestamped JSON file |
| `lockdown` | `lockdown --server NAME [--yes]` | Apply deny-all inbound policy (kill switch). `--yes` skips the interactive confirmation prompt |
| `restore` | `restore --server NAME --file PATH` | Restore firewall rules from a backup JSON file |
| `apply` | `apply --server NAME --policy {bootstrap,production}` | Apply a named policy template (not yet implemented) |
| `ssh-open` | `ssh-open --server NAME --source IP [--port N] [--yes]` | Temporarily open SSH access from a specific source IP |
| `ssh-close` | `ssh-close --server NAME` | Remove temporary SSH access and delete the temporary policy |

### ssh-open — Temporary SSH Access

Opens temporary SSH access from a specific source IP via the netcup SCP external firewall.

```bash
# Open SSH port 22 from your IP
python3 scripts/netcup_firewall.py ssh-open --server cupix001 --source 1.2.3.4

# Open a custom SSH port
python3 scripts/netcup_firewall.py ssh-open --server cupix001 --source 1.2.3.4 --port 55809

# Skip confirmation prompt
python3 scripts/netcup_firewall.py ssh-open --server cupix001 --source 1.2.3.4 --yes
```

The command:
1. Creates an auto-backup (safety net)
2. Creates a temporary `ssh-temp-{server}` policy with a single INGRESS TCP ACCEPT rule
3. Additively assigns the policy alongside existing policies
4. Reports the open port and source IP

### ssh-close — Remove Temporary SSH Access

Removes temporary SSH access and deletes the temporary policy.

```bash
python3 scripts/netcup_firewall.py ssh-close --server cupix001
```

The command:
1. Creates an auto-backup
2. Removes `ssh-temp-{server}` policy from all interface assignments
3. Deletes the temporary policy at netcup
4. If no SSH policy exists, exits cleanly with an info message

### Credential Storage Backends

By default credentials are stored in `~/.config/netcup-scp/credentials.json` (0600).

To use **gnome-keyring** (Secret Service API) instead, add `--keyring` before the subcommand:

```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the command
python3 scripts/netcup_firewall.py --keyring backup --server cupix001
python3 scripts/netcup_firewall.py --keyring lockdown --server cupix001 --yes
python3 scripts/netcup_firewall.py --keyring restore --server cupix001 --file backup.json
```

`--keyring` requires the `secretstorage` library (included in `nix develop`) and a running Secret Service daemon (gnome-keyring or kwallet). If the daemon is unavailable the tool exits with an error — it never silently falls back to the file backend.

### Security Notes

- SCP API credentials are **Tier 1 secrets** — never commit to git
- Credentials and backups are persisted via impermanence on thiniel
- The kill switch runs from thiniel only — credentials never reside on the VPS
- Add age encryption to credentials file later if needed (see Epic 15a plan)

### Running Tests

```bash
# Enter the devShell first (provides Python 3 + all dependencies)
nix develop

# Then run the tests
cd scripts && python3 -m pytest tests/test_netcup_firewall.py -v
```
