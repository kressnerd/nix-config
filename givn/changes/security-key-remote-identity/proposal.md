# Proposal: security-key-remote-identity

## Release note

On `thiniel`, the personal SSH identity authenticates through the Swissbit and Solo 2 security keys with non-resident handles, explicit file-key fallback, and lost-key revocation at every remote that authorized it.

## Scope update — 2026-10-20

The first stage uses the **Swissbit only**. The Solo 2 backup is deferred to a later stage. The retained file-backed identity remains the named fallback. The specs, design, and tasks below still describe the two-token plan and must be reduced to one token before implementation; this note records the decision, not the reduction.

## Use-Case Context

- Use-case ID: `authenticate-to-remote-host`, `recover-lost-security-key`
- Ideation topic: `secure-token-keys`
- Seed path: `givn/ideation/secure-token-keys/changes/security-key-remote-identity.md`
- Confirmed Personas: none — this is a host-configuration surface, not a rendered application; the owner/operator is the review lens, confirmed in the ideation Handoff.

## Problem / Opportunity

The owner holds a Swissbit iShield Key and a Solo 2, but `thiniel` declares no FIDO2 support and authenticates private repositories and servers with a file-based ed25519 identity only. A copied file key therefore remains usable, and the tokens provide no benefit.

The first stage should make the personal identity usable through the tokens without taking on local-login lockout or disk-unlock risk. A stolen token alone must not authenticate: the handle is non-resident, so the thief lacks the handle file on `thiniel`. The existing file-backed identity stays as fallback, so this change does not claim stolen-laptop resistance. A lost token must also be revocable at every remote that authorized it; a revocation that fails or cannot be verified is not success.

The work Mac, work identities, PAM/login, WebAuthn, SOPS age, and disk unlock are separate later surfaces.

## Proposed Solution

On `thiniel`, the operator can:

- Insert either security key and have the device recognize it as a FIDO2 authenticator.
- Enroll the personal identity on each token and keep a non-resident handle file in the user's SSH directory. No credential is recoverable from either token by itself; the handle file is required.
- Authorize each token's public identity at the personal GitHub account and at every declared host that accepts the user's SSH key. One key from `thiniel` represents the user. Enrollment alone grants no access.
- Open a connection to such a remote and have the daily Swissbit selected when it is present and its handle file is readable. The operator confirms with a touch; no PIN is required for daily use.
- Use the backup token automatically when the daily token is absent; use the existing file-backed personal identity only through the named fallback. The device never substitutes the file-backed identity for a token silently.
- See a token without its handle file fail to authenticate, and see a rejected or revoked public identity not retried with the file-backed identity. The backup token may be offered when the daily token is absent or rejected.
- Revoke a lost token's public identity at every remote that authorized it, with a report per remote. A failed, unreachable, or unverified revocation is reported and not treated as removed.

The file-backed personal identity remains on `thiniel`. Both handle files are backed up encrypted; the backup medium and procedure are operational, not a new configuration surface. The change does not claim that a stolen device or copied home directory yields no usable identity.

## Capability Routing

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| `security-key-enrollment-and-authorization` | `EXTEND permitted-identity-selection` (score 16) | `NEW in authenticate-to-remote-host` | The ideation Handoff confirmed a distinct actor goal: token-held authentication on `thiniel`. `permitted-identity-selection` covers which declared identity a device uses for file-based private-repository access; it does not own enrollment, non-resident handles, or the explicit fallback. Route's score is driven by host and out-of-scope work-identity names. |
| `token-preferred-remote-authentication` | `EXTEND permitted-identity-selection` (score 16) | `NEW in authenticate-to-remote-host` | The token-preferred, no-silent-substitution rule is a new success guarantee, not a variant of the existing file-key selection scenario. The ideation Handoff maps this goal to its own leaf. |
| `lost-security-key-revocation` | `EXTEND permitted-identity-selection` (score 16, proposal-level) | `NEW in recover-lost-security-key` | No existing capability owns revoking a lost public identity at remotes. Identity selection is not grant removal; the ideation Handoff confirmed a separate recovery goal. |

