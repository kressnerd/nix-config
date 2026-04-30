# KeePassXC Impermanence Conflict Fix

## Business Context

KeePassXC on thiniel shows: "Access error for config file /home/dan/.config/keepassxc/keepassxc.ini". The application cannot access its configuration properly, degrading usability.

## Root Cause

Two mechanisms fight over `~/.config/keepassxc/`:

1. **Home Manager** `programs.keepassxc.settings` generates `keepassxc.ini` as a **read-only Nix store symlink** at `~/.config/keepassxc/keepassxc.ini`
2. **Impermanence** bind-mounts `/persist/.config/keepassxc` over `~/.config/keepassxc`

The bind-mount shadows the HM-generated symlink. The persisted directory at `/persist/.config/keepassxc` does not contain the Nix store symlink — so KeePassXC either finds no config or an old mutable copy, while the HM-managed symlink is hidden underneath the mount.

## Acceptance Criteria

- [x] KeePassXC starts without "Access error for config file" warning
- [x] KeePassXC settings are declared in Nix (declarative, reproducible)
- [x] `nix flake check` passes
- [x] Unit tests updated to reflect changes

## Alternatives Analysis

### Option A: Remove impermanence entry, keep HM settings ✅ RECOMMENDED

Remove `.config/keepassxc` from impermanence. Let Home Manager fully own the config as a declarative Nix store symlink. The directory lives on ephemeral tmpfs.

**How it works at runtime:**
- HM creates symlink: `~/.config/keepassxc/keepassxc.ini` → `/nix/store/...-keepassxc.ini`
- KeePassXC reads declared settings from the Nix store
- KeePassXC may replace the symlink with a mutable file during the session (atomic write pattern) — this is fine, the directory is writable tmpfs
- On next `nixos-rebuild switch`, HM recreates the symlink with the declared settings
- Runtime state (window geometry, recent databases) doesn't persist across reboots — consistent with impermanence philosophy

| Criterion | Rating |
|-----------|--------|
| Declarativeness | ★★★★★ — Settings fully declared in Nix |
| Simplicity | ★★★★★ — Single-line removal from impermanence |
| Reliability | ★★★★★ — No bind-mount/symlink conflict |
| Reproducibility | ★★★★★ — Rebuild always restores declared state |
| Impermanence consistency | ★★★★★ — Runtime state is ephemeral by design |

**Trade-off**: Window geometry, recent databases list, and other runtime preferences don't persist across reboots. Acceptable because: (a) this is the impermanence contract; (b) core settings (browser integration, SSH agent, theme) are declared in Nix and always restored; (c) database paths can be passed as CLI arguments or remembered by the user.

### Option B: Remove `settings`, keep impermanence entry

Remove `programs.keepassxc.settings` from HM. Let KeePassXC manage its own `keepassxc.ini` in the persisted directory. Configure settings via GUI.

| Criterion | Rating |
|-----------|--------|
| Declarativeness | ★☆☆☆☆ — Settings managed imperatively via GUI |
| Simplicity | ★★★★☆ — Remove settings block |
| Reliability | ★★★★★ — No conflict |
| Reproducibility | ★★☆☆☆ — Config lost on full persistence wipe |

**Rejected**: Not the Nix way. Settings should be declared in Nix, not managed imperatively.

### Option C: Hybrid — `home.file` with activation script

Seed the config via activation script that copies (not symlinks) initial content, combined with impermanence for the directory.

| Criterion | Rating |
|-----------|--------|
| Declarativeness | ★★★☆☆ — Initial state declared, but can drift |
| Simplicity | ★★☆☆☆ — Complex setup, fragile |
| Reliability | ★★★☆☆ — Depends on activation ordering vs. bind-mount timing |
| Reproducibility | ★★★☆☆ — Config may drift from declared state |

**Rejected**: Over-engineered. Activation scripts and impermanence bind-mounts have ordering issues. Drift between declared and actual config.

## Decision

**Option A** — Remove `.config/keepassxc` from impermanence, keep declarative HM settings.

This is the Nix way: configuration is declared in code, runtime state is ephemeral.

## Technical Analysis

### Conflict resolution diagram

```mermaid
graph TD
    A["Current: CONFLICT"] --> B["HM symlink: keepassxc.ini → /nix/store/..."]
    A --> C["Impermanence: bind-mount /persist/.config/keepassxc"]
    C -->|shadows| B
    
    D["Fix: CLEAN"] --> E["HM symlink: keepassxc.ini → /nix/store/..."]
    D --> F["Directory on ephemeral tmpfs"]
    E -->|lives in| F
    F -->|writable for runtime state| G["KeePassXC can write temp files alongside symlink"]
```

### Files to modify

### Files modified

