# Change seed: security-key-remote-identity

Status: ready

- Use-case IDs: authenticate-to-remote-host, recover-lost-security-key
- Topic: secure-token-keys
- Personas: owner--operator (reused; no promotion)
- Suggested start: first and only ready seed for this topic; no dependency on another seed
- Handoff: ready as input to `/givn-propose`; no givn change started

## Accepted decisions

### First-stage scope

- Context: the owner holds a Swissbit iShield Key and a Solo 2 but no declared device behavior uses them. The same hardware supports four independent surfaces with different lockout and recovery costs. The first stage must prove the token path without taking on local login or disk-unlock risk.
- Options:
  1. **Device privilege authentication first.** `sudo`/login require a token on Linux. Gain: protects local privilege. Cost: highest lockout risk; no macOS; PAM can make the device unadministrable.
  2. **Remote identity first.** Token-held SSH identities replace or supplement file keys for private repositories and servers. Gain: extends the verified `permitted-identity-selection` capability; no local login lockout. Cost: every remote must register both tokens; work Mac compatibility is later.
  3. **Web-account authentication first.** Tokens are WebAuthn authenticators. Gain: phishing resistance. Cost: mostly account-side enrollment; weakly exercises the device configuration.
  4. **Secret/disk unlock first.** Token unlocks SOPS age or LUKS. Gain: hardware-bound secrets at rest. Cost: `thiniel` is OPAL SED, not LUKS; headless physical-presence limits; high recovery cost.
  5. **All four, staged.** One surface at a time. Gain: coherent direction. Cost: larger scope; the first surface still has to be named.
- Chosen: **Remote identity**, scoped to the **personal identity on `thiniel` only** (Q2/Q3). The work Mac and work identities stay file-based. Server access that already trusts the `thiniel` personal identity is included. Rejected: device privilege, web-account, and secret/disk as the first stage for the lockout, account-side, and platform/recovery reasons above; the broader all-at-once cut because the first outcome must be bounded.

### Token roles

- Context: neither security key exports its private key, so a backup is a second registered credential, not a copy.
- Options:
  1. **Swissbit daily, Solo 2 backup.** Swissbit carried; Solo 2 stored separately; both registered on the same remotes. Gain: clear break-glass separation. Cost: two credentials per remote; backup maintenance.
  2. **Solo 2 daily, Swissbit backup.** Gain: daily device has open firmware and `solo2-cli` updates. Cost: reserve has less transparent firmware; same enrollment cost.
  3. **Equal pair.** Gain: flexibility. Cost: no unambiguous reserve; both need constant maintenance.
  4. **One token now.** Gain: less work. Cost: no tested recovery path.
- Chosen: **Swissbit daily, Solo 2 backup** (Q4). Rejected: Solo 2 daily because a clear break-glass separation outweighs the firmware-update advantage; equal pair because it leaves no reserve; one token because the stage cannot claim a tested recovery path.

### Threat model and first-stage guarantee

- Context: Q5's overall model includes stolen device/copied data, malicious local process/unattended session, and remote account/credential compromise. Q6 chose to keep the existing file key on `thiniel`; Q7 reconciled the conflict.
- Options:
  1. **Keep the file key; defer the stolen-device guarantee.** The stage delivers token enrollment and token-preferred daily use with the file key as fallback. Gain: easiest migration and rollback. Cost: the first stage does not improve the stolen-device posture and must say so.
  2. **Keep the file key, passphrase-protected.** Gain: local recovery without offline media. Cost: not hardware-bound; offline brute force; weaker guarantee.
  3. **Move the file key off the device.** Gain: preserves the stolen-device guarantee. Cost: offline media and a long-lived key to protect and test.
  4. **Remove the file key; external recovery only.** Gain: strongest key hygiene. Cost: external account/provider recovery; not fully testable.
- Chosen: **Keep the file key; defer the stolen-device guarantee** (Q6/Q7). The first stage proves token enrollment, token-preferred daily use, and the backup credential. It does **not** claim that a stolen device or copied home directory yields no usable identity. Per-use verification and WebAuthn remain later stages. Rejected: passphrase-protected file key for the weaker claim; moving it off-device because the owner declined offline media; removing it because the owner chose the local fallback.

### Use-case cut and seed boundary

- Context: the reviewed first stage has two actor outcomes: authenticating to a remote host, and revoking a lost security key's public identity. Enrollment/authorization/retention are setup and fallback preconditions.
- Options:
  1. **Two leaves, one seed.** `authenticate-to-remote-host` and `recover-lost-security-key` ship in one change. Gain: the lost-key revocation rule is true when the stage ships. Cost: a larger change.
  2. **Two leaves, two seeds with authentication first.** Gain: smaller first change. Cost: an intermediate state where a lost key cannot be revoked, making a confirmed first-stage rule untrue.
  3. **One combined "safe access" leaf.** Gain: one goal. Cost: the success guarantee joins authentication and revocation, violating the one-outcome rule.
  4. **Enrollment as a third leaf.** Gain: explicit setup goal. Cost: enrollment alone delivers no usable access; it is a subfunction.
- Chosen: **Two leaves, one seed** (`authenticate-to-remote-host`, `recover-lost-security-key`). The seed guarantee is token-held remote identity on `thiniel` with daily/backup/fallback and lost-key revocation. Rejected: two seeds because the intermediate state violates the lost-key rule; one combined leaf because of the joint success outcome; enrollment as a leaf because it is not value-ready.

