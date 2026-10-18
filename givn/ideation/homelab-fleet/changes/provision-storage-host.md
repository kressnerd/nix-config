# Change seed: provision-storage-host

Status: proposed by provision-storage-host

- Use-case IDs: provision-host
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 1. No prerequisite seed; `pronix` hardware and firmware checks
  (P1/P2/P3) must be usable before implementation.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

`pronix` is accepted into the fleet with its declared base system, storage
layout, network attachment and storage/infrastructure roles. The host boots
with the declared unlock path (the manual passphrase fallback is acceptable
for this seed) and its declared storage exports are reachable from the intended
storage network. Unattended boot, redundancy proof, edge publication,
updates, host recovery and health observation are separate seeds.

This is a host-level guarantee. It does not claim an application is available,
an application state is recoverable, or a service role is healthy beyond its
declared acceptance check.

## Accepted decisions

### Host-level guarantee, not an application or config-only claim

- Context: `pronix` is the new storage/infrastructure host. The handover
  supplies its BIOS/microSD boot, LUKS2 pools, four bays, two NVMe and two
  NICs. The existing `adlerkopf` plans target different hardware and remain a
  separate fourth host (Q1/Q5).
- Options:
  1. **Deliver the accepted-host guarantee** — base system, storage layout,
     network and declared storage roles are present and checked.
     In practice: `pronix` boots, its pools are mounted, and its exports
     answer from the storage VLAN.
     Gain: a real storage host that later seeds can build on.
     Cost: P1–P3 and the real device/address values must be supplied before
     implementation; the manual passphrase fallback is still required.
  2. **Include unattended boot** — add Clevis/Tang in the same seed.
     In practice: `pronix` cold-starts without a passphrase.
     Gain: one operational host.
     Cost: depends on `tinix001` Tang, which does not exist yet; would create a
     circular first deliverable.
  3. **Configuration-only scaffold** — create `hosts/pronix` without a booted,
     accepted host.
     In practice: the flake evaluates but no host is accepted.
     Gain: fast to write.
     Cost: violates the accepted-host guarantee and gives later seeds no real
     target.
- Chosen: **Deliver the accepted-host guarantee**. Rejected: unattended boot
  because it depends on the compute host's Tang; config-only scaffold because
  it is not a host outcome.

## Open questions

### Real `pronix` device and boot values

What are the actual `/dev/disk/by-id` values for the microSD, ODD SSD, four
SATA SSDs and two NVMe devices; does P1 show both NVMe devices; does P2 boot
GRUB from microSD; and which kernel module drives the NIC (P3)? These block the
disko/hardware declarations and the first accepted-host check. Supply the
observed values, not guessed device names or documentation-range addresses.

### Pool 2 feasibility (A2)

Does the PCIe NVMe card expose both NVMe devices to Linux? If not, the
appdata pool is not a separate two-device pool; the seed must record the
reduced layout instead of silently claiming a pool that cannot exist.

### Real network and private values

Which LAN, storage VLAN, management VLAN and addresses does `pronix` use, and
which values are supplied by the private flake input? The public stub must
continue to evaluate without operational values.