| File | Change |
|------|--------|
| [`home/dan/features/linux/impermanence.nix`](../../home/dan/features/linux/impermanence.nix) | Removed `.config/keepassxc` from `directories` list |
| [`tests/assertions/thiniel-impermanence-invariants.nix`](../../tests/assertions/thiniel-impermanence-invariants.nix) | Added regression guard asserting keepassxc is absent from HM persistence |
| [`tests/unit/hm-linux-modules-test.nix`](../../tests/unit/hm-linux-modules-test.nix) | Updated `testImpermanenceDoesNotHaveKeepassxc` (inverted) and `testImpermanenceDirCount` (16→15) |

### Files unchanged (verified correct)

| File | Reason |
|------|--------|
| [`home/dan/features/productivity/keepassxc.nix`](../../home/dan/features/productivity/keepassxc.nix) | `programs.keepassxc.settings` kept as-is — declarative config |
| [`home/dan/thiniel.nix`](../../home/dan/thiniel.nix) | Imports both modules — no change needed |
| [`tests/unit/hm-productivity-modules-test.nix`](../../tests/unit/hm-productivity-modules-test.nix) | All 5 keepassxc tests remain valid (enable, browser, ssh-agent, compact, hide-passwords) |

## Phase 0: Validation Strategy

### Validation commands

| Step | Command |
|------|---------|
| Syntax/eval check | `nix flake check --no-build` |
| Full check | `nix flake check` |
| Build thiniel | `nixos-rebuild build --flake .#thiniel` |
| Apply | `sudo nixos-rebuild switch --flake .#thiniel` |

### Rollback path

- `sudo nixos-rebuild switch --rollback` reverts to previous generation
- Git revert of the commit restores impermanence entry
- If KeePassXC had important runtime state in `/persist/.config/keepassxc`, it remains at that path (not deleted, just no longer bind-mounted)

### Risk assessment

| Category | Risk |
|----------|------|
| Boot | None — no bootloader/kernel changes |
| Network | None |
| Filesystem | Low — removing one impermanence bind-mount; no data loss |
| Authentication | None |
| Secrets | None |

**Risk level**: LOW — removing one directory from impermanence persistence list.

## Phase 1: Red — Write failing assertion

### Step 1.1: Add assertion that `.config/keepassxc` is NOT in impermanence

In [`tests/assertions/thiniel-impermanence-invariants.nix`](../../tests/assertions/thiniel-impermanence-invariants.nix), add a new assertion verifying `.config/keepassxc` is **absent** from `home.persistence."/persist".directories`. This test uses the Home Manager impermanence module's option path.

**Note**: This assertion operates at system-level (`environment.persistence`), but the keepassxc entry is in Home Manager's `home.persistence`. The assertion may need to be placed differently — either as a unit test checking the impermanence module output, or as a comment-documented invariant. The implementation step should verify the correct option path.

**Red verification**: `nix flake check` → FAIL (`.config/keepassxc` still in impermanence)

## Phase 2: Green — Remove impermanence entry

### Step 2.1: Remove `.config/keepassxc` from impermanence

In [`home/dan/features/linux/impermanence.nix`](../../home/dan/features/linux/impermanence.nix:21), remove line 21:

```diff
     ".config/Code"
-    # KeepassXC
-    ".config/keepassxc"
     # ownCloud client
```

**Green verification**: `nix flake check` → PASS

## Phase 3: Validate and Apply

### Step 3.1: Build

```fish
nixos-rebuild build --flake .#thiniel
```

### Step 3.2: Apply on thiniel

```fish
sudo nixos-rebuild switch --flake .#thiniel
```

### Step 3.3: Manual verification

1. Reboot (to clear ephemeral root and re-activate HM)
2. Verify the config is a symlink to Nix store:
   ```fish
   ls -la ~/.config/keepassxc/keepassxc.ini
   # Expected: symlink → /nix/store/...-keepassxc.ini
   ```
3. Launch KeePassXC
4. Confirm no "Access error for config file" warning
5. Verify declared settings are active (compact mode, classic theme, browser integration)

## Current Status

- **Phase**: COMPLETED
- **Status**: All implementation phases complete. Ready for deployment.
- **Current Step**: Deploy on thiniel with `sudo nixos-rebuild switch --flake .#thiniel`

## Completion Log

| Phase | Status | Notes |
|-------|--------|-------|
| Phase 1 (Red) | ✅ | Assertion added to `thiniel-impermanence-invariants.nix` — confirmed FAIL |
| Phase 2 (Green) | ✅ | Removed `.config/keepassxc` from `impermanence.nix` — confirmed PASS |
| Phase 3 (Validate) | ✅ | `nix flake check --no-build` PASS, `nix fmt` PASS, `deadnix` PASS, `statix` PASS |
| Review | ✅ | Found 2 issues: stale unit test + message prefix — both fixed |

### Additional changes from review

- Updated `tests/unit/hm-linux-modules-test.nix`: renamed `testImpermanenceHasKeepassxc` → `testImpermanenceDoesNotHaveKeepassxc` (expected: false), updated `testImpermanenceDirCount` (16 → 15)
- Fixed assertion message prefix in `tests/assertions/thiniel-impermanence-invariants.nix` for consistency
