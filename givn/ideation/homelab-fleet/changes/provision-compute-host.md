# Change seed: provision-compute-host

Status: ready

- Use-case IDs: provision-host, boot-host-unattended
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 2 after `provision-storage-host`; `tinix001` needs the
  storage host's NFS exports for its declared mounts and supplies Tang for the
  later unattended `pronix` seed.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

`tinix001` is accepted into the fleet with its declared base system, system
storage pool, LAN and storage-VLAN attachment, NFS automounts and declared
service roles. It unlocks its encrypted root through TPM2 on a cold start and
exposes Tang to the storage network. A TPM failure is reported and falls back
to the retained passphrase; it is not presented as an unattended success.

This is a host-level guarantee. It does not claim the applications are
available, their data is recoverable, or the public edge is published.

## Accepted decisions

### TPM2 unlock and Tang belong to the compute host's first deliverable

- Context: `tinix001` is the compute host with TPM 2.0 (A3), two NVMe devices
  and one NIC with a storage VLAN subinterface. Tang runs on it so `pronix` can
  unlock later; Tang is not useful without the compute host.
- Options:
  1. **TPM2 unlock plus Tang in this seed** — the host boots unattended and
     serves Tang on the storage VLAN.
     In practice: a cold start reaches the declared roles without a
     passphrase; `pronix` can later use Tang.
     Gain: the unattended compute host and the prerequisite for `pronix`.
     Cost: P5 (TPM) and P4 (Tang reachability) must be usable; the passphrase
     slot remains.
  2. **Passphrase-only first, TPM later** — provision the host with the manual
     fallback and defer TPM.
     In practice: the host boots only after a console passphrase.
     Gain: less hardware dependency.
     Cost: the compute host is not unattended, and the first boot chain seed
     remains incomplete.
  3. **Put Tang on `pronix`** — avoid `tinix001` as the Tang host.
     In practice: `pronix` serves Tang for itself.
     Gain: fewer hosts in the unlock chain.
     Cost: contradicts the handover's decision to separate the Tang trust
     anchor from the storage host and creates a self-unlock dependency.
- Chosen: **TPM2 unlock plus Tang in this seed**. Rejected: passphrase-only
  because it does not meet the compute host's unattended guarantee; Tang on
  `pronix` because it contradicts the handover's trust-anchor split.

## Open questions

### Real `tinix001` hardware and TPM state (P5)

Is TPM 2.0 present and enabled, and which PCR policy is bound? What are the
actual NVMe device IDs and NIC name? Is the RX550 removed? These block the
hardware declaration, TPM enrollment and the first unattended cold start.

### NFS mounts and storage VLAN

Which exports, mount points and storage-VLAN address does `tinix001` use, and
which applications depend on each mount? A mount that is declared but not
available must fail the acceptance check rather than start a service against a
missing path.

### Tang keys and scope

Where are Tang keys persisted, which storage-VLAN clients may reach them, and
how are they backed up? Tang must not be reachable from the LAN.
