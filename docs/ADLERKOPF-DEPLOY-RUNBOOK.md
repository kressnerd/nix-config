# adlerkopf — Deployment Runbook

One-shot procedure: install NixOS via nixos-anywhere, bootstrap sops, enroll TPM2.
Run through this sequentially on first deployment; for subsequent rebuilds use `nixos-rebuild`.

## Prerequisites

On the workstation (J6G6Y9JK7L):

- [ ] `nix flake check` passes (all adlerkopf assertions green, build succeeds)
- [ ] `hosts/adlerkopf/secrets.yaml` contains at minimum `placeholder: initial-setup` (encrypted)
- [ ] `.sops.yaml` has an `adlerkopf` entry (can use a temporary placeholder age key — see Step 5)
- [ ] LUKS recovery passphrase saved in 1Password
- [ ] M720q is booted from NixOS installer USB (e.g. `nixos-minimal-25.11-x86_64-linux.iso`)
- [ ] M720q is connected via Ethernet and has a temporary DHCP IP
- [ ] `~/.config/sops/age/keys.txt` contains the workstation age private key (needed for local `sops`
  operations). On thiniel this is handled by `home/dan/features/cli/sops-age-key.nix`.

> **Secure Boot / lanzaboote — chicken-and-egg**: `secure-boot.nix` MUST be disabled (commented out
> in `hosts/adlerkopf/default.nix`) for the initial nixos-anywhere install. The sbctl keys do not
> exist yet at that point. After first boot, create keys and re-enable (see Step 4).

## Step 0 — Verify TPM 2.0 in BIOS

On the M720q BIOS (F1 at boot):
- Security → TPM → **Enabled**
- Leave Secure Boot **Disabled** for the initial install (see Secure Boot note above)

## Step 1 — `@root-blank` snapshot (automatic)

The `postCreateHook` in `hosts/adlerkopf/disko.nix` creates `@root-blank` automatically as part of
the btrfs setup during nixos-anywhere. No manual step is needed.

```nix
# Already wired in disko.nix — shown for reference only:
postCreateHook = ''
  mount -t btrfs /dev/mapper/cryptroot /mnt/btrfs_tmp
  btrfs subvolume snapshot /mnt/btrfs_tmp/@root /mnt/btrfs_tmp/@root-blank
  umount /mnt/btrfs_tmp
'';
```

## Step 1.5 — Prepare installer SSH access

nixos-anywhere SSHes to the installer as `nixos` (with passwordless sudo) to upload a kexec image
and run disko. The standard NixOS minimal ISO ships with sshd disabled by default.

**On the M720q console** (after booting the installer USB):

```bash
sudo systemctl start sshd
sudo passwd nixos      # set a temporary password, e.g. "nixos-install"
ip addr show           # note the DHCP IP for the next step
```

**From the workstation** — copy your SSH key so no password prompt during nixos-anywhere:

```fish
ssh-copy-id nixos@<installer-ip>   # enter the temporary password once
```

Verify:

```fish
ssh nixos@<installer-ip> echo ok   # should succeed without password prompt
```

**Alternative — pre-built installer ISO**: `scripts/deploy-vm.sh generate-iso` (lines 248-302)
builds a custom ISO with SSH enabled and `nixos`/`root` password pre-set to `nixos`. Useful if
console access is awkward. Boot from it instead and skip the manual sshd steps above.

## Step 2 — Provision via nixos-anywhere

From workstation (requires `nixos-anywhere` in PATH — available via `nix run github:...` or flake devShell):

```fish
# Find the installer's temporary IP:
ssh nixos@<installer-ip> ip addr show

# Write passphrase to a local file first (avoids shell history exposure):
read -s -P "LUKS passphrase: " LUKS_PASS
printf '%s' "$LUKS_PASS" > /tmp/luks-key.txt

# Run nixos-anywhere:
nix run github:nix-community/nixos-anywhere -- \
    --flake .#adlerkopf \
    --build-on local \
    --disk-encryption-keys /tmp/secret.key /tmp/luks-key.txt \
    --phases kexec,disko,install \
    nixos@<installer-ip>

# Remove the key file immediately after:
rm -f /tmp/luks-key.txt
```

**Flags explained**:
- `--build-on local` — build the NixOS closure locally on the workstation (avoids Nix on installer)
- `--phases kexec,disko,install` — stops before auto-reboot, allowing manual verification first
- `--disk-encryption-keys /tmp/secret.key /tmp/luks-key.txt` — uploads the local key file to the
  installer as `/tmp/secret.key`; disko uses this as the initial LUKS passphrase

nixos-anywhere will:
1. Run disko to partition and format disks (LUKS with recovery passphrase as initial key)
2. Install NixOS into the btrfs layout
3. Stop (no reboot — you used `--phases kexec,disko,install`)

