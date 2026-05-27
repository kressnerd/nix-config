# Fix `private.nix` not loaded during flake evaluation (adlerkopf + cupix001)

**Status**: DRAFT — awaiting approval
**Scope**: `hosts/adlerkopf/`, `hosts/cupix001/`, `.gitignore`, related docs
**Repository visibility**: PRIVATE

## Business Context

`hosts/adlerkopf/private.nix` and `hosts/cupix001/private.nix` are listed in [`.gitignore`](../../.gitignore:2). Nix flakes only copy git-tracked files into the evaluation store. As a result, `builtins.pathExists ./private.nix` in [`hosts/adlerkopf/default.nix`](../../hosts/adlerkopf/default.nix:23) and [`hosts/cupix001/default.nix`](../../hosts/cupix001/default.nix:18) always returns `false` during flake evaluation, even when the file exists on the developer's filesystem.

Consequence on adlerkopf: option defaults from [`hosts/adlerkopf/options.nix`](../../hosts/adlerkopf/options.nix:20) are silently used, producing `lanIPv4 = "REDACTED-HOME-LAN-SUBNET"` instead of the intended `REDACTED-HOME-LAN-SUBNET` from `private.nix`. The same trap affects cupix001 — its defaults are empty strings, masking the bug as "everything still evaluates" while shipping broken networking.

## Acceptance Criteria

- [ ] `nix flake check` passes
- [ ] `nix eval .#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4` returns the real value from `private.nix`, not the placeholder default
- [ ] `nix eval .#nixosConfigurations.cupix001.config.networking.cupix001.publicIPv4` returns the real value, not `""`
- [ ] `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel --dry-run` succeeds
- [ ] `nix build .#nixosConfigurations.cupix001.config.system.build.toplevel --dry-run` succeeds
- [ ] Removing `private.nix` from disk causes `nix flake check` to FAIL loudly (regression guard) — no more silent fallback to defaults
- [ ] No `--impure` evaluation required anywhere
- [ ] Pattern is symmetric across both hosts
- [ ] `README.md` and `docs/ADLERKOPF-DEPLOY-RUNBOOK.md` reflect the new workflow

## Technical Analysis

### Why the current pattern is broken

```
Developer disk:                     Flake store copy (git-tracked only):
  hosts/adlerkopf/                    hosts/adlerkopf/
    default.nix       ← tracked        default.nix
    options.nix       ← tracked        options.nix
    private.nix       ← gitignored     (absent)
    private.nix.example ← tracked      private.nix.example
```

`builtins.pathExists ./private.nix` evaluates `./private.nix` as a path relative to the store copy. The path resolves to a non-existent location → `false` → `lib.optional` produces `[]` → no override → defaults win.

This is documented Nix flakes behavior: only git-tracked files are copied to the Nix store during evaluation. It is independent of pure vs. impure mode.

### Approaches Considered

| # | Approach | Verdict | Reason |
|---|----------|---------|--------|
| 1 | Force-track `private.nix` via git (remove `.gitignore` entries) | **CHOSEN** | Repo is PRIVATE; the original gitignore was a defense against a public repo threat model that no longer applies. Simplest fix. Restores flake purity. Symmetric across hosts. Makes the file's absence a loud failure instead of silent fallback. |
| 2 | Move IPs to sops-nix secrets | Rejected | sops-nix decrypts at activation time, not at eval time. `systemd.network.networks."10-lan".address = [ "${cfg.lanIPv4}/24" ]` cannot read sops values during evaluation. Wrong layer. |
| 3 | Build with `--impure` and use `builtins.getEnv` or absolute path outside the store | Rejected | Breaks flake purity. Requires every developer, CI job, and `colmena` deployment to opt into impure mode. Cumbersome. Violates project conventions. |
| 4 | Place `private.nix` outside the flake (e.g. `/etc/nixos-private/`) and reference via absolute path | Rejected | Loses reproducibility across machines. Same impurity problem. Couples evaluation to host filesystem layout. |
| 5 | Keep gitignore, use `lib.warn` when `private.nix` is missing | Rejected | Does not fix the bug — defaults would still be used silently, just with a warning printed. Warnings are easy to miss in CI logs. |
| 6 | Rename to `host-values.nix` and track in git | Equivalent to #1 with extra churn | Cosmetic only. Adds a refactor without functional benefit. |

### Why approach #1 is correct for this repository

The project rule [`.roo/rules/10-nix-senior-admin.md`](../../.roo/rules/10-nix-senior-admin.md) — "Option DEFAULT VALUES must not leak operational details; actual values go in gitignored files (e.g., `private.nix`)" — was written under the assumption of a **public** repository. The user task explicitly clarifies the constraint:

> This is a PRIVATE repository

In a private repository, tracking the deployment-specific values in git is not a leak. The architectural separation between schema (`options.nix`, neutral defaults, public-API-like) and values (`private.nix`, host-specific overrides) is preserved — the only change is that `private.nix` becomes a tracked file inside a private repo, rather than an untracked file that breaks flake evaluation.

### Regression Guard

