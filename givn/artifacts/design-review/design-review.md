# Design Review: {{CHANGE_ID}}

## Grilling log

The table is the scannable index; the full record for each question is written
in a per-question block below it. The `Question` cell holds the short title, not
the whole record.

| # | Branch | Question | Outcome |
|---|---|---|---|
| 1 | | | |

### Q1 — <short title in domain language>

- Status: open | closed <date> (<decider>)
- Blocks: <the decision or work item this question blocks, one line>
- Context: <why the question exists — the problem, the constraints, and what
  changes depending on the answer, 2-5 sentences>
- Question: <full standalone question>
- Recommended: <the recommended answer, with its reason>
- Options:
  1. **<option name>** — <what it means>
     In practice: <concrete example of what the host config does or what the
     operator observes>
     Gain: <what improves>
     Cost: <what gets harder or is given up>
- Resolution: **<chosen option>** because <reason>. Rejected: <option> because
  <reason>; <option> because <reason>.

## Resolved by codebase exploration

Items answered without user input by exploring the existing codebase.

| Branch | Finding |
|---|---|
| | |

## Open questions

Questions that could not be resolved and were flagged explicitly.

| # | Question |
|---|---|
| | |

## Verification binding

Read `docs/GIVN-VERIFICATION.md` for the binding-tag semantics and the
targeted-run commands. Every scenario in the change's `specs/**/*.feature` has
exactly one binding tag; every binding resolves; `verify.e2e_command` is not
identical to `verify.command`.

| Scenario title | Binding tag | Resolves? | Targeted command fires the assertion? |
|---|---|---|---|
| | | | |

- [ ] Every scenario carries exactly one binding tag.
- [ ] Every `@check:`/`@host:` name resolves in the flake; every `@deploy:`
      name has a matching `tests/deploy/test_<name>.py`.
- [ ] Every `@e2e` scenario binds to `@check:integration-*`, `@host:`, or
      `@deploy:`.
- [ ] `verify.e2e_command` differs from `verify.command`.
- [ ] Every scenario's targeted command can exit non-zero before the fix.

## Deployment & rollback

> Complete when the change touches `boot.loader`, `networking`,
> `fileSystems`/disko, `environment.persistence`/impermanence, kernel, or
> secrets. Otherwise record `N/A`.

| Area touched | Apply command | On-host verification | Rollback |
|---|---|---|---|
| | | | |

## Risk

> The single most likely way this plan fails (boot lockout, data loss, loss of
> connectivity, secret misconfiguration) with its mitigation and rollback.

| Failure mode | Mitigation | Rollback |
|---|---|---|
| | | |

## Use-Case And Persona Context

Persona is optional: record the confirmed Personas and their relevance, or
`none` with the reason. A host-configuration change normally records `none`.

| Check | Finding | User disposition |
|---|---|---|
| Use-case contract and capability ownership | | |
| Typed Includes / Extends relationships | | |
| Confirmed Persona coverage | | |
| Actor and Persona distinction | | |

### Persona disposition

One row per confirmed persona, recording the relevance and the evidence; when
no persona is confirmed, record `none` and the reason.

| Persona | Relevance | Evidence |
|---|---|---|
| | | |

## Architecture documentation (arc42) check

N/A if the arc42 addon is not enabled (`addons.arc42` in `givn/config.yaml`).
Otherwise, fill in **all 12 rows** — this is an independent audit, not a
transcription of `arc42.md`'s own table. Assess each chapter against
proposal.md/design.md yourself before reading what `arc42.md` claims, then
record both:

| # | Chapter | Reviewer's own assessment (Yes/No) | arc42.md's claim (Yes/No) | Match? | Content matches design.md? |
|---|---|---|---|---|---|
| 1 | 01 introduction-and-goals | | | | |
| 2 | 02 architecture-constraints | | | | |
| 3 | 03 context-and-scope | | | | |
| 4 | 04 solution-strategy | | | | |
| 5 | 05 building-block-view | | | | |
| 6 | 06 runtime-view | | | | |
| 7 | 07 deployment-view | | | | |
| 8 | 08 crosscutting-concepts | | | | |
| 9 | 09 architecture-decisions | | | | |
| 10 | 10 quality-requirements | | | | |
| 11 | 11 risks-and-technical-debt | | | | |
| 12 | 12 glossary | | | | |

- [ ] All 12 rows assessed independently against proposal.md/design.md before
      reading arc42.md's own claims.
- [ ] No row is "Match? = No" with the reviewer saying "Yes" and arc42.md
      saying "No" or omitting the row — any such row is a finding, not a note.
- [ ] Every qualified ADR candidate in design.md has a corresponding MADR entry
      in chapter 09; non-qualifying decisions name exactly one canonical target.
- [ ] Every MADR "Bad, because..." consequence has a counterpart entry in
      chapter 11 (risks-and-technical-debt).
- [ ] Every ADR candidate records the structured qualification verdict and its
      route-specific target; `Must be shared` is supporting evidence only.
- [ ] No chapter claimed as "updated" is still scaffolded placeholder text.

## Changes made during hardening

Edits applied to existing artifacts as a result of grilling.

| Artifact | Change summary |
|---|---|
| | |

## Sign-off

- [ ] Every branch of the design tree has been walked.
- [ ] Every proposal question ID (`D<n>`) resolves in the design's `## Decisions` ledger or is carried with a named owner.
- [ ] All questions are resolved.
- [ ] `design.md` reflects any decisions reached during grilling.
- [ ] `specs/**/*.feature` updated if any missing scenarios were identified.
- [ ] Every scenario has a resolvable binding tag; `verify.e2e_command` differs from `verify.command`.
- [ ] `givn lint --change {{CHANGE_ID}}` exits 0 or 2 (no parse errors).
- [ ] Architecture documentation (arc42) check completed above (or marked N/A
      because the addon is not enabled) — never left blank.

**DESIGN-REVIEW: PASS** <!-- change to FAIL if any question remains unresolved -->