## Out of Scope

- The work Mac (`J6G6Y9JK7L`) and all work identities (`company`, `client001`, `client002`).
- Device privilege authentication (`sudo`/login), WebAuthn account enrollment, SOPS age, and disk unlock.
- A claim of theft resistance while the file-backed personal identity remains on `thiniel`.
- Removing the file-backed identity or delivering the stolen-device guarantee. That is a later change with its own recovery decision.
- Recovery when both security keys and `thiniel` are lost; account/provider recovery; a third token; an offline recovery key.
- The handle-file backup medium, product, schedule, and retention. The requirement is an encrypted backup; the operating procedure is outside this change.
- Commands or resources used inside an authenticated session.

## Open Questions

### D1 — Which remote hosts authorize the `thiniel` personal identity?

- Question: Which remotes must the change authorize and later revoke the token-held public identities at?
- Answer: one key from `thiniel` represents the user, and every host that accepts the user's SSH key can identify the user with it. The token-held public identities therefore become the user's identity on `thiniel`, `adlerkopf`, and `nixos-vm-minimal`, plus the personal GitHub account. `cupix001` has no SSH server and is excluded. The work Mac and work identities remain out of scope.
- Options considered:
  1. **One user identity key, authorized on every declared host and GitHub personal.** Gain: consistent identity and one recovery set; cost: every host is in the revocation scope; in practice: the same token-held public identities are added to each host's `authorized_keys` and to GitHub.
  2. **Per-host keys.** Gain: isolation; cost: more credentials and more revocation paths; in practice: each host gets a different token credential.
  3. **GitHub and `adlerkopf` only.** Gain: smaller first cut; cost: a host that accepts the user's key is missed; in practice: the spec covers two remotes and discloses the gap.
- Chosen: **One user identity key on every declared host and GitHub personal.** Rejected: per-host keys because the user wants one key that represents them; the narrower cut because it would leave an accepting host outside the revocation set.
- Disposition: answered 2026-10-20 (user). The design enumerates the declared hosts and the external GitHub authorization; the recovery scenarios quantify over that set. Any host not in the repository must be checked before it is claimed.

### D2 — Which key type and Swissbit capability does the first stage use?

- Question: Does the Swissbit accept `ed25519-sk`, or must the first stage use `ecdsa-sk`? What model is it?
- Answer: the iShield Key 2 family shares the same FIDO2 functions across variants; the base **iShield Key 2 FIDO2** is sufficient for SSH, and the Pro/MIFARE/FIPS extras are not used. The manual does not state signature algorithms. Swissbit describes ECDSA P-256 and Ed25519 as common FIDO2 algorithms, but no source establishes Ed25519 support for this device. The first key creation therefore tests `ed25519-sk` and falls back to `ecdsa-sk` on `invalid format` or `feature not supported`.
- Options considered:
  1. **Try `ed25519-sk`, fallback `ecdsa-sk`.** Gain: Ed25519's deterministic nonce if supported; P-256 is an acceptable fallback; cost: the first key creation is the test; in practice: `ssh-keygen -t ed25519-sk ... || ssh-keygen -t ecdsa-sk ...`.
  2. **Use `ecdsa-sk` directly.** Gain: known P-256; cost: abandons Ed25519's deterministic nonce without a test; in practice: both keys use `ecdsa-sk`.
  3. **Use `ed25519-sk` only.** Gain: deterministic nonce; cost: support is unproven and a rejection blocks the stage; in practice: the first key creation fails without a fallback.
- Chosen: **Try `ed25519-sk`, fallback `ecdsa-sk`.** Rejected: `ecdsa-sk` only because the token may support the preferred Ed25519; Ed25519 only because the support is not established.
- Post-quantum note: neither `ed25519-sk` nor `ecdsa-sk` is post-quantum-safe. OpenSSH's default key exchange is post-quantum hybrid on current versions, which protects session confidentiality; it does not make the authentication signature post-quantum. Non-resident keys can be replaced later by adding new public keys; no token migration is needed.
- Disposition: answered 2026-10-20 (user research). The design still tests the actual token; the fallback is part of the first RED/GREEN target.

