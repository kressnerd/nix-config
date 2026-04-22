# Firefox "no-tracking" Profile — Implementation Plan

## Status: COMPLETED (2026-04-22)

## Goal

Add a second Firefox profile named `no-tracking` to the thiniel host. This profile is **identical** to the existing `user` profile in `home/dan/features/productivity/firefox-personal.nix` — same extensions, same settings, same search engine. The only differences are the profile attr key (`no-tracking`), `id = 1`, and `isDefault = false`. The user intends to use this profile for Google account logins etc., separate from daily browsing.

## Business Context

The user wants browser session isolation: a dedicated profile for sites requiring login (Google, etc.) while keeping their default profile clean. Since `SanitizeOnShutdown` is active, sessions/cookies clear on close — the user accepts re-logging in each session.

## Acceptance Criteria

1. `programs.firefox.profiles.no-tracking` exists with `id = 1` and `isDefault = false`
2. `programs.firefox.profiles.user` remains unchanged: `id = 0`, `isDefault = true`
3. The `no-tracking` profile has **identical** extensions, settings, and search config to `user`
4. No duplication: shared configuration is extracted into `let` bindings (DRY)
5. `nix flake check` passes
6. `nixos-rebuild build --flake .#thiniel` succeeds
7. Unit tests verify both profiles exist with correct attributes
8. No changes required to `browser.nix`, `lib/helpers.nix`, or `thiniel.nix`

## Technical Analysis

### Current State

[`firefox-personal.nix`](../../home/dan/features/productivity/firefox-personal.nix) defines a single `programs.firefox.profiles.user` with:
- Extensions: `exts.common ++ exts.privacy ++ exts.convenience ++ exts.productivity` plus 4 extras
- Settings: 25 key-value pairs covering privacy, UI, password manager, translations
- Search: Kagi as default, built-in engines hidden

### Target State

Same file defines two profiles under `programs.firefox.profiles`:
- `user` — `id = 0`, `isDefault = true` (unchanged behavior)
- `no-tracking` — `id = 1`, `isDefault = false` (identical config)

### Refactoring Pattern

Follow the established pattern from [`firefox-company.nix`](../../home/dan/features/productivity/firefox-company.nix:6-70) which extracts `workSettings` and `kagiSearch` into `let` bindings shared across three profiles.

For `firefox-personal.nix`, extract into `let`:
- `personalExtensions` — the full extension list
- `personalSettings` — the full settings attrset
- `personalSearch` — the full search config

Both profiles reference these bindings identically.

### File Changes

| File | Change |
|------|--------|
| `home/dan/features/productivity/firefox-personal.nix` | Refactor: extract shared config into `let` bindings; add `no-tracking` profile |
| `tests/unit/hm-productivity-modules-test.nix` | Add: unit tests for the new profile and for DRY refactoring verification |
| `home/dan/thiniel.nix` | **No change** — already imports `firefox-personal.nix` |
| `home/dan/features/productivity/browser.nix` | **No change** |
| `lib/helpers.nix` | **No change** |

## Implementation Phases

### Phase 0: Validation Strategy

**Syntax validation:**
```bash
nix flake check
```

**Build validation:**
```bash
nixos-rebuild build --flake .#thiniel
```

**Apply validation:**
```bash
sudo nixos-rebuild test --flake .#thiniel
```

**Rollback path:** This change only adds a Firefox profile definition. No system services, boot, networking, or filesystem changes. Rollback = revert the commit and rebuild. Risk: **minimal**.

### Phase 1: Unit Tests — Red (new profile existence)

**Goal:** Write failing unit tests that assert the `no-tracking` profile exists in the module output.

**Location:** `tests/unit/hm-productivity-modules-test.nix`

**Steps:**

- [x] 1.1 Import `firefox-personal.nix` in the test file (currently not imported — only `browser.nix`, `keepassxc.nix`, `maestral.nix` are tested). The import needs a mock `pkgs` with `pkgs.nur.repos.rycee.firefox-addons` — create a minimal mock or reuse the existing `mockPkgsLinux` extended with a NUR stub.
- [x] 1.2 Add test: `testPersonalProfileNoTrackingExists` — assert `personalModule.programs.firefox.profiles ? no-tracking` → `expected = true`
- [x] 1.3 Add test: `testPersonalProfileNoTrackingId` — assert `personalModule.programs.firefox.profiles.no-tracking.id` → `expected = 1`
- [x] 1.4 Add test: `testPersonalProfileNoTrackingNotDefault` — assert `personalModule.programs.firefox.profiles.no-tracking.isDefault` → `expected = false`
- [x] 1.5 Run `nix flake check` → confirm RED (tests fail because module has no `no-tracking` profile yet)

### Phase 2: Implementation — Green (add no-tracking profile)

**Goal:** Refactor `firefox-personal.nix` to extract shared config and add the `no-tracking` profile.

**Location:** `home/dan/features/productivity/firefox-personal.nix`

**Steps:**

- [x] 2.1 Extract `personalExtensions` into a `let` binding containing the full extension list
- [x] 2.2 Extract `personalSettings` into a `let` binding containing the full settings attrset
- [x] 2.3 Extract `personalSearch` into a `let` binding containing the full search config
- [x] 2.4 Rewrite `profiles.user` to reference the extracted bindings
- [x] 2.5 Add `profiles.no-tracking` with `id = 1`, `isDefault = false`, referencing the same bindings
- [x] 2.6 Run `nix flake check` → confirm GREEN (all tests pass)

