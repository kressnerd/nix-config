# Use case: authenticate-to-remote-host

## Level
!

## Actors
- Primary: Device owner.

## Goal
The Device owner authenticates to a remote host with the personal identity using a valid credential.

## Trigger
The Device owner opens a connection to the selected remote host.

## Preconditions
- The personal identity has at least one usable credential: an enrolled token-held credential on the daily or backup security key, or the retained file-backed personal identity.
- The credential selected for this connection is authorized at the selected remote host; enrollment alone grants no access. An unauthorized or revoked credential is not selected or presented, even if its record remains in the identity declaration.
- The identity declaration records the credentials the device holds and their preference order.
- The credential to be used for this connection is available and usable: an addressable security key for a token-held credential, or a present identity file for the file-backed personal identity. Which credential is available is handled by the main flow and extensions.
- The Device owner is authorized to use the personal identity and the selected remote host is reachable.

## Main flow
1. Actor Device owner opens a connection to the selected remote host; System identifies the personal identity and the credentials the device holds.
2. System selects the daily security key when it is present and usable; Actor Device owner confirms presence on the security key.
3. System presents the daily token-held public identity to the remote host; the remote host checks whether that public identity is authorized.
4. System establishes the authenticated session after the remote accepts; System reports which credential authenticated.
5. Actor Device owner obtains the session; System reports the remote and the credential used.

## Extensions
- 2a: The daily security key is absent or unavailable → Actor Device owner may select the backup security key or the retained file-backed personal identity; System uses the selected credential; protects the access outcome. The device never substitutes a credential silently.
- 2b: The Device owner does not confirm presence → System reports that no token-held authentication occurred and establishes no session; protects the authentication guarantee.
- 2c: Both security keys are unavailable → System offers the retained file-backed personal identity when it is present and authorized; if it is also unavailable, System reports that no first-stage credential can authenticate; protects the access outcome.
- 2d: The Device owner determines that the daily or backup security key is lost rather than temporarily absent → System does not treat the loss as a normal fallback; the owner continues with the remaining credential and hands off to `recover-lost-security-key` for revocation; protects the recovery boundary.
- 3a: The remote host rejects the presented public identity, or the credential is revoked there → System reports the rejection and establishes no session; it does not silently try another credential; protects the authentication guarantee.
- 1a: No credential is enrolled or authorized at the remote → System reports the unmet setup prerequisite and establishes no session; protects the authentication guarantee.

## Rules
- When the daily security key is present and usable, the device uses it for the personal identity's remote connections. The file-backed personal identity is used only when the token is unavailable or the owner explicitly selects it.
- The device never substitutes one credential for another silently. The credential used is reported.
- A token-held authentication requires user presence on the security key; a declined or missed presence prompt establishes no session.
- Enrollment grants no access. The remote must authorize the presented public identity, and a rejected or revoked public identity is not retried with another credential. A credential the remote has not authorized, or has revoked, is not selected or presented.
- The session does not grant commands or resources inside the remote beyond the remote's own access rules; those are outside this use case.
- The file-backed personal identity remains on `thiniel` in this stage. The stage does not claim that a stolen device or copied home directory yields no usable SSH identity.
- The stage does not claim protection against a malicious local process or remote-account compromise; per-use verification and WebAuthn are later stages.
- A failed, unconfirmed, or rejected attempt is not an authenticated session, even if the device can reach the remote.

## Examples
- The daily Swissbit is present and authorized at the personal GitHub account. The owner runs `git push`; the device selects the Swissbit, the owner touches it, GitHub accepts the public identity, and the session reports the daily security key as the credential used.
- The daily Swissbit is absent. The owner retrieves the Solo 2, selects the backup security key, and touches it; the remote accepts the backup public identity, and the session reports the backup security key.
- Both security keys are unavailable, but `~/.ssh/id_ed25519` is present and authorized. The owner selects the file-backed personal identity; the remote accepts it, and the session reports the file-backed personal identity. This is the first-stage fallback, not theft resistance.
- The owner opens a connection and declines the presence prompt. No session is established; the device reports that token-held authentication did not occur.
- The remote has revoked the daily public identity. The owner touches the Swissbit; the remote rejects the connection, and the device does not silently fall back to the file-backed personal identity.
- The owner realizes the Swissbit is lost rather than merely absent. The owner authenticates with the Solo 2 to reach the remotes; the loss is handled by `recover-lost-security-key`, not by treating the loss as a normal fallback.