### D3 — Do `thiniel` and the affected servers run OpenSSH ≥ 8.2 with FIDO support?

- Question: Can the client and every affected server accept `ed25519-sk`/`ecdsa-sk`?
- Answer: all declared NixOS hosts evaluate to OpenSSH `10.5p1` (`thiniel`, `adlerkopf`, `cupix001`, `nixos-vm-minimal`); the local client reports `OpenSSH_10.5p1`. OpenSSH has supported FIDO `-sk` keys since 8.2. GitHub supports FIDO SSH authentication keys. Apple's `ssh`/`ssh-keygen` lack FIDO support, but the work Mac is out of scope.
- Options considered:
  1. **Use the declared OpenSSH 10.5p1 fleet.** Gain: verified versions; cost: any host outside the repository must still be checked; in practice: the declared hosts are covered; an external host gets one `ssh -V` check.
  2. **Use `ecdsa-sk` everywhere.** Gain: the wider fallback; cost: still requires FIDO support and is not a version proof; in practice: the key type is chosen, but the version check remains.
  3. **Defer.** Gain: no work; cost: the first login may fail; in practice: the failure becomes a RED result.
- Chosen: **Use the declared OpenSSH 10.5p1 fleet; check any host outside the repository.** Rejected: `ecdsa-sk` as a substitute for version verification; deferring the check.
- Disposition: answered 2026-10-20 (repository evaluation and OpenSSH/GitHub documentation). The actual token login remains D6.

### D4 — Which udev/package support does the Solo 2 need?

- Question: Does normal Solo 2 FIDO2 use work with `libfido2` alone, or is `solo2-cli` required?
- Answer: normal FIDO2 SSH works with `libfido2`; the SoloKeys SSH guide says standard FIDO2 `-sk` keys need no special firmware, and the FIDO guide says `libfido2` tools work alongside the `solo2` CLI. `solo2-cli` is a device/firmware management tool, not a runtime dependency for credential create/assert. Swissbit uses its iShield Key Manager/iKMcli for management; the FIDO2 functions are standard. The first stage therefore needs `libfido2` for udev/access. Firmware or vendor management tools are one-off, not part of the host configuration.
- Options considered:
  1. **`libfido2` runtime only; vendor tools one-off.** Gain: minimal package set; cost: a firmware update needs a temporary tool; in practice: `services.udev.packages = [ pkgs.libfido2 ]`; `solo2-cli` or iKMcli only if firmware work is needed.
  2. **Add `solo2-cli` to the host.** Gain: firmware tools always available; cost: an extra package and udev rules not needed for authentication; in practice: the package is installed but unused by daily auth.
  3. **Add the Swissbit vendor tool.** Gain: vendor management; cost: not in nixpkgs, unpinned binary; not needed for authentication.
- Chosen: **`libfido2` runtime only; firmware/management tools are one-off.** Rejected: carrying `solo2-cli` permanently because it is not needed for authentication; adding a vendor binary to the host.
- Disposition: answered 2026-10-20 (SoloKeys SSH/FIDO documentation and Swissbit manual). The design verifies the Solo 2 authenticates with `libfido2` alone.

### D5 — How is the token preferred over the retained file key?

- Question: When both the token-held credential and the retained file key are available, how does a normal connection choose the token without a silent fallback?
- Context: this is not about which token serves which role; that is settled — Swissbit daily, Solo 2 backup. The file key remains on `thiniel`. If the SSH agent loads it, a connection may authenticate with it even when the token is present, violating the no-silent-substitution rule.
- Options:
  1. **Token-only normal connections, named fallback.** Normal `ssh`/`git` use the token only; the file key is available through a separate explicit command or alias.
     Gain: no silent fallback; cost: the fallback is a distinct command; in practice: `git push` prompts for the token, while a named fallback command uses `~/.ssh/id_ed25519`.
  2. **Token first, automatic file fallback when the token is absent.** The agent tries the token; if it is absent, it uses the file key.
     Gain: convenience; cost: the fallback is automatic and may be silent; in practice: with the token removed, `git push` uses the file key without a separate command, and the device reports which credential was used.
  3. **Both identities in the agent, rely on SSH order.** Gain: simplest; cost: the file key may authenticate even when the token is present; in practice: the file key wins when the agent offers it first.
  4. **Decide in design.** Gain: no user choice now; cost: the spec cannot assert the no-silent-substitution rule; in practice: the behavior remains unspecified.