### Phase 3: Unit Tests — Verify DRY and existing profile integrity

**Goal:** Add characterization tests ensuring the `user` profile is unchanged and both profiles share identical config.

**Location:** `tests/unit/hm-productivity-modules-test.nix`

**Steps:**

- [x] 3.1 Add test: `testPersonalProfileUserExists` — assert `personalModule.programs.firefox.profiles ? user` → `expected = true`
- [x] 3.2 Add test: `testPersonalProfileUserId` — assert `id` → `expected = 0`
- [x] 3.3 Add test: `testPersonalProfileUserIsDefault` — assert `isDefault` → `expected = true`
- [x] 3.4 Add test: `testPersonalProfileSettingsMatch` — assert `profiles.user.settings == profiles.no-tracking.settings` → `expected = true`
- [x] 3.5 Add test: `testPersonalProfileSearchMatch` — assert `profiles.user.search == profiles.no-tracking.search` → `expected = true`
- [x] 3.6 Add test: `testPersonalProfileExtensionsMatch` — assert `profiles.user.extensions.packages == profiles.no-tracking.extensions.packages` → `expected = true`
- [x] 3.7 Run `nix flake check` → confirm GREEN
- [x] 3.8 Run `nixos-rebuild build --flake .#thiniel` → confirm build success

### Phase 4: Refactor — Clean up

**Goal:** Review the implementation for clarity and adherence to conventions.

**Steps:**

- [x] 4.1 Verify no code duplication remains in `firefox-personal.nix`
- [x] 4.2 Verify `let` binding names are descriptive and consistent with `firefox-company.nix` naming style
- [x] 4.3 Run quality tools: `deadnix`, `statix check`, `nix fmt` on changed files
- [x] 4.4 Run full `nix flake check` → confirm all tests pass
- [x] 4.5 Commit: `feat(thiniel): add no-tracking Firefox profile`

## Validation Strategy

| Layer | Command | What It Verifies |
|-------|---------|------------------|
| Unit test | `nix flake check` | Both profiles exist, correct ids, identical settings/extensions/search |
| Build | `nixos-rebuild build --flake .#thiniel` | Full host config evaluates and builds |
| Apply | `sudo nixos-rebuild test --flake .#thiniel` | Config applies without errors |
| Manual | Open Firefox → Profile Manager → verify `no-tracking` profile appears | Runtime verification |

## NUR Mock Strategy for Unit Tests

The `firefox-personal.nix` module accesses `pkgs.nur.repos.rycee.firefox-addons`. The unit test must provide a mock for this. Two approaches:

**Option A — Minimal attrset mock (recommended):** Create a mock `addons` attrset where each addon name maps to a dummy string or derivation stub. This keeps tests fast and eval-only.

```nix
mockAddons = builtins.listToAttrs (map (name: { inherit name; value = name; }) [
  "ublock-origin" "keepassxc-browser" "consent-o-matic"
  "privacy-badger" "decentraleyes" "clearurls" "noscript" "temporary-containers"
  "tridactyl" "tree-style-tab" "languagetool" "single-file"
  "sponsorblock" "return-youtube-dislikes" "youtube-shorts-block"
  "reddit-enhancement-suite" "old-reddit-redirect"
  "terms-of-service-didnt-read" "link-cleaner" "tabliss" "kagi-search"
]);
mockPkgsWithNur = mockPkgsLinux // {
  nur = { repos.rycee.firefox-addons = mockAddons; };
};
```

**Option B — Import real NUR:** Slower, requires network or flake input. Not suitable for unit tests.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| NUR mock incomplete (missing addon name) | Low | Test eval error | Mock all addon names used in `firefox-personal.nix` and `lib/helpers.nix` |
| Profile id conflict | None | N/A | Verified: `user` is id=0, `no-tracking` is id=1 — no overlap with `firefox-company.nix` which is only imported on work hosts |
| `resistFingerprinting` breaks Google login | Medium | User inconvenience | Accepted by user — identical settings are the explicit requirement |

## Completion Criteria

- [x] All acceptance criteria met
- [x] All phases completed
- [x] `nix flake check` passes
- [x] `nixos-rebuild build --flake .#thiniel` passes
- [x] Commit created with conventional format

## Lessons Learned

- **Magic numbers need comments**: Firefox's `cookieBehavior = 5` is not self-documenting. Always add inline comments for non-obvious numeric values, even in a "minimal comments" codebase. The sibling file `firefox-company.nix` had the same comment — consistency matters.
- **Test mocks should document scope**: When a mock provides a superset of what the tested module needs (e.g., including `exts.dev` addons for future reuse), a comment prevents confusion about whether the extra entries are intentional or accidental.
- **Cross-file DRY is a future concern**: `personalSettings` and `workSettings` share ~20 identical key-value pairs. Extracting a shared `basePrivacySettings` into `lib/helpers.nix` would eliminate this duplication. Candidate for a dedicated refactoring task.
- **TDD with NUR mocks works well**: Mocking `pkgs.nur.repos.rycee.firefox-addons` as a simple `name → name` attrset is sufficient for unit-testing Firefox profile structure without evaluating real NUR packages. This pattern is reusable for testing `firefox-company.nix`.
