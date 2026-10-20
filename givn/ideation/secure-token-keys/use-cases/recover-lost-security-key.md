# Use case: recover-lost-security-key

## Level
!

## Actors
- Primary: Device owner.

## Goal
The Device owner revokes a lost security key's public identity at every remote that authorizes it.

## Trigger
The Device owner observes that a security key is lost.

## Preconditions
- The lost key's public identity is known from the identity declaration and its enrolled credential.
- A remaining credential can authenticate to each affected remote: the other security key with its own non-resident handle file, or the retained file-backed personal identity.
- The Device owner is authorized to change the remote authorizations.
- Each affected remote is reachable.
- If both security keys are lost, the file-backed personal identity is present and authorized.

## Main flow
1. Actor Device owner assesses which security key is lost; System reports key availability and the lost key's public identity.
2. Actor Device owner authenticates to each affected remote with the remaining credential; System establishes the session through `authenticate-to-remote-host`.
3. Actor Device owner revokes the lost public identity at the remote; System removes that remote's authorization.
4. Actor Device owner asks the remote to confirm or list that the lost public identity is no longer authorized; System reports the remote authorization status.
5. Actor Device owner obtains the outcome; System reports, per remote, whether the lost public identity was revoked, a revocation failed, or the remote was unreachable.

## Extensions
- 1a: The Device owner cannot distinguish a lost key from a temporarily absent key → System does not revoke the present credential; the owner continues with the available credential; protects the remaining access and avoids revoking a key the owner still holds.
- 2a: The remaining credential cannot authenticate at a remote → System reports that remote as blocked; when both security keys are lost and the file-backed personal identity is present, the owner uses it as the remaining credential; protects the success guarantee for that remote.
- 2b: A remote is unreachable → System reports that remote as not revoked; it does not treat reachability failure as revocation; protects the success guarantee.
- 3a: The remote refuses or fails the revocation → System reports the failure and leaves the lost public identity treated as authorized there; protects the success guarantee.
- 4a: The remote's confirmation is absent or contradicts the revocation → System reports that revocation is not effective and does not claim success; protects the success guarantee.

## Rules
- Revocation is performed at every remote that authorized the lost public identity. The owner does not select a convenient subset; the authoritative remote inventory is an elaboration input, but the outcome quantifies over all of it.
- A revocation is successful only when the remote confirms it. A failed, refused, unreachable, or unverified revocation is not success.
- The lost security key's public identity is the object; the lost key's handle file and credential record grant no access without the key, and the handle is non-resident. Local record cleanup is not part of this goal.
- A lost or unreadable handle file while the token remains is not a lost key. It makes that credential unusable and is handled by using the other credential or re-enrolling; it is not a reason to revoke a public identity at the remote.
- The remaining credential is used through `authenticate-to-remote-host`; this case grants no new access and does not remove the remaining credential.
- The case does not recover a lost device, both security keys and the device together, an account, or a provider console session; no third token or offline recovery key is selected.
- A lost backup key is handled symmetrically with a lost daily key: the daily key remains usable, and the lost backup's public identity is revoked at every remote that authorized it.

## Examples
- The daily Swissbit is lost. The owner retrieves the Solo 2, authenticates to GitHub and to `adlerkopf`, revokes the Swissbit's public identity at both, and confirms that each remote lists the Swissbit's public identity as no longer authorized. The daily-key public identity is revoked at every remote that authorized it.
- The backup Solo 2 is lost. The owner uses the Swissbit to reach each remote that authorized the Solo 2 and revokes the backup public identity there. The daily key remains available.
- Both security keys are lost while `thiniel` remains. The owner uses `~/.ssh/id_ed25519` to reach each remote and revokes both lost public identities. If `thiniel` is also lost, this stage provides no recovery.
- Revocation succeeds at GitHub but fails at `adlerkopf`. The owner reports the failure; the Swissbit's public identity remains authorized at `adlerkopf` and the goal is not complete.
- A remote is unreachable. The owner reports it as not revoked; the lost public identity is not treated as removed there.

