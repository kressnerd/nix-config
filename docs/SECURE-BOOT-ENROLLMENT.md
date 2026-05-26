# Secure Boot Enrollment — lanzaboote

This runbook covers the one-time manual key enrollment required after the initial deployment of any host in this repository that has `boot.lanzaboote.enable = true`. Run it after the first `nixos-rebuild switch` with lanzaboote enabled (Secure Boot still **off** in firmware), and again after any re-keying event. The declarative Nix configuration is assumed to be already deployed; this document covers only the operational steps.

---

## Prerequisites

- `boot.lanzaboote.enable = true` in the host's Nix config
- `boot.loader.systemd-boot.enable = lib.mkForce false` in the host's Nix config
- `/var/lib/sbctl` persisted via impermanence (if the host uses impermanence)
- Host boots successfully with lanzaboote as the loader (Secure Boot **disabled** in firmware)
- LUKS recovery passphrase available (TPM2 binding will break temporarily)
- Secure Boot is currently **DISABLED** in UEFI firmware

> **⚠️ WARNING — data loss risk**: Enabling Secure Boot in firmware without correctly enrolled keys renders the system unbootable. Keep the LUKS recovery passphrase accessible before starting Step 5.

---

## Enrollment Steps

### Step 1 — Generate Secure Boot keys

```bash
sudo sbctl create-keys
```

Verify:

```bash
ls -la /var/lib/sbctl/keys/
```

Expected: `PK/`, `KEK/`, `db/` directories each containing `.key` and `.pem` files.

If using impermanence, confirm the keys are on the persisted mount:

```bash
findmnt /var/lib/sbctl
```

Expected: resolves via bind mount to `/persist/system/var/lib/sbctl` (or the host-specific persistence path).

---

### Step 2 — Enroll keys in UEFI firmware

```bash
sudo sbctl enroll-keys --microsoft
```

> **Note**: `--microsoft` includes Microsoft's KEK so that signed third-party UEFI option ROMs (NIC PXE, dGPU firmware) continue to function. Omit only if you are certain no signed option ROMs are present — this is rare.

---

### Step 3 — Rebuild NixOS to sign boot artifacts

```bash
sudo nixos-rebuild switch --flake .#<hostname>
```

Or remotely:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host dan@<ip> --use-remote-sudo
```

This re-signs all UKIs (Unified Kernel Images) on the ESP with the newly created keys.

---

### Step 4 — Verify all boot files are signed

```bash
sudo sbctl verify
```

Expected: every listed file shows `✓ Signed`.

If any file shows `✗ Not Signed`: run `nixos-rebuild switch` again, then re-verify. Check that `boot.lanzaboote.pkiBundle` points to `/var/lib/sbctl`.

---

### Step 5 — Enable Secure Boot in UEFI firmware

1. Reboot into BIOS/UEFI setup (typically `F1`, `F2`, or `DEL` at POST — see host-specific firmware key)
2. Navigate to **Security → Secure Boot**
3. Set Secure Boot to **Enabled**
4. Confirm the firmware switches to **User Mode** (exits Setup Mode after PK enrollment by `sbctl`)
5. Save and exit

The machine should boot normally with Secure Boot active.

---

### Step 6 — Verify Secure Boot is active

```bash
bootctl status
```

Expected output includes:

```
Secure Boot: enabled (user)
```

Alternative check:

```bash
mokutil --sb-state
```

Expected: `SecureBoot enabled`

---

### Step 7 — (TPM2 + LUKS only) Re-enroll TPM2 with PCR 7

PCR 7 measures the Secure Boot policy. After enabling Secure Boot, the PCR 7 value changes, so the existing TPM2 slot must be re-enrolled to bind LUKS unlock to the new policy.

First, determine the encrypted partition label:

```bash
lsblk -o NAME,PARTLABEL
```

Then wipe the old TPM2 slot and re-enroll with PCR 7:

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto \
    --tpm2-pcrs=0+2+7 /dev/disk/by-partlabel/<partition-label>
```

