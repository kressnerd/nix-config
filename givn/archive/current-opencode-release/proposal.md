# Proposal: current-opencode-release

## Release note

Both personal devices run a current OpenCode coding agent from a freshly
refreshed package, and each device refuses an OpenCode older than 2.0.28.

## Use-Case Context

- Use-case ID: `reproduce-working-environment` — the permanent contract for a
  device reproducing the owner's usable working environment (intended tools and
  settings, required working state, permitted identity access).
- Ideation topic: none. This change has no ideation change seed; the use case's
  originating topic was `infrastructure-growth`, which is not re-opened here.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator
  runs OpenCode on both personal devices and is the one who judges whether the
  carried one is usable and current. `family--application-user` is not affected:
  an agent's version is not part of an application user's task.

Vocabulary: the use case's "coding agent" now covers the two agents the devices
carry — Oh My Pi (omp) and OpenCode. The version-currency rule applies to each.
The guardrails half of the rule ("a device that carries the coding agent also
carries its guardrails") is read as applying to the agent that carries the
user-level secret-access guard (omp); OpenCode's guardrails are explicitly out
of scope here (see Out of Scope). The durable glossary's "Coding agent" entry,
which today names only omp, is corrected to name both.

## Problem / Opportunity

Measured on 2026-10-13:

- The laptop `thiniel` runs OpenCode `2.0.22`, the release of 2026-10-02.
  Upstream's newest release is `2.0.28` (2026-10-13 08:16) — six releases in the
  eleven days since the installed build.
- Both devices carry it from one place: each home profile imports the same
  feature module, and the package is the repository's own prebuilt-binary
  package. So the Mac `J6G6Y9JK7L` carries the same `2.0.22` (declared; the Mac
  cannot be observed from here).
- The package does not come from a package set that can be refreshed: nixpkgs
  carries OpenCode `1.19.0` only, and the 2.x line is distributed as prebuilt
  per-platform binaries. Refreshing any package-set pin therefore changes
  OpenCode by nothing; the version is written into the repository's own package
  and updated by hand.
- Nothing asserts currency: both devices' configurations require only
  "OpenCode 2.x (`>= 2`)", so the eleven-day drift is invisible to every check.

Operator impact: the everyday coding agent on both devices is six releases
behind, and no check would notice if it fell further.

## Proposed Solution

Observable device state:

1. Each device installs OpenCode from the repository's package pinned at the
   newest upstream release; taking a newer one is the operator refreshing that
   pin and applying the configuration. Today that yields 2.0.28 on both devices.
2. Each device reports an OpenCode version of at least 2.0.28 — never the 2.0.22
   line the devices run today.
3. Both devices carry the same OpenCode: the Mac's OpenCode is the same package,
   at the same version, as the laptop's.
4. Each device's configuration asserts the floor at evaluation time, so a stale
   pin fails the configuration rather than drifting silently.
5. OpenCode still starts: on a device that carries it, launching it reports a
   version at or above the floor of point 2.

Verification binding (each point bound to exactly one native target; see
`docs/GIVN-VERIFICATION.md`):

| Point | Native target |
|---|---|
| 1, 3 as configuration facts | `@host:thiniel`, `@host:J6G6Y9JK7L` |
| 2, 4 as declared floor assertions | `@host:thiniel`, `@host:J6G6Y9JK7L` |
| 5 as behaviour of a running system | `@check:integration-agent-tooling` — a booted Linux VM is the only target in this repository that observes real behaviour; this repository has no deploy-test layer (`tests/deploy/` does not exist), so the Mac's own launch is confirmed on the machine during implementation, not by a spec binding |

Points 1 and 3 as *package content* are proven by the same host assertions — the
floor assertion reads the declared package's version — so no separate unit case
is added; the existing `@check:unit-helpers` OpenCode module tests stay green
unchanged.

## Capability Routing

| Proposed capability | Route's recommendation | Decision | Rationale (if deviated from route) |
|---|---|---|---|
| `current-agent-tooling` | EXTEND `current-agent-tooling` (score 12.60, confidence: signal) | `EXTEND current-agent-tooling` | The capability's promise is "a device carries the owner's coding agent at or above the accepted version floor". OpenCode is a second coding agent the same devices carry, and the floor discipline is identical, so it extends that promise rather than opening a new one. The guardrails half of the capability stays scoped to the guarded agent (omp) — see Out of Scope. |

## Out of Scope

- **Automatic or scheduled updating.** Currency stays a floor rather than a
  schedule: refreshing the pin is the operator's deliberate action, per the use
  case's existing rule. No timer, Renovate rule, or CI bump is introduced.
- **Reaching the newest release without an operator action.** A refresh is a
  version-and-checksum edit, not a one-command lock update (D1).
- **OpenCode's guardrails and configuration parity.** Whether the Mac's OpenCode
  carries a secret-access guard equivalent to omp's user-level hook, and whether
  it carries the same servers, is a named boundary of this change and not part
  of it.
- **OpenCode 1.x from nixpkgs.** Excluded by the devices' existing 2.x
  requirement; nixpkgs carries `1.19.0` only.
- **Other hosts.** `cupix001`, `adlerkopf`, and `nixos-vm-minimal` apply the same
  package overlay but do not carry OpenCode in their home profiles.
- **What OpenCode is used for**: model configuration, provider settings, plugins,
  session content.
- **Other packages.** The refresh moves only the OpenCode pin; no shared package
  set is involved.

## Open Questions

### D1 — Where a current OpenCode comes from

- Status: answered 2026-10-13 (user).
- Blocks: how the pin is expressed and what a refresh costs; it determines the
  whole implementation.
- Context (measured 2026-10-13): installed `2.0.22`; upstream's newest release
  `2.0.28`; nixpkgs carries `1.19.0` only, so a package-set pin cannot serve the
  2.x line; the package is already the repository's own prebuilt-binary package
  (`overlays/opencode`), with a hardcoded version and two platform checksums.
- Options:
  1. **Keep the repository's own prebuilt package** — meaning: the package stays
     the one the repository owns, a downloaded upstream release binary per
     platform with the Linux integration already maintained; gain: a refresh
     reaches the newest release within minutes and compiles nothing, one package
     for both platforms; cost: the refresh is a manual checksum edit rather than
     a single lock update, and the repository keeps owning the packaging; in
     practice: to take 2.0.29 the operator edits the version, rebuilds once to
     read the two checksums from the build error, and rebuilds again.
  2. **Pin upstream's own Nix packaging as a flake input** — meaning: a new
     pinned input points at OpenCode's own Nix packaging (its dev tree carries
     2.0.28 today, measured) and the package comes from there; gain: no checksums
     to derive, no packaging owned here; cost: that packaging builds OpenCode
     from source (its own Node dependency set) and no binary cache is advertised,
     so every refresh compiles on each machine, and the flake gains an input with
     its own nixpkgs pin; in practice: refreshing runs a source build on the Mac
     and on the laptop instead of a download.
