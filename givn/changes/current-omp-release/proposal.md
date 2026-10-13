# Proposal: current-omp-release

## Release note

Both personal devices run a current Oh My Pi (omp) coding agent from a freshly
pinned package set, with the same servers and decryption prohibition, and each
device refuses an agent older than 18.10.

## Use-Case Context

- Use-case ID: `reproduce-working-environment` — the permanent contract for a
  device reproducing the owner's usable working environment (intended tools and
  settings, required working state, permitted identity access).
- Ideation topic: none. This change has no ideation change seed; the use case's
  originating topic was `infrastructure-growth`, which is not re-opened here.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator
  runs this agent on both personal devices and is the one who judges whether the
  device carries a usable, current one. `family--application-user` is not
  affected: an agent's version and its decryption prohibition are not part of
  an application user's task.

## Problem / Opportunity

Measured on 2026-10-13:

- The laptop `thiniel` runs omp `18.8.4`, the build of 2026-10-08. Upstream's
  newest release is `18.10.3` (2026-10-12 19:23) — twelve releases in the five
  days since the installed build.
- The agent comes from the flake input `nixpkgs-unstable`, and that branch's
  head **is the revision this configuration already pins**
  (`8edc0c72`, 2026-10-08, carrying `18.8.4`). Refreshing the lock file
  therefore changes the agent by nothing — which is why the installed version
  is five days old while the same branch is described as "unstable".
- The only nixpkgs revisions that are newer are not much newer: the branch that
  does advance (`nixos-unstable`, 2026-10-11) carries `18.8.9`, and nixpkgs
  master (today) carries `18.10.0`. nixpkgs merges the agent's bumps about once
  a day, so its lag is structural, not accidental.
- The Mac `J6G6Y9JK7L` declares no agent at all — nothing in its home profile
  installs one. Any agent already present on that machine therefore came from
  outside this configuration, and with it the two shared servers and the
  repository's decryption prohibition are absent there while they hold on the
  laptop.

Operator impact: the daily-driver tool is twelve releases behind on both
devices, refresh looks like it should fix that but cannot, and the two devices
do not behave the same — the same agent on the Mac does not refuse `sops`,
`age -d`, `ssh-to-age`, or reads of decrypted material, on the machine that
holds the age private key unlocking every secret in this repository.

## Proposed Solution

Observable device state:

1. Each device installs the agent from a package set pinned at a revision that
   carries the agent at 18.10 or newer; refreshing that pin is how the operator
   takes a newer agent. Today that yields 18.10.0 on both devices.
2. Each device reports an agent version of at least 18.10 — never the 18.8 line
   the devices run today. The newest upstream release, 18.10.3, is deliberately
   not reachable this way (see Out of Scope).
3. The Mac carries the same agent setup as the laptop: the same two shared
   servers declared (documentation lookup, web search), the same secret-access
   guard installed as a regular file in the agent's user directory, and the same
   host-configuration assertion that the agent is installed.
4. On every device that carries the agent, a session that invokes `sops`,
   `age -d`/`--decrypt`, or `ssh-to-age`, or that reads decrypted material
   under `/run/secrets/`, a `sops/age/` path, or `/var/lib/sops-nix/`, is
   refused with the repository's policy message, in every approval mode.
5. The agent still starts: on a device that carries it, launching it reports the
   version of point 2.

Verification binding (each point bound to exactly one native target; see
`docs/GIVN-VERIFICATION.md`):

| Point | Native target |
|---|---|
| 1, 2, 3, 4 as configuration facts | `@host:thiniel`, `@host:J6G6Y9JK7L` |
| 3, 4 as declared module content | `@check:unit-helpers` (extends the existing agent unit tests) |
| 2, 4, 5 as behaviour of a running system | `@check:integration-*` — a booted Linux VM is the only target in this repository that observes real behaviour; this repository has no deploy-test layer (`tests/deploy/` does not exist), so the Mac's own launch is confirmed on the machine during implementation, not by a spec binding |

## Capability Routing

| Proposed capability | Route's recommendation | Decision | Rationale (if deviated from route) |
|---|---|---|---|
| `current-agent-tooling` | EXTEND `operational-data-separation` (score 11.80, confidence: signal) | `NEW in reproduce-working-environment` | Route matched keywords (`sops`, `configuration`, `operator`) that the agent module shares with the publication capability. That capability governs what the public repository records and says nothing about an agent's version, its servers, or its guard. The promised outcome here — a device that carries a usable, current agent with this repository's guardrails — is the working-environment use case's promise; its existing capability `permitted-identity-selection` covers identity material only, not tooling. |