Replace `<partition-label>` with the actual label (e.g., `cryptroot` for `adlerkopf`).

Reboot and confirm LUKS auto-unlock completes without a passphrase prompt.

---

## Verification Checklist

- [ ] `sbctl verify` — all files signed
- [ ] `bootctl status` — `Secure Boot: enabled (user)`
- [ ] System boots without keyboard interaction (if TPM2 auto-unlock configured)
- [ ] Reboot survives: `sudo reboot`, then re-check `bootctl status`
- [ ] `/var/lib/sbctl/keys/` persists across reboot (impermanence check: `ls /var/lib/sbctl/keys/` after reboot)

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "Security Violation" on boot | Keys not enrolled or firmware not in User Mode | Boot with SB disabled (F1 → Security → Secure Boot → Disabled), re-run `sbctl enroll-keys --microsoft`, rebuild, re-enable |
| TPM2 unlock fails after enabling SB | PCR 7 value changed — expected | Use LUKS recovery passphrase to boot, then re-enroll: `--wipe-slot=tpm2 --tpm2-pcrs=0+2+7` |
| `sbctl verify` shows unsigned files | `nixos-rebuild switch` not run after key creation | Run `sudo nixos-rebuild switch --flake .#<hostname>` |
| Keys absent after reboot | `/var/lib/sbctl` not in impermanence persistence | Add to `environment.persistence."/persist/system".directories` |
| TPM2 unlock fails after BIOS update | PCR 0 changes on firmware update | Boot with recovery passphrase, re-enroll: `--wipe-slot=tpm2 --tpm2-pcrs=0+2+7` |

---

## Rollback

### Before enabling Secure Boot in firmware (Steps 1–4)

Revert the Nix config commits. `nixos-rebuild switch` restores plain `systemd-boot`. No firmware state was changed.

### After enabling Secure Boot in firmware (Step 5 onwards)

Enter BIOS/UEFI setup, set Secure Boot to **Disabled**, save and exit. The system boots normally. LUKS auto-unlock will fail PCR 7 check → use recovery passphrase, then re-enroll TPM2 without PCR 7 if needed.

### Nuclear option

Boot from a NixOS installer USB. Mount `/persist`, `/nix`, and the ESP. Use `nixos-enter` to run `nixos-rebuild switch --rollback` or revert flake commits and rebuild. Clear lanzaboote UKIs from the ESP if needed:

```bash
rm /boot/EFI/Linux/*.efi
```

---

## Applying to a New Host

To enable lanzaboote on a host that does not yet have it:

1. Add `inputs.lanzaboote.nixosModules.lanzaboote` to the host's `modules` list in [`flake.nix`](../flake.nix)
2. Create `hosts/<hostname>/secure-boot.nix` — copy from [`hosts/adlerkopf/secure-boot.nix`](../hosts/adlerkopf/secure-boot.nix)
3. Change `boot.loader.systemd-boot.enable = true` to `boot.loader.systemd-boot.enable = lib.mkDefault true` in the host's `hardware.nix`
4. Import `./secure-boot.nix` in `hosts/<hostname>/default.nix`
5. Add VM variant overrides (disable lanzaboote, re-enable systemd-boot) in `virtualisation.vmVariant`
6. Add `"/var/lib/sbctl"` to `environment.persistence."/persist/system".directories` in the host's `impermanence.nix` (if impermanence is active)
7. Deploy with `nixos-rebuild switch --flake .#<hostname>` (Secure Boot still off in firmware)
8. Follow this runbook from Step 1

---

## References

- [lanzaboote documentation](https://github.com/nix-community/lanzaboote)
- [lanzaboote quick-start](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)
- [sbctl documentation](https://github.com/Foxboron/sbctl)
- [NixOS Wiki: Secure Boot](https://wiki.nixos.org/wiki/Secure_Boot)
- Internal: [`docs/plans/adlerkopf/01a-secure-boot-plan.md`](plans/adlerkopf/01a-secure-boot-plan.md)
