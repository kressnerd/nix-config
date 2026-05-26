# Plan: Enable Secure Boot via lanzaboote on `adlerkopf`

**Status**: IN PROGRESS — phases 1–7 complete, Phase 8 (post-deploy) pending
**Plan ID**: `adlerkopf/01a-secure-boot`
**Target host**: `adlerkopf` (Lenovo ThinkCentre M920q, x86_64-linux, UEFI)
**Depends on**: [`docs/plans/adlerkopf/01-base-os.md`](01-base-os.md) (TPM2 + LUKS already in place)

---

## 1. Goal

Replace `systemd-boot` with [lanzaboote](https://github.com/nix-community/lanzaboote) on `adlerkopf` so the kernel + initrd are signed and verified by UEFI Secure Boot. After Secure Boot is enabled in firmware, only kernels signed by the host's locally-generated key chain (managed via `sbctl`) will boot.

This change also unlocks the TPM2 PCR 7 measurement (Secure Boot policy) for the LUKS auto-unlock, allowing the cryptenroll policy `--tpm2-pcrs=0+2+7` documented in [`01-base-os.md`](01-base-os.md:67) to be tamper-evident against bootloader replacement.

## 2. Business Context

- **Problem solved**: Without Secure Boot, an attacker with brief physical access can boot an arbitrary kernel/initrd (e.g., from USB or by replacing files on the unencrypted ESP) and capture the LUKS passphrase or modify the system before sealing. PCR 7 in the TPM enroll is meaningless until UEFI actually enforces the boot policy.
- **Why lanzaboote** (vs. Microsoft-signed shim): keeps the supply chain fully under our key — no third-party trust anchor; aligns with the declarative-first principle (boot chain is a derivation, not a manually-managed shim).
- **Scope boundary**: This plan covers only `adlerkopf`. No other host is touched. No shared module is introduced (YAGNI — first integration, see [`.roo/rules/05-fundamental-principles.md`](../../../.roo/rules/05-fundamental-principles.md:36) Rule of Three).

## 3. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|--------------|
| AC1 | `nix flake check` passes on a clean tree | `nix flake check` |
| AC2 | `nixosConfigurations.adlerkopf` builds end-to-end | `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel` |
| AC3 | `boot.lanzaboote.enable = true` on `adlerkopf` (real boot, not VM) | Assertion in [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix) |
| AC4 | `boot.loader.systemd-boot.enable = false` on `adlerkopf` (real boot) | Same assertion file |
| AC5 | `boot.loader.systemd-boot.enable = true` AND `boot.lanzaboote.enable = false` in the VM variant | Build of `nixosConfigurations.adlerkopf.config.virtualisation.vmVariant` succeeds |
| AC6 | `/var/lib/sbctl` is in `environment.persistence."/persist/system".directories` | Read `hosts/adlerkopf/impermanence.nix` |
| AC7 | ESP generation budget is capped (`configurationLimit ≤ 5`) so signed kernels do not overflow 512 MiB ESP | Read `hosts/adlerkopf/secure-boot.nix` |
| AC8 | Post-deploy: `sbctl verify` reports all bundles `signed` | Manual, post-deploy step 4 |
| AC9 | Post-deploy: `bootctl status` shows `Secure Boot: enabled` and `Setup Mode: user` | Manual, post-deploy step 6 |
| AC10 | [`docs/plans/adlerkopf/01-base-os.md`](01-base-os.md) TPM section cross-links this plan and confirms PCR 7 inclusion | Diff of `01-base-os.md` |

## 4. Technical Analysis

### 4.1 What lanzaboote does

lanzaboote replaces `systemd-boot` with a stub loader that:
1. Bundles the kernel + initrd + cmdline into a single Unified Kernel Image (UKI) per generation.
2. Signs the UKI at system build time with the keys in `pkiBundle` (default `/var/lib/sbctl`).
3. Lets UEFI firmware verify the signature against the platform key (PK) and key-exchange-key (KEK) chain that `sbctl enroll-keys` installed.

The Nix module replaces `systemd-boot` entirely. Both must NOT be enabled simultaneously — lanzaboote will refuse to evaluate.

### 4.2 Files changed and why

| File | Change | Rationale |
|------|--------|-----------|
| [`flake.nix`](../../../flake.nix:35) | Add `lanzaboote` input pinned to `v0.4.2`; pass `lanzaboote.nixosModules.lanzaboote` into `nixosConfigurations.adlerkopf.modules` only | New flake dependency; module must be imported per-host to keep blast radius minimal |
| `hosts/adlerkopf/secure-boot.nix` *(NEW)* | Declare `boot.loader.systemd-boot.enable = lib.mkForce false`, `boot.lanzaboote = { enable = true; pkiBundle = "/var/lib/sbctl"; }`, `boot.loader.systemd-boot.configurationLimit = 5` | Single responsibility per [`11-repository-conventions.md`](../../../.roo/rules/11-repository-conventions.md); peer of `tpm2.nix`, `caddy.nix`, etc. |
| [`hosts/adlerkopf/default.nix`](../../../hosts/adlerkopf/default.nix:16) | Add `./secure-boot.nix` to `imports`; in `virtualisation.vmVariant` override `boot.lanzaboote.enable = lib.mkForce false` and `boot.loader.systemd-boot.enable = lib.mkForce true` | Wire the new file; keep VM variant bootable without sbctl PKI |
| [`hosts/adlerkopf/hardware.nix`](../../../hosts/adlerkopf/hardware.nix:14) | Change `boot.loader.systemd-boot.enable = true;` → `boot.loader.systemd-boot.enable = lib.mkDefault true;` (so `secure-boot.nix` can override without conflict in eval). `boot.loader.efi.canTouchEfiVariables = true;` stays. | `mkDefault` lets the secure-boot module use `mkForce false` cleanly; VM variant continues to inherit `true` |
| [`hosts/adlerkopf/impermanence.nix`](../../../hosts/adlerkopf/impermanence.nix:22) | Add `"/var/lib/sbctl"` to `directories` | Without persistence, sbctl keys are wiped on every boot → next `nixos-rebuild switch` fails to sign UKIs |
| [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix:8) | Add two assertions (lanzaboote enabled, systemd-boot disabled) gated on `!config.adlerkopf.vmMode` | Eval-time invariant per [`13-test-first.md`](../../../.roo/rules/13-test-first.md) |
| [`docs/plans/adlerkopf/01-base-os.md`](01-base-os.md:74) | Update PCR 7 footnote to link this plan and state that SB is now declaratively enabled | DRY — single source of truth on TPM policy |

### 4.3 Risks

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| SB1 | sbctl keys not generated before first boot with `lanzaboote.enable = true` → system signs UKIs with an empty PKI bundle and SB-enabled firmware rejects them | High if procedure skipped | System unbootable (need recovery media) | Two-stage rollout: deploy lanzaboote **with SB disabled in firmware first**; run `sbctl create-keys` + `sbctl enroll-keys`; only then flip SB on in firmware (see Phase 8 manual steps) |
| SB2 | `/var/lib/sbctl` not persisted → keys lost on next boot via impermanence rollback | High if Phase 3 skipped | All future rebuilds fail to produce a bootable UKI | Phase 3 adds the path; Phase 5 assertion does NOT catch this (assertion is on enable flag, not persistence wiring) — runbook callout in Phase 8 |
| SB3 | ESP fills up because every signed generation also stores its UKI (~80–120 MiB each) | Medium | `nixos-rebuild switch` fails with "no space left on device" | Phase 6 caps `configurationLimit = 10` (≤ ~1.2 GiB worst case — fits 512 MiB only with limit reduced; see Phase 6 sub-analysis) |
| SB4 | Firmware update changes PK or wipes Setup Mode → SB keys must be re-enrolled | Low | One-time recovery via firmware reset to Setup Mode + `sbctl enroll-keys` | Documented in Phase 8 + already covered by [`risks.md`](risks.md) R1/R2 |
| SB5 | Microsoft KEK not enrolled → external option ROMs (e.g., dGPU, NIC PXE) refuse to load | Low (no dGPU on M920q iGPU-only) | Cosmetic on this host; severe on hardware with signed option ROMs | `sbctl enroll-keys --microsoft` is the post-deploy default; documented in Phase 8 |
| SB6 | lanzaboote v0.4.2 incompatible with nixpkgs `nixos-25.11` | Low (v0.4.2 declares 25.05 + 25.11 support in its README) | `nix flake check` fails | Phase 1 validation catches this immediately; rollback = revert flake input |

### 4.4 ESP capacity sub-analysis (justifies Phase 6)

- ESP size: 512 MiB ([`hosts/adlerkopf/disko.nix:16`](../../../hosts/adlerkopf/disko.nix))
- Per-generation lanzaboote UKI footprint: kernel (~13 MiB) + initrd (~80–120 MiB with `initrd.systemd.enable`) + stub ≈ 100–140 MiB
- Worst-case budget at `configurationLimit = 10`: ~1.0–1.4 GiB → **does NOT fit**
- Decision: set `configurationLimit = 5` for adlerkopf to keep worst case under ~700 MiB and average closer to ~500 MiB. NixOS `garbage-collector` still keeps `/nix/store` generations; this only bounds the ESP.
- Trade-off: only 5 rollback targets at the bootloader menu — acceptable for a single-admin server. Recovery via netboot/install media is always available.

## 5. Validation Strategy (Phase 0)

### Validation commands

| Layer | Command | When |
|-------|---------|------|
| Syntax | `nix flake check` | After every phase that touches `.nix` |
| Eval (assertions fire) | `nix flake check --no-build` | After Phase 5 |
| Build (real host) | `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel --no-link` | After every phase that touches `hosts/adlerkopf/` |
| Build (VM variant) | `nix build .#nixosConfigurations.adlerkopf.config.virtualisation.vmVariant.system.build.toplevel --no-link` | After Phase 4 |
| Format | `nix fmt` | After every code change |
| Lint | `statix check` and `deadnix` on touched files | After every code change |

### Affected hosts

- `adlerkopf` (only). All other `nixosConfigurations` MUST continue to build unchanged — verified by `nix flake check` building every config in `checks.*`.

### Dangerous-change classification

| Category | This change touches it? |
|----------|------------------------|
| Boot | **YES** — bootloader swap (HIGH RISK) |
| Network | No |
| Filesystem | No |
| Authentication | No |
| Secrets | No (sbctl keys are local-only, not committed) |

→ Explicit user approval required before Phase 8 (firmware Secure Boot enable). Phases 1–7 are reversible by removing the import / reverting commits.

### Rollback procedure

See Section 7 below.

## 6. Implementation Phases

Each phase is one Red-Green-Refactor cycle per [`13-test-first.md`](../../../.roo/rules/13-test-first.md). Commits per [`.roo/rules/02-commits.md`](../../../.roo/rules/02-commits.md). Phases 1–7 are declarative; Phase 8 is the manual post-deploy.

### Phase 1 — Add `lanzaboote` flake input and wire module into `adlerkopf`

- [x] **Red**: Run `nix flake check`. Confirm it currently passes (baseline). Add a deliberately failing assertion stub `assertion = config ? boot.lanzaboote;` to [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix). Run `nix flake check` → expect FAIL with "unable to evaluate" or assertion failure on adlerkopf. **(Stub assertion is temporary; replaced in Phase 5.)**
- [x] **Green**:
  - Add to `flake.nix` inputs:
    ```nix
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ```
  - Add to `nixosConfigurations.adlerkopf.modules`:
    ```nix
    inputs.lanzaboote.nixosModules.lanzaboote
    ```
    (Insert AFTER `./hosts/adlerkopf` and BEFORE `disko.nixosModules.disko` to keep ordering consistent.)
  - Remove the stub assertion from Phase 1 Red.
  - Run `nix flake check`.
- [x] **Refactor**: Verify `flake.lock` updated cleanly; no stray inputs. Run `nix fmt`, `statix check`, `deadnix`.
- [x] **Commit**: `feat(adlerkopf): add lanzaboote flake input`

**Verify**: `nix flake check` PASS. `nix eval .#nixosConfigurations.adlerkopf.options.boot.lanzaboote.enable.type` returns `bool` (option now visible).

### Phase 2 — Create `hosts/adlerkopf/secure-boot.nix` and import it

- [x] **Red**: Add to [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix):
  ```nix
  {
    assertion = config.adlerkopf.vmMode || config.boot.lanzaboote.enable;
    message = "adlerkopf: lanzaboote must be enabled on real host";
  }
  ```
  Run `nix flake check` → expect FAIL ("lanzaboote must be enabled on real host").
- [x] **Green**:
  - Change [`hosts/adlerkopf/hardware.nix:14`](../../../hosts/adlerkopf/hardware.nix) `systemd-boot.enable = true;` → `systemd-boot.enable = lib.mkDefault true;` (add `lib` to function arguments).
  - Create `hosts/adlerkopf/secure-boot.nix`:
    ```nix
    { lib, ... }:
    {
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
    }
    ```
  - Add `./secure-boot.nix` to `imports` in [`hosts/adlerkopf/default.nix`](../../../hosts/adlerkopf/default.nix:16) (insert AFTER `./tpm2.nix`, BEFORE `./impermanence.nix`).
  - Run `nix flake check`.
- [x] **Refactor**: `nix fmt`, `statix check`, `deadnix`.
- [x] **Commit**: `feat(adlerkopf): replace systemd-boot with lanzaboote`

**Verify**: `nix flake check` PASS. `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel --no-link` succeeds. The new assertion now passes.

### Phase 3 — Persist `/var/lib/sbctl`

- [x] **Red**: Add assertion to [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix):
  ```nix
  {
    assertion =
      config.adlerkopf.vmMode
      || builtins.elem "/var/lib/sbctl" config.environment.persistence."/persist/system".directories;
    message = "adlerkopf: /var/lib/sbctl must be persisted for lanzaboote signing keys";
  }
  ```
  Run `nix flake check` → expect FAIL.
- [x] **Green**: Add `"/var/lib/sbctl"` to the `directories` list in [`hosts/adlerkopf/impermanence.nix:22`](../../../hosts/adlerkopf/impermanence.nix). Keep the list alphabetically grouped (the existing list is loosely grouped — append at the end is acceptable).
- [x] **Refactor**: `nix fmt`, `statix check`, `deadnix`.
- [x] **Commit**: `feat(adlerkopf): persist /var/lib/sbctl for lanzaboote PKI`

**Verify**: `nix flake check` PASS.

### Phase 4 — VM variant override (keep VM bootable without sbctl)

- [x] **Red**: Run `nix build .#nixosConfigurations.adlerkopf.config.virtualisation.vmVariant.system.build.toplevel --no-link`. **Expected**: FAIL — `boot.lanzaboote.enable = true` on a VM without sbctl PKI bundle path will error (lanzaboote module performs an `assertion` on pkiBundle existence at build time, OR the VM build will succeed but the resulting image cannot boot). Capture the actual error.
- [x] **Green**: In [`hosts/adlerkopf/default.nix`](../../../hosts/adlerkopf/default.nix:87) `virtualisation.vmVariant.boot` block, add:
  ```nix
  lanzaboote.enable = lib.mkForce false;
  loader.systemd-boot.enable = lib.mkForce true;
  ```
  (The `loader.systemd-boot.enable` re-force is needed because `secure-boot.nix` sets `mkForce false`; the VM needs systemd-boot back.)
  Run `nix build .#nixosConfigurations.adlerkopf.config.virtualisation.vmVariant.system.build.toplevel --no-link` → expect PASS.
- [x] **Refactor**: `nix fmt`, `statix check`, `deadnix`. Confirm the assertions from Phases 2 and 3 still pass (they are gated on `!vmMode`).
- [x] **Commit**: `feat(adlerkopf): disable lanzaboote in VM variant`

**Verify**: Both real-host and VM-variant builds succeed. `nix flake check` PASS.

### Phase 5 — Strengthen the lanzaboote assertion (cover both enable + disable)

- [x] **Red**: Add a second assertion to [`tests/assertions/adlerkopf-invariants.nix`](../../../tests/assertions/adlerkopf-invariants.nix):
  ```nix
  {
    assertion = config.adlerkopf.vmMode || !config.boot.loader.systemd-boot.enable;
    message = "adlerkopf: systemd-boot must be disabled on real host (lanzaboote replaces it)";
  }
  ```
  Temporarily comment out the `mkForce false` line in `secure-boot.nix` → expect `nix flake check` FAIL.
- [x] **Green**: Restore `mkForce false`. Run `nix flake check` → PASS.
- [x] **Refactor**: Group the three lanzaboote-related assertions visually in the file (consecutive list entries). `nix fmt`.
- [x] **Commit**: `test(adlerkopf): assert systemd-boot disabled when lanzaboote enabled`

**Verify**: `nix flake check` PASS. Three assertions present: lanzaboote enabled, systemd-boot disabled, sbctl persisted.

### Phase 6 — Cap ESP generation count

- [x] **Red**: Read `nix eval .#nixosConfigurations.adlerkopf.config.boot.loader.systemd-boot.configurationLimit` — capture current default (likely `null` = unlimited). Add a temporary throw-away assertion `assertion = (config.boot.loader.systemd-boot.configurationLimit or 0) > 0;` → expect FAIL.
- [x] **Green**: Add to `hosts/adlerkopf/secure-boot.nix`:
  ```nix
  boot.loader.systemd-boot.configurationLimit = 5;
  ```
  (Even though `systemd-boot.enable = false`, `configurationLimit` is read by lanzaboote to bound the number of UKIs it writes to the ESP — confirmed in lanzaboote module source.)
  Remove the throw-away assertion.
  Run `nix flake check`.
- [x] **Refactor**: `nix fmt`. Add a one-line comment above `configurationLimit` referencing the ESP capacity analysis (Section 4.4 of this plan).
- [x] **Commit**: `chore(adlerkopf): cap ESP generation count to 5`

**Verify**: `nix flake check` PASS. `nix eval .#nixosConfigurations.adlerkopf.config.boot.loader.systemd-boot.configurationLimit` = `5`.

### Phase 7 — Cross-link `01-base-os.md`

- [x] **Red**: Skipped — documentation-only change exempt per [`13-test-first.md`](../../../.roo/rules/13-test-first.md) Exceptions.
- [x] **Green**: Edit [`docs/plans/adlerkopf/01-base-os.md`](01-base-os.md:74) PCR 7 bullet to read:
  > `7` — Secure Boot policy. Now declaratively enabled via lanzaboote on `adlerkopf` (see [`01a-secure-boot-plan.md`](01a-secure-boot-plan.md)). Use `--tpm2-pcrs=0+2+7` for cryptenroll.
  Remove the conditional "omit if SB is off" wording for adlerkopf.
- [x] **Refactor**: None.
- [x] **Commit**: `docs(adlerkopf): cross-link secure-boot plan from 01-base-os`

**Verify**: Manual read of `01-base-os.md`.

### Phase 8 — Manual post-deploy (operator runbook, NOT a code phase)

> **⚠️ DANGEROUS** — bootloader transition. Requires physical or out-of-band access to firmware. Get explicit operator go/no-go before starting.

**Pre-conditions**: Phases 1–7 merged. `nixos-rebuild switch --flake .#adlerkopf` succeeded once with **Secure Boot still DISABLED in firmware** (lanzaboote runs as plain loader, no signature enforcement yet).

1. **Verify lanzaboote is running**:
   ```fish
   bootctl status
   ```
   Expected: bootloader line shows `systemd-stub` / lanzaboote stub. `Secure Boot: disabled (setup)` or `disabled`.

2. **Create local signing keys** (one-shot, on the host):
   ```fish
   sudo sbctl create-keys
   ```
   Output goes to `/var/lib/sbctl/keys/`. Confirm directory is on the persisted mount: `findmnt /var/lib/sbctl` (should resolve via the impermanence bind mount to `/persist/system/var/lib/sbctl`).

3. **Enroll keys into firmware** (firmware must be in Setup Mode — see BIOS step 5):
   ```fish
   sudo sbctl enroll-keys --microsoft
   ```
   `--microsoft` adds the Microsoft KEK so that signed third-party option ROMs continue to function (defense in depth — even though M920q iGPU does not need it, the cost is zero).

4. **Re-sign existing UKIs** and verify:
   ```fish
   sudo nixos-rebuild switch --flake .#adlerkopf
   sudo sbctl verify
   ```
   Expected: every file under `/boot/EFI/Linux/*.efi` and `/boot/EFI/BOOT/BOOTX64.EFI` reported as `signed`.

5. **Enable Secure Boot in BIOS** (Lenovo M920q): reboot → F1 → Security → Secure Boot → **Enabled** → set firmware to **User Mode** (exits Setup Mode after PK enrollment). Save and exit.

6. **Post-boot verification**:
   ```fish
   bootctl status
   # Expected lines:
   #   Secure Boot: enabled (user)
   #   Setup Mode: user
   ```

7. **Re-enroll TPM2 with PCR 7** (now that SB is enforcing):
   ```fish
   sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/disk/by-partlabel/cryptroot
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/disk/by-partlabel/cryptroot
   ```
   Reboot and confirm LUKS auto-unlock still works without passphrase prompt.

8. **Commit any operational notes** to [`docs/plans/adlerkopf/deploy-runbook.md`](deploy-runbook.md) if procedure deviated from this plan.

## 7. Rollback Plan

Rollback path depends on which phase failed.

### Rollback during Phases 1–7 (pre-firmware-flip)

All changes are declarative. Revert the offending commit(s) and `nixos-rebuild switch --flake .#adlerkopf` returns the system to `systemd-boot`. The ESP retains the previous `systemd-boot` entries until pruned, so the next boot continues working.

### Rollback after Phase 8 step 5 (Secure Boot enabled, system won't boot)

System symptom: firmware rejects all UKIs with "Security Violation".

1. **Immediate recovery** (no data loss): Reboot → F1 → Security → Secure Boot → **Disabled** → save & exit. System boots normally via lanzaboote stub (signature ignored). LUKS auto-unlock will fail PCR 7 check → use recovery passphrase from 1Password (slot 0, per [`01-base-os.md`](01-base-os.md:76)).
2. **Re-enroll keys**: from inside the running system, repeat Phase 8 steps 2–4.
3. **Re-attempt Phase 8 step 5**.

### Rollback after Phase 8 step 7 (TPM PCR 7 re-enroll, system asks for LUKS passphrase forever)

1. Boot with recovery passphrase.
2. Investigate: `systemd-cryptenroll --tpm2-device=auto /dev/disk/by-partlabel/cryptroot` to list enrolled slots; `systemd-analyze pcrs` to inspect current PCR values.
3. Either re-enroll with the correct PCR set, or fall back to `--tpm2-pcrs=0+2` (drops SB measurement; documented in [`risks.md`](risks.md) R2).

### Full nuclear rollback (lanzaboote itself is broken)

1. Boot from NixOS installer USB.
2. Mount `/persist`, `/nix`, and ESP.
3. `nixos-enter` and run `nixos-rebuild switch --flake .#adlerkopf --rollback` OR revert the flake commits and rebuild.
4. Disable Secure Boot in BIOS.
5. Manually clear lanzaboote UKIs from ESP if needed: `rm /boot/EFI/Linux/*.efi`.

## 8. Current Status

| Phase | Status |
|-------|--------|
| Phase 0 — Validation strategy defined | ✅ Documented (this file) |
| Phase 1 — flake input + wire module | ✅ Complete |
| Phase 2 — `secure-boot.nix` + replace systemd-boot | ✅ Complete |
| Phase 3 — persist `/var/lib/sbctl` | ✅ Complete |
| Phase 4 — VM variant override | ✅ Complete |
| Phase 5 — assertion strengthening | ✅ Complete |
| Phase 6 — ESP generation cap | ✅ Complete |
| Phase 7 — `01-base-os.md` cross-link | ✅ Complete |
| Phase 8 — manual post-deploy (operator) | ⏳ Manual — post-deploy operator steps |

## 9. Completion Log

*(To be filled in as phases complete.)*

## 10. References

- lanzaboote upstream: <https://github.com/nix-community/lanzaboote>
- lanzaboote quick-start: <https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md>
- NixOS manual on Secure Boot: <https://nixos.wiki/wiki/Secure_Boot> (community wiki — verify against upstream module options before relying)
- `sbctl` upstream: <https://github.com/Foxboron/sbctl>
- Internal: [`docs/plans/adlerkopf/01-base-os.md`](01-base-os.md), [`docs/plans/adlerkopf/deploy-runbook.md`](deploy-runbook.md), [`docs/plans/adlerkopf/risks.md`](risks.md)
- Rules: [`.roo/rules/10-nix-senior-admin.md`](../../../.roo/rules/10-nix-senior-admin.md), [`.roo/rules/13-test-first.md`](../../../.roo/rules/13-test-first.md), [`.roo/rules-architect/02-validation-first.md`](../../../.roo/rules-architect/02-validation-first.md)
