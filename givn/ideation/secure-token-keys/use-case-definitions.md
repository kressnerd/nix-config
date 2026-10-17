# Use Case Definition: secure token keys

Status: elaborated drafts 2026-10-17 — the first-stage cut with the use-case review's correctness findings applied; both leaves have contracts in `use-cases/`. The Use Case Elaboration phase review is pending. The user has not confirmed this cut as a Handoff record. It selects no implementation or release order.

This cut follows the confirmed Frame (remote identity on `thiniel`, Swissbit daily, Solo 2 backup, file-backed personal identity retained, no theft-resistance claim) and the confirmed terms. It covers the first stage only; the later staged surfaces are not cut into use cases here.

## Leaf goals and boundaries

Every proposed case is level `!`, with one primary actor and one observable outcome. Each is a separate future permanent leaf candidate. No summary use case is needed; the topic itself is not a permanent use case.

| Stable use-case ID | Actor's goal | Primary actor | Nature | Single outcome / closure | Boundary and affected stakeholders |
|---|---|---|---|---|---|
| authenticate-to-remote-host | Authenticate to a remote host with the personal identity | Device owner | Changing | The remote host accepts a connection that presents the personal identity through a valid credential. | The daily security key, the backup security key, and the file-backed personal identity are alternative credentials under this one goal. When the daily key is present, the stage requires token-preferred use and no silent substitution. The case does not authorize commands or resources inside the session; the remote's own rules apply. It does not claim theft resistance. Owner only. |
| recover-lost-security-key | Revoke a lost security key's public identity at every remote that authorizes it | Device owner | Changing | Every remote that authorized the lost key's public identity no longer accepts it. | Covers losing the daily key, the backup key, or both, while a remaining credential can authenticate: the other security key or the file-backed personal identity. The owner reaches the remotes through that remaining credential. Does not cover losing both security keys and the device, account/provider recovery, or a third token. A failed revocation is not success. Owner only. |

## Sizing checks and mutation ownership

- **One goal / one actor:** authentication and revocation are separate actor outcomes. Recovery's continued access is a precondition and observed condition, not part of its success guarantee; the success guarantee is the revocation itself. Neither goal joins two outcomes with "and".
- **Closure:** the owner can stop after a remote host accepts the connection, or after every lost public identity is no longer accepted at every remote that authorized it. The system is left consistent: no session was silently replaced, and no lost authorization is reported as removed without remote confirmation.
- **Goal-shaped, never component-shaped:** the names and goals do not name libfido2, `ed25519-sk`, PAM, OpenSSH, a key handle, or a configuration file. A security key is the owner's domain noun for the authenticator, not a technical component in the goal.
- **Level discipline:** both cases are `!` leaves; they own their capabilities directly. No `+` summary is introduced. The setup events (recognize, enroll, authorize, retain fallback) are preconditions/subfunctions, not separate value-ready leaves.
- **Mutation containment:** authentication establishes a session (changing), but it does not mutate application data or grant resources beyond the remote's own access rules. Recovery changes the remote's authorization set by revoking the lost public identity.
- **Precondition and flow consistency:** the credentials and remote authorizations must exist before authentication; the flow establishes the session, not the enrollment. Recovery's preconditions are a remaining credential that can authenticate and reachability of every remote that authorized the lost key; the flow establishes the revocation, not the loss. The remaining credential is used through `authenticate-to-remote-host`; that is a precondition dependency, not an Includes relationship.
- **Implementation independence:** Goal, Trigger, Main flow, and Guarantees remain true if the device configuration, key type, or remote implementation changes. Mechanism vocabulary stays in the design and capability sections.
- **Relationship semantics:** no Includes relationship exists between the two leaves. Recovery consumes an authenticated session with the remaining credential, which is the authentication goal's outcome; consuming an outcome as a precondition is not Includes. No Extends relationship to a fragment is introduced.

## First-stage binding constraints

These are stage rules, not additional use cases. They keep the credential-agnostic authentication outcome from silently waiving the confirmed first stage.

- **Token-preferred daily use.** When the daily security key is present and usable, the device uses it for the personal identity's remote connections. The file-backed personal identity is used only when the token is unavailable or the owner explicitly selects the fallback. The device never substitutes one credential for another silently.
- **Enrollment and authorization are separate.** A recognized or enrolled security key grants no access until its public identity is authorized at the remote. Authorization alone, without the matching credential, cannot authenticate.
- **The file-backed personal identity is a fallback, not theft resistance.** It remains on `thiniel` in this stage; the stage does not claim that a stolen device or copied home directory yields no usable SSH identity.
- **A lost key is revoked at every remote that authorized it.** The owner does not select a convenient subset. The authoritative remote inventory is an elaboration input, but the outcome quantifies over all of it.
- **A failed revocation is not success.** If a remote does not confirm removal, the lost public identity is still treated as authorized there.
- **Both keys lost while the device remains.** The file-backed personal identity can authenticate, and each lost public identity must be revoked. Loss of both keys and the device is outside this stage.

