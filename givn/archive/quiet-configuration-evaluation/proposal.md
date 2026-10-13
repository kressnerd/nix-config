# Proposal: quiet-configuration-evaluation

## Release note

Checking or building this configuration prints no evaluation warnings: the
personal laptop's browser profile moves under its XDG config directory with its
data intact, the booted-device checks load Home Manager and their packages from
the same release, and the flake stops declaring the fleet output a checker
cannot interpret.

## Use-Case Context

- Use-case ID: `publish-infrastructure-configuration` — the permanent contract
  whose flow already requires that a checkout of this repository evaluates and
  passes its checks.
- Ideation topic: none. This change has no ideation change seed; its source is
  the operator's report of the warnings below on 2026-10-13.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator
  runs the checks and host builds, keeps the configuration current, and owns the
  browsing data the relocation touches. `family--application-user` is not
  affected: no hosted application, shared resource, or access path changes here.

## Problem / Opportunity

The operator's flake check prints five warning blocks from four causes, every
time, and a build of the personal laptop prints two of them. The causes:

- The personal laptop's home profile relies on two settings whose default the
  current release superseded, because the profile's state version predates that
  release: the format of the window-manager configuration, and the location of
  the browser profile. The release keeps the older value and prints a migration
  warning for each, naming both possible values.
- Each of the two booted-device checks (private-repository identity, coding-agent
  tooling) builds a "test" home profile from Home Manager of one release and a
  package set of another, so each prints the same version-mismatch warning.
- The checker reports one flake output it cannot interpret — the fleet hive
  (`colmenaHive`), which is declared with zero nodes.

Operator impact: the diagnostics an evaluation prints are the only signal that a
host build is drifting from its release, and today they carry four permanent
entries that must be recognised and skipped on every run. One of them also means
the operator's browser profile location is decided by an inherited default
rather than by him: the warning is the release asking for that decision.

## Proposed Solution

Observable outcomes of this change:

- An evaluation of this repository — a flake check, or a build of any host —
  prints no migration warning, no version-mismatch warning, and no
  unrecognised-output warning. Today's four causes are all cleared, and a
  recurrence fails a target rather than scrolling past.
- The personal laptop keeps its window-manager configuration in the format it
  uses today, stated explicitly rather than inherited, so it renders the same
  kind of compositor configuration file as before this change.
