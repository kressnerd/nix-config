# Change seed: storage-redundancy

Status: ready

- Use-case IDs: restore-storage-redundancy
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 4 after `provision-storage-host`; independent of the compute
  and edge seeds.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

A declared `pronix` storage pool survives a single storage-device failure with
its declared data readable, and returns to its declared redundancy after a
compatible replacement is installed and the rebuild completes. The result
distinguishes degraded from healthy and reports the replacement/rebuild state.
A pool is not claimed as a backup; application-state recovery is a separate
guarantee.

This seed covers one pool and one device failure. A two-device failure or full
pool loss is outside the guarantee.

## Accepted decisions

### Mirror redundancy, not parity or an application backup

- Context: the handover selects btrfs RAID1 data/metadata for the appdata and
  media pools and rejects MergerFS/SnapRAID. The first proof is the disk-pull
  test in the handover.
- Options:
  1. **btrfs mirrored pools with a device-pull and rebuild proof** — data
     remains readable through one device failure and redundancy is restored.
     In practice: pull one media SSD, the pool serves degraded; install a
     replacement, rebuild, confirm readability and redundancy.
     Gain: a real redundancy guarantee matching the handover.
     Cost: the pool is not a backup; a second failure or a host loss still
     requires separate recovery.
  2. **MergerFS/SnapRAID** — periodic redundancy.
     In practice: writes are not redundantly stored in real time.
     Gain: flexible disk mixing.
     Cost: rejected by the handover; the workload has frequent writes.
  3. **Treat a btrfs snapshot as the recovery proof** — keep a same-host
     snapshot.
     In practice: a snapshot survives a file deletion but not the pool/host
     loss.
     Gain: no replacement-device work.
     Cost: not a redundancy or recovery guarantee.
- Chosen: **btrfs mirrored pools with a device-pull and rebuild proof**.
  Rejected: MergerFS/SnapRAID because it is not real-time redundancy;
  snapshots because they do not survive the storage failure boundary.

## Open questions

### Actual pool devices and replacement procedure

Which device IDs form each pool, which pool is tested first, and what is the
supported replacement/rebuild procedure? The test must use the declared pool,
not an empty fixture or a same-disk snapshot.

### Capacity and growth (A7)

The handover assumes 500 GB today and +250 GB/year. Which pool is the first
capacity risk, and what is the supported replacement/expansion path? A pool
that cannot be expanded without data loss is not a complete guarantee.

### Scrub and monitoring

What scrub schedule detects latent errors, and which health signal reports a
degraded pool? The redundancy seed may consume the health seed's alerting, but
it must not claim an alert that does not exist.