After the fix, `private.nix` is unconditionally imported. If the file is ever deleted or moved, `nix flake check` fails immediately with a "file not found" eval error. This is a stronger guarantee than any assertion: the failure mode is "loud and immediate" instead of "silent wrong-value".

No additional Nix assertion is needed. (An assertion like `lanIPv4 != "REDACTED-HOME-LAN-SUBNET"` would be fragile — it conflates "default value" with "wrong value" and would false-positive in environments that legitimately use the default.)

## Validation Strategy (Phase 0)

Run before, during, and after implementation:

| Command | Purpose |
|---------|---------|
| `git check-ignore -v hosts/adlerkopf/private.nix` | Confirm gitignore state (should exit 0 BEFORE fix, exit 1 AFTER fix) |
| `git check-ignore -v hosts/cupix001/private.nix` | Same for cupix001 |
| `git ls-files hosts/adlerkopf/private.nix` | After fix: should print the path (tracked) |
| `git ls-files hosts/cupix001/private.nix` | After fix: should print the path (tracked) |
| `nix flake check` | Must pass at every step |
| `nix eval .#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4` | Must return real value after fix, not `"REDACTED-HOME-LAN-SUBNET"` |
| `nix eval .#nixosConfigurations.cupix001.config.networking.cupix001.publicIPv4` | Must return real value after fix, not `""` |
| `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel --dry-run` | Must succeed |
| `nix build .#nixosConfigurations.cupix001.config.system.build.toplevel --dry-run` | Must succeed |

### Affected Hosts

- `adlerkopf` (NixOS, LAN homelab)
- `cupix001` (NixOS, public-facing VPS)

### Dangerous-Change Classification

This change touches networking-related option values that drive `systemd.network` configuration on both hosts.

| Risk | Mitigation |
|------|------------|
| Wrong IP applied to live adlerkopf after switch | The fix loads the IP that the user already intended. Before any `switch`, run `nix eval` to confirm the resolved value matches expectations. |
| `private.nix` accidentally containing test/placeholder values gets committed | Pre-commit review; `private.nix.example` retained as the documented schema-only template. Reviewer mode MUST diff `private.nix` content before approving. |
| cupix001 `private.nix` does not exist on disk in some environment | Fix will make this a loud eval-time failure rather than a silent runtime networking failure. Existing developer environments that have `private.nix` continue to work. New environments must populate it before first `nix flake check`. |

### Rollback Path

If the fix causes an unexpected regression:

```bash
git revert <commit-sha>           # revert the fix commit
sudo nixos-rebuild switch --flake .#<host>   # re-apply previous generation
```

On a misbehaving live host: `nixos-rebuild --rollback switch` from the host itself reverts to the previous generation immediately.

## Implementation Phases

### Phase 0 — Validation strategy (defined above; no implementation)

- [x] Validation commands listed
- [x] Affected hosts identified
- [x] Rollback path documented
- [x] Dangerous-change classification recorded

### Phase 1 — Pre-flight: confirm both `private.nix` files exist on disk with intended values