### Terms and persona

- All eleven confirmed terms were promoted to `docs/arc42/12-glossary.md` on 2026-10-17: Security key, Daily security key, Backup security key, Enrollment, Token-held personal identity, Key handle, Enrolled credential, File-backed personal identity, Remote authorization, Remote host, Public identity.
- No new persona and no promotion. The existing `owner--operator` is the review lens; `family--application-user` is unaffected. The owner's security-key vocabulary is a topic stance, not a distinct authority/evaluation segment.

## Open questions

### Which remote hosts authorize the `thiniel` personal identity?

- Blocks: the recovery outcome's quantification over every remote that authorized the lost key; the proposal's remote inventory.
- Context: Q3 includes the servers that already trust the `thiniel` personal identity. The repository names GitHub personal and `adlerkopf`; `cupix001` and the VMs may or may not authorize the key. The private/remote state is not audited here.
- Options:
  1. **Audit GitHub and every declared server/VPS.** Gain: complete revocation set. Cost: auditing external/private authorization state.
  2. **Audit GitHub and `adlerkopf` only.** Gain: smaller scope. Cost: an unauthorized remote may be missed.
  3. **Owner supplies the authoritative list.** Gain: matches intent. Cost: the list must be maintained.
- Resolution: open; settle in proposal/design before claiming the recovery outcome is complete.

### Which Swissbit iShield model and capabilities?

- Blocks: resident-key capacity; later PIV/TOTP/HMAC-secret stages; the exact `fido2-token` probe commands.
- Context: the user stated "Swissbit iShield Key" without a model. The model label or `fido2-token -L -I` establishes FIDO2/PIV/TOTP/HMAC-secret support. The SSH first stage can use key-handle files if resident slots are limited.
- Options:
  1. **Read the model from the device label.** Gain: no tooling needed. Cost: may not reveal firmware capabilities.
  2. **Probe with `fido2-token` after the udev setup.** Gain: capability evidence. Cost: requires the temporary package/udev setup.
- Resolution: open; not blocking the SSH first stage, but needed before later stages.

### Which udev/package support does the Solo 2 need?

- Blocks: the first-stage device package set and the exact udev rules.
- Context: `libfido2` supplies generic FIDO2 udev rules; Solo 2 adds non-FIDO2 USB modes and firmware updates through `solo2-cli`. Normal FIDO2 use may work with `libfido2` alone.
- Options:
  1. **`libfido2` only.** Gain: smaller package set. Cost: Solo 2 firmware/bootloader modes may be inaccessible.
  2. **`libfido2` plus `solo2-cli`.** Gain: full Solo 2 modes and updates. Cost: an extra package and its udev rules.
- Resolution: open; settle by testing the actual Solo 2 on the target.

### How does the device prefer the token over the retained file key?

- Blocks: the "token-preferred, no silent substitution" first-stage rule; the SSH configuration and agent behavior.
- Context: the file key remains on `thiniel`. If the agent loads it, a connection may use it without the token, silently violating the rule.
- Options:
  1. **Configure the token identity first and keep the file key out of the agent.** Gain: token used when present; explicit fallback. Cost: fallback needs an explicit selection.
  2. **Keep both identities available and rely on SSH order.** Gain: simple. Cost: order can be bypassed; silent fallback risk.
  3. **Use a wrapper that requires an explicit fallback choice.** Gain: strongest no-silent-substitution guarantee. Cost: extra tooling.
- Resolution: open; the use-case contract requires the behavior, not the mechanism.

### What native target proves token authentication?

- Blocks: the future Gherkin scenarios' `@check:`/`@host:`/`@deploy:` binding and the RED/GREEN evidence.
- Context: `integration-ssh-identity-selection` proves file-key identity resolution in a booted VM; it does not prove a token-held authentication. A real security key cannot simply be attached to a QEMU VM.
- Options:
  1. **Host-level exercise on `thiniel` with the real token.** Gain: actual hardware proof. Cost: not a repeatable VM check; requires the owner present.
  2. **Virtual FIDO2 authenticator in a VM.** Gain: repeatable. Cost: may not exercise the real Swissbit/Solo 2 firmware or udev path.
  3. **Both: VM for configuration/udev, host for real token.** Gain: strongest coverage. Cost: two targets and two evidence classes.
- Resolution: open; the proposal must bind each scenario to a target that can actually prove it and must disclose the platform limit.

### What later recovery mechanism permits removing the file key?

- Blocks: the later stage that delivers the stolen-device guarantee; not this seed.
- Context: Q7 deferred the guarantee until a recovery mechanism exists. The options rejected in Q6 were offline recovery key, account/provider recovery only, and a third token.
- Options:
  1. **Offline recovery key.** Gain: independent recovery. Cost: long-lived key and media.
  2. **Account/provider recovery only.** Gain: no extra key. Cost: external dependency.
  3. **Third token.** Gain: same mechanism. Cost: purchase and a third credential.
- Resolution: open; belongs to the later recovery stage, not this seed.

## Handoff notes

- The readable topic is published at `docs/ideation/secure-token-keys.md`.
- The topic state, event storming, term record, reviewed cut, and contracts remain under `givn/ideation/secure-token-keys/`.
- No givn change, configuration edit, enrollment, authentication, revocation, deployment, or secret operation was performed by this ideation.