- The personal laptop's browser profile, bookmarks, history and saved logins
  live under `~/.config/mozilla/firefox` (the release's current default). The
  configuration's persistent set follows the profile, so the browsing state
  still survives the root-filesystem reset. The relocation itself is a
  documented operator step that copies the profile to the new location, has the
  browser read it, and only then removes the old `~/.mozilla/firefox` — a failed
  move leaves the existing data in place.
- Each booted-device check loads Home Manager and a package set from the same
  release, and it still proves the same device state it proves today (the
  rendered private-repository identity surface; the two coding agents starting,
  their version floors, and the installed secret-access guard).
- The flake declares no output the checker cannot interpret: the zero-node
  fleet hive is withdrawn until the first server is provisioned for fleet
  deployment. The fleet deployment tool (Colmena) and the operator's fleet
  aliases stay installed; the hive is registered again together with the server
  it would deploy.
- Nothing else changes. No service, firewall rule, secret, boot behaviour, or
  host network behaviour is touched, and the work MacBook's browser path and
  state version stay as they are.

## Capability Routing

`givn spec route --change quiet-configuration-evaluation` reports signal and
recommends `EXTEND current-agent-tooling` (score 12.60, use case
`reproduce-working-environment`). The recommendation is lexical noise: it rests
on the capability text containing the word "none" plus generic goal/rules word
overlap, and `current-agent-tooling` owns a device's coding-agent version floor
and its guardrails — not the diagnostics an evaluation prints. The decision
below therefore deviates.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| `quiet-configuration-evaluation` | EXTEND `current-agent-tooling` (score 12.60, confidence: signal) | NEW in publish-infrastructure-configuration | No existing capability owns the diagnostics a configuration evaluation prints. `operational-data-separation` owns disclosure of operational values, `permitted-identity-selection` owns identity selection, `current-agent-tooling` owns an agent's version floor and guardrails. The publication contract's flow already requires a checkout that evaluates and passes its checks, and its trigger covers recording a change to the configuration, so a capability promising that an evaluation reports nothing to triage — every superseded setting stated explicitly at a chosen value, and no output the checker cannot interpret — belongs there. |

## Out of Scope

- Adopting the Lua format for the window-manager configuration, the release's
  other value for the same superseded setting. It rewrites the whole compositor
  configuration and the four assertion files that read its current shape, and it
  cannot be verified without a real compositor session — see D2. This change
  states today's format explicitly instead.
- Changing the state version of any system or home profile. It is fixed at
  install time and never changed; it is not a way to clear these warnings.
- Fleet deployment itself. No server is provisioned, registered, or migrated;
  the piece of work that adds the first server registers the hive output again,
  and the deployment plans are updated to say so.
- The work MacBook's browser path: its default did not change and no warning is
  reported for it. Its home profile and paths stay untouched.
- The checker's informational line that it omitted incompatible systems. The
  check did run for the current system, and the other architectures are covered
  by their hosts' own evaluations. Not a defect, not suppressed.
- Restoring browsing data by any other means than the documented relocation
  step. If the operator's copy-and-verify step fails, the repository cannot
  reconstruct bookmarks, history, or saved logins.
- Every other diagnostic the tooling can print. This change clears today's four
  causes; a diagnostic a future release adds is a new decision, not a silent
  silencing.

## Open Questions

### D1 — Where does the personal laptop's browser profile live?

- Status: answered 2026-10-13 (operator).
- Blocks: the spec's browser-profile scenario and whether this change carries a
  one-time relocation of live browsing data.
- Context: the browser module's default profile location changed in the current
  Home Manager release; thiniel's home profile predates it, so the release keeps
  the older location and prints the transition warning until the location is
  stated. The live data sits at `~/.mozilla/firefox` today, and the home profile
  persists `.mozilla` so that state survives the root reset.
- Options:
  1. **Keep `~/.mozilla/firefox`** — the configuration states the current
     location explicitly.
     In practice: the profile, bookmarks and saved logins stay where they are
     and the persistent set keeps covering `.mozilla`.
     Gain: no data move, no risk to live browsing data.
     Cost: the home directory keeps the superseded layout, and a later move is
     its own change with the same data step.
  2. **Move to `~/.config/mozilla/firefox`** — the configuration adopts the
     release's current default.
     In practice: the profile is copied to the new location, the browser reads
     it there, the persistent set moves with it, and the old directory is
     removed once the operator confirms the profile is intact.
     Gain: the home directory carries no superseded dot-directory, and the
     device matches its release's default.
     Cost: a one-time operator data move on the daily-driver laptop; a botched
     move loses bookmarks, history and saved logins.
- Disposition: **answered** — option 2, selected by the operator in the change
  request (2026-10-13: "Move to ~/.config/mozilla/firefox"). Rejected: option 1
  — it clears the warning without the relocation, but leaves the profile on the
  superseded layout and defers the same data step to a later change; the
  operator chose to take the current default now and authorized the one-time
  move. The relocation therefore becomes part of this change's work, not a
  follow-up.

### D2 — Which window-manager configuration format?

- Status: answered by evidence — option 1; option 2 is out of scope.
- Question: should the personal laptop adopt the Lua compositor configuration
  format (the release's current value for this setting) or state today's
  conf-based format explicitly?
- Options:
  1. **State the conf-based format explicitly** — the compositor keeps reading
     the configuration file it reads today; the warning clears.
     In practice: the rendered compositor configuration stays in the format in
     use now; nothing about the desktop session changes.
     Gain: the diagnostic clears with no desktop risk; the change stays inside
     its subject.
     Cost: the configuration stays on the superseded format until the operator
     chooses otherwise.
  2. **Adopt the Lua format** — the compositor reads a Lua configuration file
     instead.
     In practice: every setting in the window-manager configuration is rewritten
     into the release's Lua call form (bindings, window rules, window commands,
     input settings), the four assertion files that read the current settings
     shape are rewritten with it, and the session is verified on the machine.
     Gain: the device follows the release's default for the compositor.
     Cost: a desktop configuration rewrite with real risk of a broken session on
     the daily driver, and verification that needs a live compositor — a change
     of its own, not part of clearing a warning.
- Disposition: **out of scope** — option 2. The warning clears without it
  (option 1), and it requires rewriting the compositor configuration and its
  invariant assertions plus a live-session check. The operator may open a
  separate change for it; nothing in this change forecloses it.

### D3 — How do the booted-device checks load a matching release?

- Status: carried — `design.md` decides (owner: this change's design step).
- Question: how should each booted-device check come to load Home Manager and a
  package set from the same release, so the mismatch warning cannot reappear?
- Options:
  1. **Take the guest's package set from the same pin the loaded Home Manager
     follows** — the check mirrors the device it reproduces (unstable Home
     Manager with unstable packages, as the laptop and the Mac run them).
     Gain: the fixture reproduces the device's actual pairing.
     Cost: those two checks build their guest from that pin instead of the
     release package set the other checks use.
  2. **Let the loaded Home Manager supply its own package set** — the guest
     system stays on the release set while the home profile is built from the
     set its Home Manager follows.
     Gain: cheapest change, pairing matches while the guest stays on the release
     set.
     Cost: the fixture no longer exercises the global-package-set mode the hosts
     use.
  3. **Turn the release check off in the two fixtures** — the mismatch is
     declared deliberate instead of removed.
     Gain: one line per fixture.
     Cost: a real guard is disabled inside the fixtures, so an *accidental*
     mismatch would no longer be reported.
- Disposition: **carried** — `design.md` picks between options 1 and 2 and
  records the trade-off. Rejected: option 3, because it silences the guard
  instead of fixing the pairing it reports.

### D4 — What happens to the zero-node fleet hive?

- Status: answered 2026-10-13 by evidence and this proposal's decision.
- Question: how should the flake stop declaring an output the checker cannot
  interpret while the fleet hive has no nodes?
- Context: `nix flake check` prints `unknown flake output` for every top-level
  output it does not recognise — verified against a minimal flake that declares
  the same name (2026-10-13); there is no per-output suppression. The hive has
  zero nodes, so nothing is deployed through it today; the Colmena CLI and the
  operator's fleet aliases are separate packages and stay.
- Options:
  1. **Withdraw the hive until the first server is provisioned** — output and
     its then-unused flake input go; the server work registers both again.
     In practice: a `colmena apply` against this flake reports a missing hive,
     where today it finds a hive with no node to apply to; the deployment plans
     carry the registration step.
     Gain: no unknown output, no dead declaration, and the fleet path fails
     loudly rather than appearing ready.
     Cost: the fleet aliases cannot run against this flake until a server is
     provisioned.
  2. **Keep the hive under an output the checker does not schema-check**
     — the hive moves to a location the checker accepts.
     In practice: the warning clears, the empty hive stays declared, and the
     flake carries a placement whose reason only a comment explains.
     Gain: no change to the fleet registration story.
     Cost: an empty structure kept alive at a non-obvious location, for a
     deployment that cannot happen yet.
  3. **Keep the hive at the top level and accept the warning** — the reported
     diagnostic stays.
     Gain: nothing to change.
     Cost: the change's purpose is defeated for this warning.
- Disposition: **answered** — option 1. Rejected: option 3 leaves the reported
  warning in place; option 2 trades one warning for a subtlety that buys nothing
  while there is no node to deploy.
