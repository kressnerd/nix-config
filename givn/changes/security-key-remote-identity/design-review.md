# Design Review: security-key-remote-identity

Status: signed off after grilling and hardening.

## Grilling record

The grilling review found the plan not ready and raised ten questions. The user decided the four that required human authority:

- **Hardware e2e policy:** VM virtual authenticator in CI (`@check:integration-security-key-authentication`, `-revocation`); real-token, backup-token, and restore checks are manual gates.
- **Backup-token selection:** automatic after the daily token is absent or rejected; the file-backed identity is only through the named fallback.
- **Handle-file backup:** encrypted backup plus a restore drill is a completion gate recorded in `backup-drill.md`.
- **Credential reporting:** the claim is removed; the token touch and the named fallback make the path observable without a reporting surface.

Repository-resolvable questions were answered in the design: keep `personalIdentityFile` as the file-backed identity and add `tokenIdentityFiles`; explicit server Host blocks; update the raw unit mocks; move remote-rejection proof to the VM; x86_64-gate the VM checks; use `lib/security-key.nix` as the public-identity/remote data source; add a revocation-plan package; keep the declared host set to `thiniel`, `adlerkopf`, `nixos-vm-minimal`; add `revocation-drill.md`.

## Hardening applied

- Proposal: host set corrected; D6/D8 statuses decided; backup-after-rejection wording; reporting claim removed.
- Specs: no `@deploy` tags; e2e binds to the two VM checks; automatic-backup and rejected-daily scenarios added; authorization rejection moved to the VM; delta scenarios for the thiniel token identity and the unchanged Mac identity.
- Design: option model, Host blocks, mocks, x86_64 gating, revocation consumer, manual gates, fidorium packaging notes, and the VM/real-token split.
- arc42: context, building blocks, runtime, cross-cutting concept, quality scenario, risks, and the no-ADR verdict updated; stale deploy-layer claims removed.
- Manual gates: `backup-drill.md` and `revocation-drill.md` record the real-token, backup, restore, and per-remote revocation evidence.

## Review findings

- **B1 deploy tag/file mismatch:** resolved — no deploy tags remain.
- **B2 unrun deploy scenarios counted:** resolved — no deploy-bound scenario remains.
- **B3 git offers the file key:** resolved in design — `git.nix` uses the token list; the old thiniel assertion update is an implementation task.
- **B4 work Mac breaks:** resolved — token list only when declared; Mac keeps `personalIdentityFile`.
- **B5 promoted identity contract:** resolved — delta scenarios added; old assertion update planned.
- **B6 thiniel profile missing:** resolved — `home/dan/thiniel.nix` listed with the token list.
- **B7 new options break tests:** resolved — default `[]`, mock update and `or []` planned.
- **B8 assertion guard:** resolved — hostname guard.
- **B9 data model / plan consumer:** resolved — `lib/security-key.nix` and `packages.security-key-revocation-plan`.
- **B10 durable revocation:** resolved — declaration edit, redeploy, GitHub removal, per-remote verification.
- **B11 revocation test platform:** resolved — x86_64 VM, not aarch64 `nixos-vm-minimal`.
- **B12 unit bindings:** resolved — remote rejection moved to the VM; the plan has a consumer.

## Remaining implementation prerequisites

- Wire the new check names before the first RED.
- Update `tests/assertions/thiniel-invariants.nix` and the unit mocks.
- Enroll the real tokens and insert the public keys into `lib/security-key.nix`.
- Run `backup-drill.md` and `revocation-drill.md` before archive.

These are tasks, not design gaps.

## Sign-off

DESIGN-REVIEW: PASS