## Minimal guarantee
No authenticated session is established without a credential the remote accepts; the device does not silently substitute a different credential; a failed, unconfirmed, or rejected attempt grants no access; the retained file-backed personal identity is not removed by an authentication attempt.

## Success guarantee
The remote host accepts the connection that presents the personal identity through a valid credential.

## Personas
- Owner/operator (`owner--operator`), applied to the Device owner role: advisory critique — token-preferred daily use, explicit fallback, and an honest no-theft-resistance claim are required; a session that silently uses the file key is not the accepted first-stage behavior.
- No family-application-user or new security-key persona is introduced; the family user does not use the owner's SSH identities.

## Capabilities
- none — proposal/spec will bind the enrollment, authorization, selection, and verification capabilities.

## Interactions
- none — no remote protocol, key type, or transport is selected here.

## Includes
- none — enrollment and authorization are setup subfunctions, not separate leaves included by this case.

## Extends
- none — no leaf-to-leaf extension is asserted. The lost-key handoff is a boundary to `recover-lost-security-key`, not an extension that performs revocation inside this case.

## Out of scope
- Revoking a lost security key's public identity — `recover-lost-security-key`.
- Device privilege authentication, WebAuthn, SOPS age, and disk unlock — later staged surfaces.
- The work Mac (`J6G6Y9JK7L`) and work identities — not in the first stage.
- Commands or resources used inside the authenticated session — the remote's own access rules govern them.
- Account/provider recovery when both security keys and the device are lost.
- Any claim of theft resistance while the file-backed personal identity remains on `thiniel`.

## Diagram
See the rendered canvases in the [Event Storming](../eventstorming.md): [authorize the public identities at the remote](../eventstorming.md#canvas-authorize-the-public-identities-at-the-remote), [authenticate with the daily security key](../eventstorming.md#canvas-authenticate-with-the-daily-security-key), [authenticate with the retained file-backed identity](../eventstorming.md#canvas-authenticate-with-the-retained-file-backed-identity), [authenticate with the backup security key](../eventstorming.md#canvas-authenticate-with-the-backup-security-key), and [both security keys unavailable](../eventstorming.md#canvas-both-security-keys-unavailable). These show proposed relationships, not an enrollment or authentication run.

## Scenario skeletons
- Given the daily security key is present and its public identity is authorized at the remote, When the Device owner opens a connection and confirms presence, Then the remote accepts the connection and the daily security key is reported as the credential used.
- Given the daily security key is absent and the backup security key's public identity is authorized, When the Device owner selects the backup and confirms presence, Then the remote accepts the connection and the backup security key is reported.
- Given both security keys are unavailable and the file-backed personal identity is present and authorized, When the Device owner selects the fallback, Then the remote accepts the connection and the file-backed personal identity is reported.
- Given the owner declines the presence prompt, When the connection is attempted, Then no session is established.
- Given the remote has revoked the presented public identity, When the owner attempts the connection, Then the remote rejects it and the device does not silently substitute another credential.
- Given no credential is enrolled or authorized at the remote, When the owner attempts the connection, Then the unmet setup prerequisite is reported and no session is established.
- Given the daily security key is lost rather than temporarily absent, When the owner continues with the remaining credential, Then the loss is handed to `recover-lost-security-key` and is not treated as a normal fallback.

These are contract skeletons, not a configuration or authentication implementation. Future end-to-end proof must exercise a meaningful actual token path through a native target; a key-handle file's presence or a mock authenticator echo is not authentication proof.

## Elaboration phase review — 2026-10-17

A fresh-context reviewer returned "pass with findings" and no blocker. Applied: the precondition requires only the selected credential to be authorized, so a revoked credential record does not make later connections impossible; the availability precondition no longer requires a token and the file identity at the same time; the "enrolled credential" term is used only for token-held credentials; the remote, not the System, checks authorization; the contract states that an unauthorized or revoked credential is not selected or presented; and the loss-versus-absence skeleton is present. No open contract fork remains for Handoff.