## Minimal guarantee
The lost public identity is not reported as revoked before the remote confirms it; the remaining credential is not removed or weakened; the case grants no new access and does not treat local credential records as remote revocation.

## Success guarantee
Every remote that authorized the lost security key's public identity no longer accepts that public identity.

## Personas
- Owner/operator (`owner--operator`), applied to the Device owner role: advisory critique — the lost key's authorization must be revoked at every remote, a failed or unreachable revocation must be visible, and the remaining credential must keep working. A green local action is not remote revocation.
- No family-application-user or new security-key persona is introduced.

## Capabilities
- none — proposal/spec will bind the revocation and verification capabilities.

## Interactions
- none — no remote administration protocol or account-recovery mechanism is selected here.

## Includes
- none — the authenticated session with the remaining credential is obtained through `authenticate-to-remote-host` as a precondition; it is not an Includes relationship.

## Extends
- none — no leaf-to-leaf extension is asserted.

## Out of scope
- Authenticating to a remote host with the personal identity — `authenticate-to-remote-host`.
- Losing both security keys and the device — no recovery mechanism is selected in this stage.
- Account/provider recovery, a third token, or an offline recovery key — not selected.
- Device privilege authentication, WebAuthn, SOPS age, and disk unlock — later staged surfaces.
- The work Mac (`J6G6Y9JK7L`) and work identities — not in the first stage.
- Local deletion of the lost key's handle file or credential record — not required by this goal.
- Recovering from a lost or unreadable handle file while the token remains — handled by the other credential or re-enrollment, not by this revocation goal.
- Any claim of theft resistance while the file-backed personal identity remains on `thiniel`.

## Diagram
See the rendered canvases in the [Event Storming](../eventstorming.md): [recover from a lost daily security key](../eventstorming.md#canvas-recover-from-a-lost-daily-security-key), [recover from a lost backup security key](../eventstorming.md#canvas-recover-from-a-lost-backup-security-key), and [revoke the lost key's public identity](../eventstorming.md#canvas-revoke-the-lost-keys-public-identity). These show proposed relationships, not an actual loss or revocation run.

## Scenario skeletons
- Given the daily security key is lost and the backup key can authenticate to every remote that authorized the daily key, When the owner revokes the daily public identity at each remote, Then every such remote no longer accepts it.
- Given the backup security key is lost and the daily key can authenticate, When the owner revokes the backup public identity at each remote, Then every such remote no longer accepts it.
- Given both security keys are lost and the file-backed personal identity can authenticate, When the owner revokes both public identities at each remote, Then every such remote no longer accepts them.
- Given a remote refuses the revocation or is unreachable, When the owner attempts it, Then the lost public identity remains treated as authorized there and the goal is not reported complete.
- Given the remaining credential cannot authenticate at a remote, When the owner attempts revocation there, Then that remote is reported blocked and the goal is not reported complete.
- Given the remote's confirmation is absent or contradicts the revocation, When the owner checks the result, Then revocation is not reported effective.
- Given the owner cannot distinguish a lost key from a temporarily absent one, When the key is unavailable, Then the present credential is not revoked.

These are contract skeletons, not a revocation implementation. Future end-to-end proof must exercise the actual remote authorization state, not a local configuration edit or a green command.

## Elaboration phase review — 2026-10-17

A fresh-context reviewer returned "pass with findings" and no blocker. Applied: verification is now the remote's confirmation or listing that the lost public identity is no longer authorized, not an authentication attempt with a key the owner no longer has; the both-keys-lost case is folded into the remaining-credential extension with a step reference; the minimal guarantee uses domain phrasing instead of "key-handle presence"; and skeletons cover a blocked remaining credential and an ineffective verification. No open contract fork remains for Handoff.
