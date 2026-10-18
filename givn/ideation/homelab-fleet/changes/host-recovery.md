# Change seed: host-recovery

Status: ready

- Use-case IDs: recover-host
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 8 after `provision-storage-host`, `provision-compute-host`
  and `preserve-host-state`; the surviving source is a dependency, not an
  assumption. It may run after the health seed; failure observation is a
  precondition, not necessarily an implemented alert.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

A failed host's declared role and persistent system state are restored on a
replacement host, and the role answers again. The state source survives the
declared failure boundary; a fresh install, a same-host persistence area or a
source reference that regenerates missing material is not recovery. The result
distinguishes host recovery from application-data recovery and reports an
unreadable source or a failed role check as a failure.

## Accepted decisions

### Host role and system state, application recovery separate

- Context: the handover includes an off-site restic target and DB dumps, but
  application-state recovery is already owned by `infrastructure-growth`
  (`recover-hosted-applications`). A recovered host must not silently claim a
  recovered application.
- Options:
  1. **Host role plus declared system state; application recovery separate** —
     restore the host and report application recovery as pending.
     In practice: a replacement `tinix001` boots, the declared system state is
     restored, its roles answer; the photo application's data recovery is a
     separate step.
     Gain: a truthful host-level guarantee without duplicating the application
     topic.
     Cost: the owner may need two recovery steps for a full application return.
  2. **Include all application state in host recovery** — one big restore.
     In practice: the host and all application data return together.
     Gain: one operation.
     Cost: duplicates `infrastructure-growth`, conflates host and application
     consistency, and may claim a restore the state source does not support.
  3. **Fresh install only** — rebuild the host and re-create state manually.
     In practice: the host is new but the persistent system state is missing.
     Gain: no state-source dependency.
     Cost: not recovery; the declared role may not be restorable.
- Chosen: **Host role plus declared system state; application recovery
  separate**. Rejected: all application state because it duplicates the
  application topic; fresh install because it is not recovery.

## Open questions

### Approved state source and bootstrap

Which source holds the host's persistent system state and bootstrap, and does
it survive the declared failure boundary? The source is created by the
`preserve-host-state` seed; if that seed is not delivered, this recovery seed
cannot claim its guarantee. A reference that regenerates missing private
material is not a source.

### Replacement hardware and identity

Which replacement hardware or instance is available, and how is the host's
identity and secrets bootstrap re-established without conflicting with the
failed host?

### Application recovery dependency

For each host, which application data and access recovery must follow the host
recovery? The seed must not claim the application result even when the host
role answers.
