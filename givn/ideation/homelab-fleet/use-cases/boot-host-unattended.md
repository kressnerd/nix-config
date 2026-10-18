# Use case: boot-host-unattended

Status: elaborated domain draft 2026-10-17; not an implementation, selected
unlock mechanism or observed boot.

## Level
!

## Actors
- Primary: Owner/operator.
- Supporting: Unlock authority for the Owner/operator (Tang or TPM); the
  authority performs the release under the declared policy.

## Goal
The Owner/operator boots an encrypted host without on-site intervention, so the
host reaches its declared services after a cold start without a person entering
a passphrase at the console.

## Trigger
The Owner/operator starts the host, or the host reboots as part of its normal
operation.

## Preconditions
- The host is accepted into the fleet (`provision-host`) with its declared
  boot mode and encrypted root.
- Unlock material is enrolled for the host's declared authority: Tang for
  `pronix`, TPM2 for `tinix001`.
- A retained passphrase slot exists for the manual fallback.
- The authority is reachable for the host's declared mode: the Tang host is
  running for `pronix`; the TPM is present and its binding is valid for
  `tinix001`.
- A fallback path exists: initrd-SSH and, for `pronix`, the iLO serial console
  (P10).
- The host's declared service roles are known.

## Main flow
1. Actor Owner/operator starts the host; System performs a cold start of the
   declared host.
2. System requests the root release from the declared authority; the Unlock
   authority for the Owner/operator releases the encrypted root.
3. System unlocks the root automatically; the host starts its declared service
   roles.
4. System reports the boot result, including whether the automatic path or a
   fallback was used.

## Extensions
- 2: The authority is unreachable, the release is refused, or the binding is
  invalid → automatic unlock fails; report the failure and enter the manual
  fallback. Protects availability without claiming the unattended guarantee.
- 2: The host cannot reach the authority because the network is not up → the
  same fallback applies; protects the boot guarantee and reports the network
  prerequisite.
- 3: Automatic unlock succeeds but a declared service does not start → report
  the boot as unlocked but not service-ready; protects the service guarantee.
- 3: The host remains in the initrd and the manual fallback is used → the host
  may become usable, but the unattended guarantee is not met; report the
  degraded mode explicitly.
- 3: The passphrase is unavailable or rejected → the host remains locked;
  report the failure without inventing another credential.
- 3: The host boots the wrong state or the wrong host identity → do not claim
  the declared host boot; protects fleet identity.

## Rules
- `pronix` uses Tang for automatic unlock; `tinix001` uses TPM2. The
  passphrase slot remains in every LUKS header as the fallback.
- Tang is reachable only from the storage VLAN; the LAN must not unlock
  `pronix`.
- The declared update order keeps the Tang host running while `pronix`
  reboots; a `pronix` reboot without a reachable Tang host is a failed
  automatic boot, not a silent success.
- A TPM binding can break after a firmware or Secure Boot change. Re-enrollment
  is a maintenance step; a broken binding is reported, not hidden.
- An unlocked root is not proof that services are available; the boot result
  distinguishes unlock from service readiness.
- A manual unlock protects availability; it does not satisfy the unattended
  guarantee and must be reported as a degraded mode.
- The Clevis retry behavior (P4) and the iLO prompt (P10) are checks, not
  facts; an unknown result prevents an unattended-readiness claim where the
  host depends on it.

## Examples
- `pronix` cold-starts while `tinix001` is running Tang. It unlocks
  automatically and starts its declared storage roles.
- `pronix` cold-starts while `tinix001` is off. Automatic unlock fails; the
  host waits in the initrd. The owner unlocks through initrd-SSH or the iLO
  serial console. The host becomes usable, but the unattended guarantee is
  reported as not met for that boot.
- `tinix001` reboots normally and unlocks through TPM2. After a BIOS update,
  the PCR binding no longer matches; the owner uses the passphrase once and
  re-enrolls the TPM.
- A host unlocks but its NFS export does not start. The boot result says
  "unlocked, service not ready", not "boot successful".

## Minimal guarantee
Failure is reported without claiming an unattended boot, without removing the
passphrase slot, and without presenting a manual fallback as the automatic
guarantee.

## Success guarantee
The host reaches its declared services after a cold start without a person
entering a passphrase at the console.

## Personas
- Owner/operator (`owner--operator`): advisory critique — a manual unlock is
  not the unattended baseline; the failure and the fallback must be visible.
- Application user (`family--application-user`): advisory critique — the user
  experiences an outage, not an unlock procedure; no console or passphrase
  role is inferred.

## Capabilities
- none — actual owned capabilities and native verification targets are
  selected through the normal proposal/spec flow, not fabricated in ideation.

## Interactions
- none — no Tang, TPM or initrd command binding is selected.

## Includes
- none — enrollment and fallback are subfunctions of the one boot guarantee.

## Extends
- none.

## Out of scope
- Provisioning the host — `provision-host`.
- Restoring storage redundancy after a device failure —
  `restore-storage-redundancy`.
- Publishing a service at the edge — `reach-service-from-internet`.
- Applying a fleet update — `apply-fleet-update`.
- Recovering a failed host — `recover-host`.
- Observing fleet health — `observe-fleet-health`.
- Application availability or access — `infrastructure-growth`.

## Diagram
See [Canvas 1 — provision and boot a host](../eventstorming.md#canvas-1--provision-and-boot-a-host).
The unlock and fallback paths are shown there; this is not observed boot
behavior.

## Scenario skeletons
- Given an accepted `pronix` host with enrolled Tang material and a running Tang host, When `pronix` cold-starts, Then the root unlocks automatically and the declared services start.
- Given the same host when Tang is unreachable, When `pronix` cold-starts, Then the automatic unlock fails, the host waits in the initrd, and the manual fallback is reported.
- Given a `tinix001` host with a valid TPM binding, When it reboots, Then the root unlocks without a passphrase and the boot result reports service readiness.
- Given a TPM binding broken by a firmware change, When `tinix001` reboots, Then the owner uses the retained passphrase and the TPM re-enrollment is reported as required.
- Given a host that unlocks but whose declared service does not start, When the boot result is checked, Then the host is not reported as service-ready.

These are Markdown contract skeletons, not `.feature` deltas or asserted test
coverage. Real unlock results require a booted VM or confirmed hardware under
`docs/GIVN-VERIFICATION.md`; no binding name is invented here.
