# Change seed: unattended-storage-boot

Status: ready

- Use-case IDs: boot-host-unattended
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 3 after `provision-compute-host` (Tang) and
  `provision-storage-host` (the host to unlock). It can follow the storage
  redundancy seed without depending on it.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

`pronix` cold-starts without a person entering a passphrase at the console. It
receives its root release from Tang on `tinix001` over the storage VLAN, starts
its declared storage roles, and reports service readiness. If Tang is
unreachable or refuses the release, the automatic guarantee is reported as not
met and the retained passphrase fallback through initrd-SSH or the iLO serial
console remains available. A manual unlock is not presented as an unattended
success.

This seed does not claim application availability, storage redundancy or host
recovery.

## Accepted decisions

### Clevis/Tang for `pronix`, passphrase retained, manual fallback reported

- Context: the handover selects Clevis/Tang for `pronix` because the USB
  keyfile alternative would weaken encryption-at-rest. `tinix001` is the Tang
  host. The shared-theft threat (both hosts stolen) is accepted and must be
  documented.
- Options:
  1. **Automatic Tang unlock with a retained passphrase and initrd-SSH/iLO
     fallback** — the unattended path is the guarantee; the fallback protects
     availability and is reported separately.
     In practice: a normal cold start unlocks in under three minutes; with Tang
     absent, the host waits in the initrd and the owner can unlock manually.
     Gain: no on-site keyboard and no USB keyfile; a truthful failure mode.
     Cost: the Tang host must run before `pronix` reboots; P4 and P10 must be
     usable.
  2. **USB keyfile in the chassis** — remove the network dependency.
     In practice: the host unlocks from a local key.
     Gain: no Tang dependency.
     Cost: encryption-at-rest is weakened because the key is stored with the
     host; rejected by the handover.
  3. **Passphrase-only** — keep a manual unlock on every boot.
     In practice: every cold start needs a person at the console.
     Gain: simplest trust model.
     Cost: no unattended reboot; fails the guarantee.
- Chosen: **Automatic Tang unlock with retained passphrase and fallback**.
  Rejected: USB keyfile because it weakens encryption-at-rest; passphrase-only
  because it is not unattended.

## Open questions

### Clevis retry and Tang outage behavior (P4)

How long does the initrd retry when Tang is unreachable, and does it eventually
fall back without blocking the console? What does the owner see through
initrd-SSH and the iLO serial console? A retry that never yields or a fallback
that is unreachable fails the guarantee.

### iLO serial prompt (P10)

Does the iLO Virtual Serial Port show the LUKS prompt without the Advanced
license, and is the console usable at the declared baud rate? If not, the
fallback exists only through initrd-SSH and must be reported as such.

### Threat model and key rotation

Is the shared-theft risk (both `pronix` and `tinix001` stolen) accepted in
writing? How are Tang keys rotated and re-bound after a rotation? A missing
rotation procedure leaves the unlock chain unmaintainable.
