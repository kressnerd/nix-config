# Change seed: preserve-host-state

Status: ready

- Use-case IDs: recover-host
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 7 after `provision-storage-host` and
  `provision-compute-host`; it must precede `host-recovery`, which consumes the
  surviving source.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.
  Added by the 2026-10-17 handover-coverage correction; the original eight-seed
  cut did not create a host-state source.

## Deliverable guarantee

A host's declared persistent system state and bootstrap have a usable copy
outside the failed host, and a supported restore check succeeds. The source
survives the declared failure boundary; a same-host persistence area, a local
snapshot or a reference that regenerates missing private material is not a
source. Application data and application-consistent recovery remain separate
(`infrastructure-growth`); this seed does not claim them.

## Accepted decisions

### Host system state is a separate source from application data

- Context: the handover's Phase 12 restic pipeline captures `/export` data and
  DB dumps for application recovery. The `recover-host` use case additionally
  requires the host's persistent system state and bootstrap, which the
  handover does not define as a backup source. Without this seed,
  `host-recovery` assumes a source that no seed creates.
- Options:
  1. **A dedicated host-state source** — copy the declared persistent system
     state and bootstrap to an approved off-host location, and verify a
     supported restore.
     In practice: a replacement `tinix001` restores its declared system state
     and role from the source; application data recovery is a separate step.
     Gain: the host-recovery guarantee has a real source.
     Cost: the source, retention and restore procedure must be supplied; the
     handover's application-data restic scope is not automatically sufficient.
  2. **Reuse the application-data restic repository as the host-state source** —
     add host system state to the same repository.
     In practice: one off-site repository holds both `/export` data and host
     state.
     Gain: one destination and one retention policy.
     Cost: the host-state paths and restore procedure must be added and
     verified; application consistency and host-state consistency are
     different claims.
  3. **No host-state source; recover only by fresh install** — rebuild the
     host and re-create state manually.
     In practice: the host is new but its declared system state is missing.
     Gain: no new source.
     Cost: not recovery; `recover-host` cannot meet its guarantee.
- Chosen: **A dedicated host-state source** because the handover does not
  define host system state as part of the application-data restic scope. The
  source may reuse the same destination if it is verified for both, but the
  guarantee and the restore check are host-state-specific. Rejected: reusing
  the application-data repository without adding and verifying host-state
  paths because it would claim coverage that does not exist; fresh install
  because it is not recovery.

## Open questions

### Approved host-state source and destination

Which paths constitute the host's declared persistent system state and
bootstrap, which off-host source holds them, and does that source survive the
declared failure boundary? The handover's restic target is a candidate
destination, not proof that host state is captured.

### Restore check and retention

What supported restore check proves the source is usable, and what retention
keeps a point that meets the host-recovery requirement? A green copy job is not
a verified restore.

### Encryption and bootstrap material

How is the copied host state protected at rest, and which bootstrap material is
required to restore it without assuming the completed host already exists? A
reference that regenerates missing private material is not a source.