## Shared subfunctions and consequences — not new permanent leaves

| Element | Treatment | Reason |
|---|---|---|
| Recognize a security key and enroll the daily and backup credentials | `-` setup subfunction of authentication | Enrollment and recording the key handle create no usable access by themselves; the remote must still authorize the public identity, and the value appears only when a connection authenticates. |
| Authorize the public identity at each remote host | `-` setup subfunction of authentication | A remote grant is a precondition of the authentication outcome; it is not a separate actor goal in this stage. It is modeled as an event partner, not a leaf. |
| Security key not recognized, or public identity authorization rejected | `-` setup failure | These are setup failures, not authentication outcomes; the owner cannot authenticate with that credential until setup succeeds. |
| Retain the file-backed personal identity | `-` fallback precondition of authentication | The owner chose a fallback rather than removing the file key. It is a configuration constraint, not a goal. |
| Security key presence not confirmed, token-held authentication rejected, file-backed authentication rejected | `-` extensions of authentication, detailed in Use Case Elaboration | Each protects the authentication guarantee or reports its failure; none introduces a new actor goal. |
| Both security keys unavailable while the device is present | `-` failure path inside authentication | The file-backed personal identity can still authenticate; this protects the access goal. |
| Both security keys and the device are lost | Out of scope for this stage | No recovery mechanism is selected; the file-backed personal identity is lost with the device. The later recovery decision governs. |
| Remote account recovery and provider consoles | External, out of scope | The first stage keeps the file-backed personal identity and does not select account recovery as its path. |
| PAM/login, WebAuthn, SOPS age, disk unlock, work Mac, work identities | Later staged surfaces | Confirmed out of scope by the Frame; not cut here. |

## Advisory persona value assessment

These assessments apply the confirmed review lenses; they are not interviews, satisfaction scores, or release sequencing.

| Goal | Owner/operator lens | Family application-user lens |
|---|---|---|
| Authenticate to a remote host | High: the owner carries the token and reaches the personal remotes with token-preferred use, while the chosen fallback keeps the first stage recoverable. | None: the family user does not use the owner's SSH identities or administer the infrastructure. |
| Recover a lost security key | Critical: a lost key is a real first-stage event; every remote that authorized it must stop accepting it, and a failed revocation must be visible. | None. |

## Open inputs and exclusions

- The authoritative first-stage remote inventory is an operating input: GitHub personal and the servers that already authorize the `thiniel` personal identity are named, but the list is not audited here. The recovery outcome quantifies over that inventory; it is not an owner-selected subset.
- The Swissbit model and resident-key capacity are not needed for the use-case contract; they affect the design's choice between resident credentials and key-handle files.
- The exact udev rules and whether the Solo 2 needs `solo2-cli` in addition to `libfido2` are design inputs.
- The exact mechanism for token-preferred selection is a design decision; the stage rule requires the preference and forbids silent substitution, not a particular selection technique.
- A real security key cannot simply be attached to a QEMU VM. The future change must bind verification to a meaningful target (hardware, a virtual authenticator, or a host-level exercise) and must not claim a booted-VM proof that the target cannot supply.
- No PAM/login, WebAuthn, SOPS age, disk unlock, work Mac, work identity, account recovery, third token, or offline recovery key is included.
- The first stage does not claim that a stolen device or copied home directory yields no usable SSH identity; the file-backed personal identity remains on `thiniel`.

## Native verification constraints for later specifications

The repository binds scenarios to native `@check:`, `@host:`, or `@deploy:` targets, with exactly one resolving binding per scenario (`docs/GIVN-VERIFICATION.md`). No Gherkin runner is added. The existing `integration-ssh-identity-selection` check proves file-based identity resolution in a booted VM; it does not prove a token-held authentication. A future token check must exercise the actual key path and must disclose its platform limit. Evaluation, path membership, a key-handle file's presence, or a mock authenticator echo is not authentication proof.

## Use Case Definition phase review — 2026-10-17

A fresh-context reviewer returned "pass with findings" and no blocker. Applied: recovery's success outcome is now the revocation alone, with continued access as a precondition; recovery covers one or both lost keys while a remaining credential can authenticate; the outcome quantifies over every remote that authorized the lost public identity; presence and remote-rejection events are assigned as authentication extensions or setup failures; the recovery ID is `recover-lost-security-key`; the file-backed personal identity uses the confirmed term; token-preferred daily use is a binding first-stage rule. The cut is ready for elaboration.

## Next action

Handoff: ask which confirmed terms to promote to the durable glossary, then confirm the use-case-to-permanent mapping, persona choice, and one ready change seed. No persona is proposed; the owner/operator persona is the review lens. No change seed exists yet.
