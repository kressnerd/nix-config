# Proposal: host-specific-ssh-identities

## Release note

Each personal device uses the SSH identity that actually lives on it for private
repositories, so the laptop thiniel connects with its own `id_ed25519` instead
of a key path that only exists on the work MacBook.

## Use-Case Context

- Use-case ID: reproduce-working-environment
- Ideation topic: infrastructure-growth
- Seed path: none — this change covers one condition (permitted usable
  identities) of the ready seed `usable-personal-work`, whose deliverable
  guarantee spans the whole usable personal environment and stays open. No
  seed status line is stamped, because this change does not deliver that
  seed's end-to-end guarantee.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the affected
  surface is the owner's own device configuration and the owner is the only
  actor who evaluates whether private-repository access on that device works.
  `family--application-user` is not affected: no hosted application or shared
  resource changes here.

## Problem / Opportunity

The workspace declaration is shared between the work MacBook and the personal
laptop thiniel, but its identity selection is written for the MacBook only.

Two observations on thiniel today:

- The private-repository connection is declared to use
  `~/.ssh/id_ed25519_personal_2026-10-04`. That key exists only on the MacBook.
  thiniel holds exactly one personal private key, `~/.ssh/id_ed25519`.
  `ssh -G github-personal` on thiniel therefore reports an identity file that is
  not on the machine, and an SSH or Git operation for a private repository
  presents no usable key — access fails although the device is configured and
  holds a valid key.
- The same declaration adds connection entries for the three work identities
  (company, client001, client002) and includes three manually maintained
  work-laptop SSH configuration files. thiniel holds no secret material for
  those identities and none of those files exist, so the entries are
  unreachable declarations of the work laptop's environment.

Operator impact: the owner cannot use private repositories from thiniel, and
the device's declared identity surface claims keys and files the device does
not have. Any host that is not the work MacBook inherits the same defect.

## Proposed Solution

The identity selection follows the device, from one declared source per host:

- Each host declares the private key path of its personal identity. thiniel
  declares the key it holds, `~/.ssh/id_ed25519`; the work MacBook keeps
  `~/.ssh/id_ed25519_personal_2026-10-04`.
- A host declares a connection entry for a work identity only where that host
  holds the identity's secret material. thiniel holds none, so its
  configuration contains no company, client001 or client002 connection entry;
  the MacBook keeps all of them.
- The manually maintained work-laptop configuration files are included only on
  the host that maintains them.

Observable result on thiniel: asking SSH for the private-repository connection
resolves to `~/.ssh/id_ed25519`, the identity configuration used inside the
private workspace names the same key, and no connection entry or include
references an identity whose secret material the device does not hold. On the
MacBook the resolved identity files, the work identity entries and the includes
stay exactly as they are today.

## Capability Routing

`givn spec route --change host-specific-ssh-identities` reported **no signal —
no command, token, or lexical overlap**. The permanent corpus is empty
(`givn/specs/` holds no use case), so both columns record the decision.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| permitted-identity-selection | no signal — no command, token or lexical overlap, because the permanent corpus is empty | NEW in reproduce-working-environment | The identity condition of the personal-work contract is the only fitting owner: the actor goal is the device owner resuming usual work on a chosen device, and "permitted usable identities" is one of its named conditions. No component-shaped use case is introduced (the sizing rules reject names like "ssh configuration"), and no other leaf owns device identity access. |

Because this is the first permanent capability in the repository, the change
carries the owning use-case document (`reproduce-working-environment`) together
with the capability delta, so the use case and its capability are archived
atomically. That document is the already elaborated, accepted-scope ideation
contract, carried over with its stable ID, guarantees, rules and open-question
qualifiers intact; its Capabilities section is the only edited part.

## Out of Scope

- Generating, rotating, copying or transferring any private key. thiniel already
  holds `~/.ssh/id_ed25519`; nothing about key material changes.
- Reconstructing a lost private credential from a path reference, or any other
  part of the usable-personal-work seed (required working files, application
  state, retrieval/restoration, bootstrap of further identities).
- Changing the MacBook's effective configuration: its resolved identity files,
  work identity entries and includes must stay as they are today.
- The work machine's manually maintained SSH configuration file contents. No
  step of this change reads, writes or verifies them.
- SSH agent forwarding, host key management, and any other reachability
  contract (`adjust-application-reachability`, `recover-hosted-applications`).

## Open Questions

### D1 — Does thiniel need the work identity connection entries at all?

- Question: Should thiniel keep connection entries for the company, client001
  and client002 identities even though the device holds no secret material for
  them and no manually maintained include files exist?
- Options:
  1. **Declare work entries only where their secret material exists** — thiniel
     declares none; the MacBook keeps all three.
     In practice: `ssh -G github-company` on thiniel resolves through the
     wildcard entry only, while the MacBook still resolves
     `~/.ssh/id_ed25519_company_2025-06-18`.
     Gain: every declared entry on a device is backed by material the device
     has; one device stops carrying another device's identity surface.
     Cost: if the owner later does work-repository access from thiniel, the
     entry appears only after that identity's secret material is declared for
     thiniel — the same prerequisite the key itself already has.
  2. **Keep the work entries on every device** — thiniel keeps the three entries
     and the three includes unchanged.
     In practice: thiniel's configuration keeps naming
     `~/.ssh/id_ed25519_company_2025-06-18` and `config.d/company` although
     neither exists there, so a work repository connection from thiniel fails
     with a missing-identity error instead of a clear configuration state.
     Gain: no change beyond the personal key path.
     Cost: the device keeps declaring identities and files it does not have;
     the reported defect class remains for the work entries.
- Disposition: **answered** — option 1, on evidence. thiniel's declaration
  already declares no work secret material (`git/company/name`,
  `git/client001/name`, `git/client002/name` exist only for the MacBook), and
  the personal git configuration already gates the work identity profiles on
  exactly that material; thiniel therefore has no work identity configuration to
  connect with. The repository contains no other definition or consumer of
  `config.d/company`, `config.d/client002` or `config.d/nix-builder`. Declaring
  connections there cannot succeed and only re-states the work laptop's
  environment.

### D2 — Which key does thiniel's personal identity use?

- Question: Is thiniel's private-repository identity the device's
  `~/.ssh/id_ed25519`, and is that the approved identity source for this device?
- Options:
  1. **Use the device key `~/.ssh/id_ed25519`** — thiniel's personal identity
     resolves to the one personal private key the device holds.
     In practice: `ssh -T git@github-personal` on thiniel authenticates with
     `~/.ssh/id_ed25519` and private-repository `git fetch` succeeds.
     Gain: the device is usable for private repositories with the material it
     already has; no key is copied between devices.
     Cost: the key path is now a per-device declaration that must be supplied
     when a further device is added.
  2. **Supply a separate per-purpose key for thiniel** — thiniel receives its
     own dedicated personal key before this change is completed.
     In practice: the owner generates a personal key on thiniel, and the change
     waits for that path.
     Gain: one key per purpose, matching the MacBook's convention.
     Cost: key generation is a manual owner action and blocks the fix; the
     current device key remains unused until then.
- Disposition: **answered** — option 1, supplied by the operator in the change
  request ("the ssh key present on this machine (only id_ed25519)"). This closes
  the `(open: Q16)` qualifier of the owning use case **for this device's
  personal identity only**; the remaining approved state/source inventory stays
  open.