- Chosen: **Token-only normal connections, named fallback.** Rejected: automatic file fallback because it can be silent; relying on SSH order because the file key can win when the token is present; deferring because the no-silent-substitution rule would not be assertable.
- Disposition: answered 2026-10-20 (user). The design implements a named fallback command/alias; normal `ssh`/`git` connections never offer the file key.

### D6 — What native target proves token authentication?

- Question: Which `@check:`, `@host:`, or `@deploy:` target proves each scenario, including the non-resident checks?
- Context: `integration-ssh-identity-selection` proves file-key identity resolution in a booted VM; it does not prove token authentication. A real security key cannot simply be attached to a QEMU VM. The non-resident decision adds `ssh-keygen -K` returning no keys and a token-without-handle-file failure. The operator's test list is: login with token and touch; login without touch fails; token on a machine without its handle file fails; `ssh-keygen -K` returns no keys; the backup token authenticates independently; backup access recovery under 15 minutes. Test needed.
- Options:
  1. **Host-level exercise on `thiniel` with the real token.** Gain: actual hardware proof; cost: not a repeatable VM check, owner present; in practice: a documented host exercise proves the daily and backup paths.
  2. **Virtual FIDO2 authenticator in a VM.** Gain: repeatable; cost: may not exercise the real firmware or udev path; in practice: the VM proves configuration and the real token proof remains separate.
  3. **Both: VM for configuration/udev, host for the real token.** Gain: strongest coverage; cost: two targets and two evidence classes; in practice: the VM check covers recognition and the host exercise covers the actual key.
- Disposition: answered 2026-10-20 (user/design) — the repeatable e2e is a VM with a virtual FIDO2 authenticator (`@check:integration-security-key-authentication` and `-revocation`); the real-token, backup-token, and backup-restore checks are manual gates recorded in `backup-drill.md`. Every scenario binds to exactly one target.

### D7 — What later mechanism permits removing the file-backed identity?

- Question: Which recovery mechanism will allow the later stage to remove the file key and claim the stolen-device guarantee?
- Context: Q7 deferred that guarantee; Q6 rejected an offline recovery key, account/provider recovery only, and a third token for this stage.
- Options:
  1. **Offline recovery key.** Gain: independent recovery; cost: long-lived key and media; in practice: the later stage stores an encrypted key away from the device.
  2. **Account/provider recovery only.** Gain: no extra key; cost: external dependency; in practice: the later stage relies on GitHub recovery and provider consoles.
  3. **Third token.** Gain: same mechanism; cost: purchase and a third credential; in practice: the later stage registers a third token and stores it separately.
- Disposition: out of scope — this change keeps the file-backed identity; the later recovery change decides.

### D8 — How are the handle files backed up encrypted?

- Question: Which encrypted backup medium and procedure protects each token's handle file?
- Context: losing a handle file makes that token unusable even when the token is present. The other token is the immediate recovery path; the encrypted backup is the second.
- Options:
  1. **Encrypted archive on offline media.** Gain: independent of the device; cost: media and passphrase management; in practice: both handle files are copied into an encrypted archive kept away from `thiniel`.
  2. **Encrypted copy in the private flake or a password manager.** Gain: convenient; cost: the backup is reachable from a device that may be compromised; in practice: the handle files are stored as encrypted blobs.
  3. **No separate backup; rely on the second token.** Gain: less material; cost: losing one handle file still leaves the second token, but losing both handle files blocks both; in practice: the second token is the only recovery path.
- Disposition: answered 2026-10-20 (user) — the encrypted backup and a restore drill are a completion gate. The operator records the medium, the restored handle file, and a successful backup-token authentication under 15 minutes in `backup-drill.md`; archive waits for it.