Manually reboot when ready:

```fish
ssh nixos@<installer-ip> sudo reboot
```

After reboot, the LUKS is opened with the recovery passphrase (TPM not enrolled yet).
The box boots to NixOS; Caddy starts with empty config; no sops secrets decrypted yet
(the age key is the SSH host key, which now exists at `/persist/system/etc/ssh/ssh_host_ed25519_key`).

## Step 3 — Verify basic boot

```fish
ssh dan@REDACTED-HOME-LAN-SUBNET   # or IP from DHCP if static not active yet

# Check:
systemctl is-active caddy sshd
ip addr show eno1         # should show the static IP from networking.nix / private.nix
cat /persist/system/etc/ssh/ssh_host_ed25519_key.pub  # should exist
```

> **Note**: The actual static IP depends on the `adlerkopf.lan.ip` value in `private.nix`. The
> default in the example file is `REDACTED-HOME-LAN-SUBNET`.

To deploy a follow-up rebuild before TPM/sops are set up:

```fish
nixos-rebuild switch \
    --flake .#adlerkopf \
    --build-on local \
    --target-host dan@REDACTED-HOME-LAN-SUBNET \
    --use-remote-sudo
```

(`--build-on local` builds on the workstation by default; shown explicitly for clarity.)

## Step 4 — Enroll TPM2

TPM2 enrollment can be done on the live running system (no reboot required to enroll):

```fish
# IMPORTANT: Before TPM2 enrollment, verify a passphrase keyslot exists.
# Without a separate passphrase slot, a BIOS firmware update will lock you out
# (TPM2 PCR values change → TPM2 unlock fails, and no passphrase fallback).
sudo cryptsetup luksDump /dev/disk/by-partlabel/disk-nvme0n1-cryptroot | grep "luks2"
# Must show at least one keyslot with type luks2 + PBKDF (passphrase-based).
# disko creates one automatically via passwordFile — but verify it's there.
```

```fish
# On adlerkopf — while Secure Boot is still DISABLED:
sudo systemd-cryptenroll \
    --tpm2-device=auto \
    --tpm2-pcrs=0+2 \
    /dev/disk/by-partlabel/disk-nvme0n1-cryptroot
```

Test: `sudo reboot` → box should unlock automatically (no passphrase prompt).

### PCR selection

| Secure Boot state | Recommended PCRs | Covers |
|---|---|---|
| Disabled (initial) | `0+2` | firmware + option ROMs |
| Enabled (after sbctl) | `7` | Secure Boot policy + DBX |

### Enable Secure Boot (after stable first boot)

1. `sudo sbctl create-keys`
2. Uncomment `./secure-boot.nix` in `hosts/adlerkopf/default.nix`
3. Uncomment lanzaboote assertions in `tests/assertions/adlerkopf-invariants.nix`
4. `nixos-rebuild switch --flake .#adlerkopf --build-on local --target-host dan@REDACTED-HOME-LAN-SUBNET --use-remote-sudo`
5. Enable Secure Boot in BIOS
6. Re-enroll TPM2 with `--tpm2-pcrs=7` (remove old slot first — see below)

### Re-enrollment procedure

Required after: BIOS firmware update, Secure Boot policy change, new option ROM detected by PCR 2.

```fish
# List keyslots and tokens:
sudo cryptsetup luksDump /dev/disk/by-partlabel/disk-nvme0n1-cryptroot | grep -E "luks2|systemd-tpm2"
# Remove existing TPM2 token:
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/disk/by-partlabel/disk-nvme0n1-cryptroot
# Re-enroll:
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2 \
    /dev/disk/by-partlabel/disk-nvme0n1-cryptroot
# (or --tpm2-pcrs=7 if Secure Boot is active)
```

> **"Would leave no valid slots"**: If `--wipe-slot=tpm2` fails with this error, it means
> the TPM2 token is the only keyslot — there's no passphrase fallback. Fix this while the
> system is still running (volume is open):
>
> ```fish
> sudo nix-shell -p keyutils --run '
>   KEY_ID=$(keyctl search @s logon "cryptsetup:$(cryptsetup luksUUID /dev/disk/by-partlabel/disk-nvme0n1-cryptroot)-d0")
>   keyctl pipe "$KEY_ID" > /tmp/volume-key.bin
>   chmod 600 /tmp/volume-key.bin
> '
> sudo cryptsetup luksAddKey --volume-key-file /tmp/volume-key.bin \
>     /dev/disk/by-partlabel/disk-nvme0n1-cryptroot
> sudo rm -f /tmp/volume-key.bin
> # Now retry --wipe-slot=tpm2
> ```

## Step 5 — Bootstrap sops age key