- Resolution: **option 1** — keep the repository's own prebuilt package. Rejected:
  option 2 buys a lock-file refresh at the price of a source build on each machine
  for every refresh, with no advertised cache to fall back on.

### D2 — An OpenCode already installed outside this configuration on the Mac

- Status: answered 2026-10-13 (operator) — no OpenCode exists on the Mac outside
  this configuration, so nothing is removed and the asserted floor describes the
  binary the operator runs. Recorded in `design.md` (`## Decisions`).
- Blocks: whether the configured OpenCode becomes the only one, and therefore
  whether the version the configuration asserts is the version the operator
  actually runs.
- Context: this repository installs OpenCode for the Mac only through the shared
  feature module; OpenCode is also commonly installed by hand (npm global,
  Homebrew), and this session cannot reach the Mac to inspect it. Two
  installations can coexist with path ordering deciding which one runs.
- Options:
  1. **Remove the out-of-band installation** — meaning: the configured OpenCode
     is the only one; gain: one OpenCode, one version, the asserted floor
     describes what runs; cost: touching state outside the configuration on that
     machine, needing the operator's confirmation of what is there first; in
     practice: `opencode` resolves to the configured version in every shell.
  2. **Leave it in place** — meaning: the configuration adds its OpenCode next to
     the existing one; gain: nothing outside the configuration is touched; cost:
     which OpenCode runs depends on path ordering, so the asserted floor may not
     be the version the operator actually runs; in practice: a shell where a
     hand-installed binary precedes the profile path runs the older OpenCode.
- Disposition: answered 2026-10-13 (operator) — no out-of-band OpenCode exists on
  the Mac; the configured package is the only one. Recorded in `design.md`
  (`## Decisions`).
