# Change seed: fleet-update

Status: ready

- Use-case IDs: apply-fleet-update
- Topic: homelab-fleet
- Personas: owner--operator, family--application-user
- Suggested start: 6 after `provision-storage-host`, `provision-compute-host`
  and `unattended-storage-boot`; it needs the declared hosts and the Tang
  order.
- Handoff: ready input to `/givn-propose`; no change was started by ideation.

## Deliverable guarantee

The declared hosts apply the intended software update inside their declared
windows, reboot only when required and only inside the window, and their
declared services return. The Tang host is running while `pronix` reboots. A
failed update, a deferred reboot, a rollback or a service that does not return
is reported as such; a green activation alone is not the guarantee.

This seed does not create an application-state backup or claim application
recovery.

## Accepted decisions

### Window-bound update with service return, not a green rebuild

- Context: the handover declares per-host windows (`pronix` 04:00, `tinix001`
  05:00, `cupix001` 03:00) and requires the Tang host to be running when
  `pronix` reboots. Auto-upgrade must not reboot outside the window.
- Options:
  1. **Declared windows, reboot only when required, service-return check** —
     the update is complete only when the services return.
     In practice: `pronix` updates at 04:00, reboots before 04:45, and its
     storage roles return while `tinix001` serves Tang.
     Gain: predictable service windows and a truthful result.
     Cost: the window, order and rollback path must be real; a rollback is not
     the intended update.
  2. **Auto-upgrade with immediate reboot whenever required** — no window.
     In practice: a host can reboot during the day.
     Gain: faster updates.
     Cost: violates the declared window and can interrupt services.
  3. **Manual update only when the owner remembers** — no declared window.
     In practice: hosts drift and the Tang order is not enforced.
     Gain: no scheduler.
     Cost: no reliable update guarantee.
- Chosen: **Declared windows, reboot only when required, service-return
  check**. Rejected: immediate reboot because it violates the window; manual
  only because it has no guaranteed result.

## Open questions

### Real window and reboot order

Are the handover's windows and the Tang-before-`pronix` order the intended
ones? Which host may reboot while another is updating, and what is the
supported rollback path if a service does not return?

### Update autonomy and approval

Does the fleet apply updates without per-update approval, or does the owner
approve each host? The guarantee requires a declared policy; an undeclared
approval step is not a silent success.

### Kernel/initrd updates on `pronix`

A kernel, module or initrd change can require a reboot. Does the `pronix`
window leave enough time for the Clevis/Tang unlock and storage role return?
P4/P10 remain checks, not facts.