## Out of Scope

- **Reaching the newest upstream release within minutes.** That needs upstream's
  own packaging or its signed release binaries; both are rejected here (D1).
- **Scheduled or automatic updates.** Refreshing the pin stays a deliberate
  operator action, justified by the version floor of point 2.
- **The agent's optional voice and local-inference addons.** They depend on host
  libraries; the change neither verifies them nor claims them.
- **What the agent is used for**: model configuration, provider settings, session
  content, hooks other than the decryption guard.
- **Other packages.** The target is the agent's source pin. Whether the
  freshening also advances the shared unstable input — and with it every other
  unstable package on both devices — is D2.
- **Rebuilding the Mac's existing out-of-band agent installation.** Whether it is
  removed is D4.

## Open Questions

### D1 — Where a current agent comes from

- Status: answered 2026-10-13 (user).
- Blocks: whether this change adds upstream packaging or a prebuilt vendor
  binary, or stays inside nixpkgs; it determines the whole implementation.
- Context (measured 2026-10-13): installed `18.8.4`; the followed branch's head
  is the pinned revision, also `18.8.4`; the advancing branch `nixos-unstable`
  has `18.8.9`; nixpkgs master has `18.10.0`; upstream's newest release is
  `18.10.3`, twelve releases newer than the installed build. nixpkgs batches the
  agent's bumps about once a day, so any channel trails.
- Options:
  1. **Freshen the nixpkgs pin** — meaning: the agent comes from a nixpkgs
     revision chosen for the version it carries and refreshed deliberately;
     gain: the official cache covers both platforms (verified: nixpkgs master's
     `18.10.0` for `x86_64-linux` and `aarch64-darwin` is served by
     `cache.nixos.org`), no new vendor enters the trust set, nothing is compiled
     here; cost: never current — structurally one to three days behind — and the
     pin must be refreshed to take a bump; in practice: a fix that lands in
     `18.10.2` reaches the devices one to three days after it shipped.
  2. **Repo-owned package from upstream's released binaries** — meaning: the
     repository keeps a version and two checksums per platform and fetches
     upstream's signed release binary (the shape the repository already uses for
     OpenCode 2.x); gain: current within minutes on both platforms, a bump is two
     hashes, nothing compiles; cost: a prebuilt vendor binary joins the trusted
     executables, and the Linux integration — the ELF version-section fix and the
     library paths for the optional addons — becomes this repository's to
     maintain; in practice: the 18.10.3 Linux binary, patched and passing
     upstream's own smoke test on the laptop, moves from 18.8.4 to 18.10.3 in one
     download.
  3. **Upstream's own Nix packaging as a pinned input** — meaning: the agent's
     build recipe comes from the project; gain: current to the hour (verified:
     its master carries `18.10.3` for both platforms) with no packaging owned
     here; cost: the cache the project advertises holds neither that master
     revision nor the `v18.10.3` tag (verified: absent for both), so every bump
     compiles the agent from source on each machine, and the flake gains four
     transitive inputs including a second nixpkgs pin; in practice: a bump
     becomes a 20–40 minute compile on the Mac and on the laptop.
- Resolution: **option 1** — freshen the nixpkgs pin. Rejected: option 2 accepts
  a prebuilt vendor binary and makes the agent's Linux integration this
  repository's maintenance burden, for freshness this change does not require;
  option 3 buys the same freshness as option 2 at the price of a source compile
  per bump on each machine, with no cache to fall back on.

### D2 — Scope of the freshening

- Status: carried — the design step decides it in `design.md`.
- Blocks: how the pin is expressed, and whether the freshening moves any package
  other than the agent.
- Context: this configuration follows the flake input `nixpkgs-unstable`, and the
  laptop's **entire system** is built from it (`nixosConfigurations.thiniel` is
  `nixpkgs-unstable.lib.nixosSystem`), while the Mac takes `pkgs-unstable` from
  it. That branch's head is already pinned and five days stale, and
  `nixos-unstable` is currently ahead of it. Whichever shape is chosen must end
  at a revision carrying 18.10 or newer — today only nixpkgs master qualifies.