- [ ] **Step 1.1** — Verify [`hosts/adlerkopf/private.nix`](../../hosts/adlerkopf/private.nix) exists and contains `lanIPv4 = "REDACTED-HOME-LAN-SUBNET"` (or the user's actual intended value). If missing, create from [`hosts/adlerkopf/private.nix.example`](../../hosts/adlerkopf/private.nix.example) and fill in real values.
- [ ] **Step 1.2** — Verify [`hosts/cupix001/private.nix`](../../hosts/cupix001/private.nix) exists and contains the actual VPS networking values. If missing, create from [`hosts/cupix001/private.nix.example`](../../hosts/cupix001/private.nix.example) and fill in real values.
- [ ] **Step 1.3** — Run `nix flake check` with the current code as a baseline. Record the (silently-wrong) resolved `lanIPv4` for evidence: `nix eval .#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4` should print `"REDACTED-HOME-LAN-SUBNET"`.

### Phase 2 — Remove the gitignore entries

- [ ] **Step 2.1** — Edit [`.gitignore`](../../.gitignore): remove the two lines
  - `hosts/cupix001/private.nix`
  - `hosts/adlerkopf/private.nix`
- [ ] **Step 2.2** — Verify with `git check-ignore -v hosts/adlerkopf/private.nix` and `git check-ignore -v hosts/cupix001/private.nix` — both must now exit non-zero.

### Phase 3 — Track both `private.nix` files in git

- [ ] **Step 3.1** — `git add hosts/adlerkopf/private.nix hosts/cupix001/private.nix .gitignore`
- [ ] **Step 3.2** — Verify with `git ls-files hosts/adlerkopf/private.nix hosts/cupix001/private.nix` — both paths must be listed.
- [ ] **Step 3.3** — Run `nix flake check`. With the files now in the store, the existing `lib.optional` import still works, but `nix eval .#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4` must now return the real value (e.g. `"REDACTED-HOME-LAN-SUBNET"`). This proves the root cause is fixed.

### Phase 4 — Convert conditional imports to unconditional imports

This step removes the booby-trapped `builtins.pathExists` pattern entirely so the file's absence becomes a loud failure rather than a silent fallback.

- [ ] **Step 4.1** — Edit [`hosts/adlerkopf/default.nix`](../../hosts/adlerkopf/default.nix:8-23): inside the `imports = [ ... ]` list, add `./private.nix` as a plain entry; remove the `++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;` continuation line so the list terminates with `];`.
- [ ] **Step 4.2** — Edit [`hosts/cupix001/default.nix`](../../hosts/cupix001/default.nix:7-18): same change — add `./private.nix` to the imports list, remove the `++ lib.optional` line.
- [ ] **Step 4.3** — Run `nix flake check`. Must pass.
- [ ] **Step 4.4** — Run `nix fmt`, `statix check`, `deadnix` on both files; auto-fix any issues.

### Phase 5 — Regression test (manual sanity check)

- [ ] **Step 5.1** — Temporarily rename `hosts/adlerkopf/private.nix` to `private.nix.bak`. Run `nix flake check`. Expected: FAIL with "path '/nix/store/.../hosts/adlerkopf/private.nix' does not exist" or similar. This confirms the loud-failure regression guard works.
- [ ] **Step 5.2** — Restore the file: `mv hosts/adlerkopf/private.nix.bak hosts/adlerkopf/private.nix`. Run `nix flake check`. Expected: PASS.

### Phase 6 — Update documentation

- [ ] **Step 6.1** — Update [`README.md`](../../README.md) cupix001 setup section: change from "copy from `.example` before first build" to "`private.nix` is committed to this private repo; edit it directly to change host-specific values".
- [ ] **Step 6.2** — Update [`docs/ADLERKOPF-DEPLOY-RUNBOOK.md`](../../docs/ADLERKOPF-DEPLOY-RUNBOOK.md) line 128–129: remove the note about `private.nix` being potentially absent; replace with reference to the tracked file.
- [ ] **Step 6.3** — Add a brief subsection to README explaining the pattern: "Schema in `options.nix` (neutral defaults), values in `private.nix` (host-specific overrides). Both are tracked in this private repo. Defaults in `options.nix` MUST remain neutral so the schema can be reused across hosts and so accidental fallback values are obviously placeholder."
- [ ] **Step 6.4** — Keep `private.nix.example` files in place — they serve as inline-comment documentation of which fields exist and how to gather them. Add a one-line note at the top of each `.example` file: `# Reference template. The real values live in private.nix (tracked in this private repo).`

### Phase 7 — Final validation

- [ ] **Step 7.1** — `nix flake check` — PASS
- [ ] **Step 7.2** — `nix eval .#nixosConfigurations.adlerkopf.config.networking.adlerkopf.lanIPv4` — returns real value
- [ ] **Step 7.3** — `nix eval .#nixosConfigurations.cupix001.config.networking.cupix001.publicIPv4` — returns real value
- [ ] **Step 7.4** — `nix build .#nixosConfigurations.adlerkopf.config.system.build.toplevel --dry-run` — PASS
- [ ] **Step 7.5** — `nix build .#nixosConfigurations.cupix001.config.system.build.toplevel --dry-run` — PASS
- [ ] **Step 7.6** — Apply on adlerkopf: `sudo nixos-rebuild switch --flake .#adlerkopf --target-host dan@<current-ip> --sudo` (run `test` instead of `switch` first if the IP change requires careful handling)
- [ ] **Step 7.7** — Verify on adlerkopf: `ip -4 addr show eno1` shows the intended IP
- [ ] **Step 7.8** — cupix001 apply only when next deploy is scheduled — no behavior change expected since the actual values were already on disk; this fix just eliminates a silent-bug class

## Current Status

**Phase 0** complete (planning).  
Awaiting approval to delegate Phases 1–7 to Code Mode via Orchestrator.

## File Change Summary

| File | Change |
|------|--------|
| [`.gitignore`](../../.gitignore) | Remove `hosts/cupix001/private.nix` and `hosts/adlerkopf/private.nix` entries |
| `hosts/adlerkopf/private.nix` | `git add` (newly tracked) |
| `hosts/cupix001/private.nix` | `git add` (newly tracked) |
| [`hosts/adlerkopf/default.nix`](../../hosts/adlerkopf/default.nix) | Move `./private.nix` into unconditional imports list; remove `lib.optional` continuation |
| [`hosts/cupix001/default.nix`](../../hosts/cupix001/default.nix) | Same change |
| [`hosts/adlerkopf/private.nix.example`](../../hosts/adlerkopf/private.nix.example) | Add header comment marking it as reference template |
| [`hosts/cupix001/private.nix.example`](../../hosts/cupix001/private.nix.example) | Same |
| [`README.md`](../../README.md) | Update cupix001 setup section; add brief note on schema/values split |
| [`docs/ADLERKOPF-DEPLOY-RUNBOOK.md`](../../docs/ADLERKOPF-DEPLOY-RUNBOOK.md) | Remove "may be absent" note about `private.nix` |

## Completion Log

_(to be filled during execution)_
