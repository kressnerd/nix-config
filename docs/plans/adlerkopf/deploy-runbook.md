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

## Step 0 — Verify TPM 2.0 in BIOS

On the M720q BIOS (F1 at boot):
- Security → TPM → **Enabled**
- If Secure Boot is desired: Security → Secure Boot → **Enabled** → use PCRs `0+2+7`
- If Secure Boot is off: use PCRs `0+2` only (see Step 4)

## Step 1 — Prepare `@root-blank` snapshot via disko hook

The disko config should create `@root-blank` as part of the btrfs setup.
Add to `hosts/adlerkopf/disko.nix` in the btrfs subvolume list or as a post-create hook:

```nix
# At the end of the btrfs device block in disko.nix:
postCreateHook = ''
  mount -t btrfs /dev/mapper/cryptroot /mnt/btrfs_tmp
  btrfs subvolume snapshot /mnt/btrfs_tmp/@root /mnt/btrfs_tmp/@root-blank
  umount /mnt/btrfs_tmp
'';
```

If the hook is not yet wired, run manually after nixos-anywhere formats but before rebooting:

```fish
# On adlerkopf installer shell:
mount -t btrfs /dev/mapper/cryptroot /mnt/btrfs_tmp
btrfs subvolume snapshot /mnt/btrfs_tmp/@root /mnt/btrfs_tmp/@root-blank
umount /mnt/btrfs_tmp
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
ssh root@<installer-ip> ip addr show

# Run nixos-anywhere:
nix run github:nix-community/nixos-anywhere -- \
    --flake .#adlerkopf \
    --disk-encryption-keys /tmp/secret.key /dev/stdin <<< "<recovery-passphrase>" \
    root@<installer-ip>
```

nixos-anywhere will:
1. Run disko to partition and format disks (LUKS with recovery passphrase as initial key)
2. Install NixOS into the btrfs layout
3. Reboot

After reboot, the LUKS is opened with the recovery passphrase (TPM not enrolled yet).
The box boots to NixOS; Caddy starts with empty config; no sops secrets decrypted yet
(the age key is the SSH host key, which now exists at `/persist/etc/ssh/ssh_host_ed25519_key`).

## Step 3 — Verify basic boot

```fish
ssh dan@192.168.168.15   # or IP from DHCP if static not active yet

# Check:
systemctl is-active caddy sshd
ip addr show eno1         # should show 192.168.168.15 if networking.nix is correct
cat /persist/etc/ssh/ssh_host_ed25519_key.pub  # should exist
```

## Step 4 — Enroll TPM2

```fish
# On adlerkopf:
sudo systemd-cryptenroll \
    --tpm2-device=auto \
    --tpm2-pcrs=0+2+7 \       # use 0+2 if Secure Boot is disabled
    /dev/disk/by-partlabel/cryptroot
```

Test: `sudo reboot` → box should unlock automatically (no passphrase prompt).

Re-enrollment required after:
- BIOS firmware update
- Secure Boot policy change
- New option ROM detected by PCR 2

Re-enroll procedure:

```fish
# Remove existing TPM2 slot (find slot number first):
sudo systemd-cryptenroll --list /dev/disk/by-partlabel/cryptroot
sudo systemd-cryptenroll --wipe-slot=<tpm2-slot> /dev/disk/by-partlabel/cryptroot
# Re-enroll:
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 \
    /dev/disk/by-partlabel/cryptroot
```

## Step 5 — Bootstrap sops age key

Derive the age public key from the SSH host key:

```fish
# On adlerkopf:
nix-shell -p ssh-to-age --run \
    'ssh-to-age < /persist/etc/ssh/ssh_host_ed25519_key.pub'
# → age1xxxx...
```

On the workstation:

1. Replace `age1PLACEHOLDER...` in `.sops.yaml` with the real `age1xxxx...` key
2. Re-encrypt secrets for the new recipient:
   ```fish
   sops updatekeys hosts/adlerkopf/secrets.yaml
   ```
3. Commit the updated `.sops.yaml` and `secrets.yaml`, deploy:
   ```fish
   nixos-rebuild switch --flake .#adlerkopf --target-host dan@192.168.168.15
   ```
4. Verify sops decrypts on the host:
   ```fish
   ssh dan@192.168.168.15 sudo sops -d /run/secrets/placeholder
   ```

## Step 6 — Subsequent deployments

Three options; **Option A is the default** for day-to-day changes.

### Option A — direct nixos-rebuild (default)

```fish
# From workstation (J6G6Y9JK7L):
nixos-rebuild switch \
    --flake .#adlerkopf \
    --target-host dan@192.168.168.15 \
    --use-remote-sudo
```

Requires: `dan` on adlerkopf has `security.sudo.wheelNeedsPassword = false` (set in Phase 1) and
an authorized SSH key for the workstation.

Build happens **locally** on the workstation; the resulting closure is uploaded and activated
remotely. No Nix needed on adlerkopf beyond what NixOS ships with.

```fish
# Test-only (no activation):
nixos-rebuild build --flake .#adlerkopf --target-host dan@192.168.168.15

# Rollback last activation:
nixos-rebuild --rollback --target-host dan@192.168.168.15 --use-remote-sudo
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
ssh dan@192.168.168.15 sudo nix-env --list-generations \
    --profile /nix/var/nix/profiles/system

# Activate a specific generation:
ssh dan@192.168.168.15 \
    sudo /nix/var/nix/profiles/system-<N>-link/bin/switch-to-configuration switch
```

## Rollback

```fish
# Remote (if previous generation still activatable):
nixos-rebuild --rollback --target-host dan@192.168.168.15 --use-remote-sudo

# List generations:
ssh dan@192.168.168.15 sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Boot from installer USB and rescue /persist if all else fails:
# (LUKS always openable with recovery passphrase from 1Password)
```

## Router changes summary (manual, not automated)

| Phase | Change | Detail |
|---|---|---|
| 2 | DHCP DNS → `192.168.168.15` | Replace Pi-hole IP in router DHCP server settings |
| 3 | Port-forward UDP 51820 | Forward to `192.168.168.15:51820` (WireGuard) |
| 3 | Remove old port-forward UDP 1194 | PiVPN/OpenVPN no longer needed |
| X | Remove DHCP reservation for Pi | After full decommission |