- Options:
  1. **A dedicated pin for the agent** — meaning: a second nixpkgs input used
     only by the agent; gain: nothing else on either device moves, so the blast
     radius is the agent; cost: a third nixpkgs reference in the tree and the
     agent's runtime closure (glibc, bun, libraries) drawn from a different
     revision than the rest of the system; in practice: refreshing the agent's
     pin cannot change any other package on either device.
  2. **Rebase the shared unstable input** — meaning: point `nixpkgs-unstable` at
     the branch that actually advances, and refresh it; gain: one pin, no
     duplicate closure, and the followed branch is the one that moves; cost: the
     whole unstable-track system moves with the agent's freshening, pulling
     unrelated package changes into this change, and both devices take a full
     activation; in practice: taking a newer agent also moves every other
     unstable package on the laptop (whose whole OS is that input) and on the
     Mac.
- Disposition: carried — owner: the design step; deciding artifact: `design.md`,
  which can measure the rebuild and closure cost of each shape.

### D3 — What the Mac gets besides the executable

- Status: answered 2026-10-13 (user).
- Blocks: whether the Mac's agent carries this repository's servers and
  guardrails, or is a bare binary.
- Context: the laptop's agent has two shared servers declared and a
  pre-execution guard installed; the Mac currently declares no agent at all. The
  Mac holds the age private key that decrypts every secret in this repository.
- Options:
  1. **Full parity with the laptop** — meaning: the Mac gets the agent, the same
     two servers, the same secret-access guard, and the same "agent installed" assertion;
     gain: one behaviour on both devices, and the decryption prohibition applies
     wherever the agent runs; cost: more wiring, and the servers' key reads
     depend on the Mac's encrypted secret file actually holding those keys (the
     names are declared for the Mac; whether values exist is inside the
     encrypted file, which must not be read); in practice: a session on the Mac
     that tries `sops -d hosts/J6G6Y9JK7L/secrets.yaml` is refused exactly as on
     the laptop.
  2. **Install the agent only** — meaning: the binary lands, nothing else; gain:
     the smallest possible change; cost: the repository's decryption prohibition
     stops applying on the machine holding the age private key, so a careless or
     prompt-injected session there could read secret material; in practice: the
     same `sops -d` attempt on the Mac is allowed because no guard is installed.
  3. **Agent plus guard, without the shared servers** — meaning: the prohibition
     is installed, the two servers are not; gain: no dependency on the Mac's
     API-key secrets; cost: the devices behave differently for anyone used to
     either, and documentation lookup or web search fails on the Mac; in
     practice: `sops -d` is refused on the Mac while a documentation lookup that
     works on the laptop fails there.
- Resolution: **option 1** — full parity. Rejected: option 2 leaves the machine
  holding the age private key without the prohibition the repository relies on;
  option 3 buys a small dependency saving at the price of the two devices
  behaving differently, which the use case's "reproduce the environment on the
  selected device" goal argues against.

### D4 — An agent already installed outside this configuration on the Mac

- Status: carried — the operator confirms what is on the Mac, the design step
  decides the handling in `design.md`.
- Blocks: whether the configured agent becomes the only one, and therefore
  whether the version the configuration asserts is the version the operator
  actually runs.
- Context: this repository installs nothing for the agent on the Mac; upstream's
  installer places its binary in `~/.local/bin`, and this session cannot reach
  the Mac to inspect it. Two installations can coexist with path ordering
  deciding which one runs; the secret-access guard in the agent's user directory
  would be written by the configuration's activation either way.
- Options:
  1. **Remove the out-of-band installation** — meaning: the configured agent is
     the only one; gain: one agent, one version, unambiguous guard and servers;
     cost: touching state outside the configuration on that machine, needing the
     operator's confirmation of what is there first; in practice: `omp` resolves
     to the configured version on every shell.
  2. **Leave it in place** — meaning: the configuration adds its agent next to
     the existing one; gain: nothing outside the configuration is touched; cost:
     which agent runs depends on path ordering, so the asserted version floor may
     not be the version the operator actually runs; in practice: a shell where
     `~/.local/bin` precedes the profile path runs the hand-installed agent.
- Disposition: carried — owner: the operator (confirming the Mac's state) and the
  design step; deciding artifact: `design.md`.
