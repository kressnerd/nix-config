# Seahorse GUI — Implementation Plan

## Goal

Enable Seahorse (GNOME keyring GUI) on the thiniel host so the user can manage gnome-keyring secrets via a graphical interface under Hyprland.

## Context

- gnome-keyring is fully configured on thiniel (system service, PAM auto-unlock, HM user service, impermanence persistence)
- Hyprland is the window manager; Seahorse works on Wayland without a full GNOME session
- `programs.seahorse.enable` is a NixOS option — no Home Manager equivalent exists
- Existing assertion tests in [`tests/assertions/thiniel-invariants.nix`](../../tests/assertions/thiniel-invariants.nix) cover gnome-keyring (lines 51–57)

## Acceptance Criteria

1. `programs.seahorse.enable` is `true` in [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix)
2. `nix flake check` passes with a new assertion verifying Seahorse is enabled
3. `nixos-rebuild build --flake .#thiniel` succeeds
4. Existing gnome-keyring and Hyprland configuration remains unchanged

## Technical Analysis

`programs.seahorse.enable` does three things:

- Adds `pkgs.seahorse` to `environment.systemPackages`
- Registers Seahorse D-Bus services
- Sets `programs.ssh.askPassword` to the Seahorse SSH askpass helper

No additional GNOME components are required — gnome-keyring-daemon is already on D-Bus.

### Risk Assessment

| Category | Risk |
|----------|------|
| Boot | None |
| Network | None |
| Filesystem | None |
| Authentication | None |
| Side effect | `programs.ssh.askPassword` changes to Seahorse's helper — harmless, provides GUI SSH passphrase prompt |

## Phase 0: Validation Strategy

### Validation commands

- Syntax/eval: `nix flake check --no-build`
- Build: `nixos-rebuild build --flake .#thiniel`
- Apply: `sudo nixos-rebuild switch --flake .#thiniel` (on thiniel)

### Rollback

Revert the two changes (assertion + option) and rebuild. No dangerous change category applies.

## Phase 1: Red — Failing Assertion

**TDD Cycle 1 — Red**

### Step 1.1

Add assertion to [`tests/assertions/thiniel-invariants.nix`](../../tests/assertions/thiniel-invariants.nix) after the existing gnome-keyring assertions (after line 57):

```nix
{
  assertion = config.programs.seahorse.enable;
  message = "thiniel: programs.seahorse must be enabled for GUI gnome-keyring management.";
}
```

### Step 1.2 — Verify Red

```bash
nix flake check --no-build
```

Expected: FAIL — assertion fires because `programs.seahorse.enable` defaults to `false`.

## Phase 2: Green — Enable Seahorse

**TDD Cycle 1 — Green**

### Step 2.1

Add to [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix), adjacent to the gnome-keyring line (after line 233):

```nix
# GUI for managing gnome-keyring secrets
programs.seahorse.enable = true;
```

### Step 2.2 — Verify Green

```bash
nix flake check --no-build
nixos-rebuild build --flake .#thiniel
```

Expected: both PASS.

## Phase 3: Apply & Verify

### Step 3.1

```bash
sudo nixos-rebuild switch --flake .#thiniel
```

### Step 3.2

Verify Seahorse launches: `seahorse` from terminal or app launcher.

## Current Status

- [x] Phase 1: Red — add assertion
- [x] Phase 2: Green — enable Seahorse
- [ ] Phase 3: Apply & verify (pending on-host deployment)

## Completion Summary

**Date**: 2026-04-13

All implementation steps completed with no deviations from the plan:

- Assertion added to [`tests/assertions/thiniel-invariants.nix`](../../tests/assertions/thiniel-invariants.nix) (Red phase confirmed failing)
- `programs.seahorse.enable = true;` added to [`hosts/thiniel/default.nix`](../../hosts/thiniel/default.nix) (Green phase confirmed passing)
- `nix flake check` passed
- `nixos-rebuild build --flake .#thiniel` passed
- Committed as `feat(thiniel): enable seahorse as gnome-keyring GUI`

Phase 3 (on-host `nixos-rebuild switch`) remains to be executed on the thiniel machine.