> **Workstation prerequisite**: ensure `~/.config/sops/age/keys.txt` contains the workstation age
> private key, so `sops` can decrypt/re-encrypt locally. On thiniel this is set up via
> `home/dan/features/cli/sops-age-key.nix`.

Derive the age public key from the SSH host key:

```fish
# On adlerkopf:
nix-shell -p ssh-to-age --run \
    'ssh-to-age < /persist/system/etc/ssh/ssh_host_ed25519_key.pub'
# → age1xxxx...
```

On the workstation:

1. Replace `age1PLACEHOLDER...` in `.sops.yaml` with the real `age1xxxx...` key
2. Encrypt or re-key secrets for the new recipient:
   ```fish
   # First deployment (secrets.yaml is still plaintext):
   sops encrypt -i hosts/adlerkopf/secrets.yaml

   # Subsequent key changes (secrets.yaml is already encrypted):
   sops updatekeys hosts/adlerkopf/secrets.yaml
   ```
3. Commit the updated `.sops.yaml` and `secrets.yaml`, deploy:
   ```fish
   nixos-rebuild switch \
       --flake .#adlerkopf \
       --build-on local \
       --target-host dan@REDACTED-HOME-LAN-SUBNET \
       --use-remote-sudo
   ```
4. Verify sops decrypts on the host:
   ```fish
   # sops CLI is not installed on adlerkopf — verify via cat instead:
   ssh dan@REDACTED-HOME-LAN-SUBNET sudo cat /run/secrets/<name>
   ```

> **Note**: Phase 1 has no `sops.secrets.*` attributes declared, so `/run/secrets/` will not exist
> until at least one secret is added to the configuration. The verify step above applies once a
> secret is declared and deployed.

## Step 6 — Subsequent deployments

Three options; **Option A is the default** for day-to-day changes.

### Option A — direct nixos-rebuild (default)

```fish
# From workstation (J6G6Y9JK7L):
nixos-rebuild switch \
    --flake .#adlerkopf \
    --build-on local \
    --target-host dan@REDACTED-HOME-LAN-SUBNET \
    --use-remote-sudo
```

> `--build-on local` builds the closure on the workstation and uploads it — this is the default
> behaviour of `nixos-rebuild --target-host`; the flag is shown explicitly for clarity.

Requires: `dan` on adlerkopf has `security.sudo.wheelNeedsPassword = false` (set in Phase 1) and
an authorized SSH key for the workstation.

```fish
# Test-only (no activation):
nixos-rebuild build --flake .#adlerkopf --target-host dan@REDACTED-HOME-LAN-SUBNET

# Rollback last activation:
nixos-rebuild --rollback --target-host dan@REDACTED-HOME-LAN-SUBNET --use-remote-sudo
```

### Option B — colmena (after Phase X PR-8)

After `adlerkopf` is registered in `colmenaHive.nodes` (`flake.nix:393-422`):

```fish
colmena apply --on adlerkopf           # switch
colmena apply --on @home-server        # all home-server tagged nodes at once
```

To add the standard shell aliases (matching the ones in `home/dan/thiniel.nix:63-71`), extend
`home/dan/J6G6Y9JK7L.nix` or `home/dan/global/default.nix` with:

```nix
programs.fish.shellAbbrs = {
  ca  = "colmena apply --on adlerkopf";
  cda = "colmena apply --on @home-server";
};
```

### Option C — auto-upgrade (gate until stable)

Declared in `X-cross-cutting.md`. Enable only after the host has been running stably for ≥30 days.
Gated by `system.autoUpgrade.allowReboot = false` initially.

### Generations and rollback

All three options share the same `/nix/var/nix/profiles/system` generation chain.

```fish
# List generations:
ssh dan@REDACTED-HOME-LAN-SUBNET sudo nix-env --list-generations \
    --profile /nix/var/nix/profiles/system

# Activate a specific generation:
ssh dan@REDACTED-HOME-LAN-SUBNET \
    sudo /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```

## Rollback

```fish
# Remote (if previous generation still activatable):
nixos-rebuild --rollback --target-host dan@REDACTED-HOME-LAN-SUBNET --use-remote-sudo

# List generations:
ssh dan@REDACTED-HOME-LAN-SUBNET sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Boot from installer USB and rescue /persist if all else fails:
# (LUKS always openable with recovery passphrase from 1Password)
```

## Router changes summary (manual, not automated)

| Phase | Change | Detail |
|---|---|---|
| 2 | DHCP DNS → `REDACTED-HOME-LAN-SUBNET` | Replace Pi-hole IP in router DHCP server settings |
| 3 | Port-forward UDP 51820 | Forward to `REDACTED-HOME-LAN-SUBNET:51820` (WireGuard) |
| 3 | Remove old port-forward UDP 1194 | PiVPN/OpenVPN no longer needed |
| X | Remove DHCP reservation for Pi | After full decommission |
