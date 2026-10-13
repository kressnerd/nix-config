# Proposal: managed-file-displacement

## Release note

Applying a device's configuration completes even when a program on the device has
rewritten a file the configuration manages: the rewritten file is moved aside and
kept instead of aborting the activation.

## Use-Case Context

- Use-case ID: `reproduce-working-environment` — the permanent contract whose flow
  applies the device's configuration and preserves already available working data
  unless a particular replacement is explicitly authorized.
- Ideation topic: none. This change has no ideation change seed; its source is the
  live observation below on 2026-10-13.
- Seed path: none.
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the operator is
  the one who applies the configuration to their own device and notices a failed
  activation. `family--application-user` is not affected: no hosted application,
  shared resource, or access path changes.

## Problem / Opportunity

A file the configuration manages can be rewritten by the program it configures.
Home Manager then refuses to replace it — `Existing file '…' would be clobbered` —
and the whole activation aborts, so the device's configuration cannot be applied
until the file is moved aside by hand.

Observed on `thiniel` on 2026-10-13, twice, in one session:

- the browser rewrote `~/.config/mozilla/firefox/profiles.ini` (its own profile
  registry) after the profile was relocated, and the next switch failed with that
  error until the file was renamed out of the way;
- after the browser was started again, it rewrote both
  `user/search.json.mozlz4` and `no-tracking/search.json.mozlz4` from its runtime
  search state, which would have failed the next activation the same way.

Operator impact: the device's configuration silently becomes un-appliable after a
program rewrites a managed file; the operator's only signal is a failed switch,
and the recovery is a manual move they have to reconstruct each time. The files
themselves are never at risk — the failure is loud and the old file stays — but
"apply the configuration" stops being reliable.

## Proposed Solution

Observable outcomes of this change:

- Applying a device's configuration completes even when a program on the device
  rewrote a file the configuration manages. No manual step is required between
  the program's write and the successful activation.
- The rewritten file is preserved every time: each rewrite is moved next to the
  rendered file under a numbered name (`<name>.1`, `<name>.2`, …) and nothing is
  deleted, so every version a program wrote stays available — including across
  repeated rewrites of the same path.
- The behaviour holds for every device in this repository that runs Home Manager:
  the four NixOS hosts through their shared module and the work MacBook through
  its own host module.
- Nothing else changes: the same files are rendered, an evaluation still reports
  no diagnostic to triage, and no host's services, secrets, or network behaviour
  are touched.

## Capability Routing

`givn spec route --change managed-file-displacement` reports no signal: run
against the scaffolded change it prints `recommendation: no signal — the top
candidates tie at 15.00` with no ranked list. (The same command, run in the same
session before the spec delta existed, recommended `EXTEND
quiet-configuration-evaluation` at 13.00; the routing index reads the change's own
delta, so that figure is historical.) The decision below is made from the two
contracts, not from the score.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| `managed-file-displacement` | EXTEND `quiet-configuration-evaluation` (score 13.00, confidence: signal) | NEW in reproduce-working-environment | The promise — the owner applies the device's configuration and it completes, with the program's file preserved — refines that use case's own rule that applying the configuration preserves already available working data unless a replacement is authorized. `quiet-configuration-evaluation` lives in the publication contract and promises that an *evaluation* reports nothing to triage; it does not own the device's activation and its refusal to discard a file the device's programs wrote. No existing capability in either contract owns this. |

> **Post-archive correction (2026-10-13).** The archived Decision cell read
> ``NEW in `reproduce-working-environment` `` with backticks around the use-case
> id. `givn archive` takes the id from that cell verbatim, so the merged
> capability landed in a directory literally named
> `` `reproduce-working-environment ``; it was moved to
> `givn/specs/reproduce-working-environment/managed-file-displacement.feature`
> and the stray directory removed. The backticks are gone so the cell reads the
> way the tooling parses it.

## Out of Scope

- Changing what the browser writes, or which files it rewrites. The browser's own
  profile registry and search state are its business.
- The browser profile relocation itself (the archived change
  `quiet-configuration-evaluation`) and its one-time data move.
- Files the operator hand-edits that the configuration does not manage: they are
  not touched by this change and are not displaced.
- The choice of which files Home Manager manages; this change only decides what
  happens when one of them has been rewritten.
- Any per-host difference in the behaviour: the setting is the same value
  everywhere Home Manager runs.

## Open Questions

### D1 — Which displacement mechanism moves a rewritten file?

- Status: answered 2026-10-13 (operator).
- Blocks: whether the device's configuration stays appliable after *repeated*
  rewrites of the same path, and what the operator finds beside the file.
- Context: Home Manager offers three answers to a conflicting managed file: a
  backup extension (move it to `<file>.<suffix>`), a backup command (run any
  command on it), or nothing (abort). The observed device rewrites the same paths
  repeatedly — the browser rewrites its profile registry and search state — so the
  mechanism has to survive a second conflict on the same path. Verified in Home
  Manager's source (2026-10-13): with the extension and `overwriteBackup` unset, a
  second conflict aborts (`Existing file '<file>.<suffix>' would be clobbered by
  backing up '<file>'`); with `overwriteBackup = true` it deletes the previous
  displaced copy before moving the new one; a backup command is run with the
  conflicting path as its final argument and its behaviour is entirely ours.
- Options:
  1. **Backup command that renames to the first free number** — the configuration
     ships a small script: `mv <file> <file>.1`, or `.2`, or the next free number.
     In practice: after two browser rewrites, `search.json.mozlz4.1` and `.2` both
     hold browser-written content, the rendered file is linked, and both switches
     completed unattended.
     Gain: works on every rewrite, and nothing any program wrote is destroyed.
     Cost: a few lines of shell in the configuration, and the displaced copies
     accumulate until the operator deletes them.
  2. **Backup extension plus `overwriteBackup`** — Home Manager's own mechanism,
     no custom code.
     In practice: the second rewrite leaves exactly one `.hm-backup` file (the
     newest); the earlier one is deleted.
     Gain: nothing custom to maintain.
     Cost: the earlier displaced copy is lost — for a profile registry that is a
     browser-written file, not regenerable state.
  3. **Backup extension alone** — the mechanism proposed before the review.
     In practice: the first rewrite is displaced, the second aborts the switch, so
     the release note would be false.
     Gain: least configuration.
     Cost: the original failure returns on the second rewrite of any path.
- Disposition: **answered** — option 1, selected by the operator (2026-10-13).
  Rejected: option 2, because it destroys the earlier copy of a file the program
  wrote; option 3, because the device's browser rewrites the same paths
  repeatedly and the promise would not hold.

### D2 — Do the automation first or the config first?

- Status: answered by evidence — the configuration, with no manual step.
- Question: should the operator keep moving the file aside by hand, or should the
  configuration move it?
- Options:
  1. **Configuration moves it** — Home Manager displaces the file and activates.
     In practice: `nixos-rebuild switch` after a browser rewrite just completes.
     Gain: activation stops depending on a manual recovery step.
     Cost: a rewritten file is moved without the switch telling the operator
     (the displaced copy stays visible in the directory).
  2. **Keep failing loudly** — the operator moves the file when a switch reports
     the clobber.
     Gain: no change; the operator is told each time.
     Cost: the device's configuration is un-appliable until the manual step.
- Disposition: **answered** — option 1, selected by the operator (2026-10-13).
  Rejected: option 2, because the failure repeats whenever a program rewrites a
  managed file and its recovery is a manual move. The displaced copy is kept, so
  nothing the program wrote is lost.
