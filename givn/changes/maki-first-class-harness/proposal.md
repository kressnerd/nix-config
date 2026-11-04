# Proposal: {{CHANGE_ID}}

## Release note

> Required. One complete, user-facing sentence naming what this change does.
> Every revision this change records carries the release note as its message subject, with the scenario title in the message body.

<one complete, user-facing sentence>

## Use-Case Context

> Optional. When this change comes from ideation or an existing permanent
> contract, record the stable use-case ID, source topic, and confirmed Persona
> IDs. Do not copy Persona biographies into the proposal. An infrastructure
> change almost always records `none` with a reason.

- Use-case ID: <usecase-id or none>
- Ideation topic: <topic-id or none>
- Seed path: <givn/ideation/<topic-id>/changes/<uc-id>.md or none>
- Confirmed Personas: <persona-id>, or none — <reason + operator confirmation>

## Problem / Opportunity

> Describe the problem or opportunity in domain terms: which host, service,
> module, secret, firewall rule, boot step, or persistence behaviour is
> broken, missing, or could be better? Explain the operator impact.

## Proposed Solution

> What should the host or system do, in observable-state terms?
> Write from the operator's perspective. Do NOT mention implementation details
> (module paths, option names, helper functions, derivation internals).

## Capability Routing

> Run `givn spec route` and record its recommendation and your decision
> for every capability this change touches. When route reports no signal,
> omit the recommendation column and record the decision with its rationale
> directly. Editing this table IS the declaration — `givn check review`
> compares what you write here against the delta you actually author, not
> against a re-run of `route`.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| | | `EXTEND <capability>` / `NEW in <usecase-id>` | |

## Out of Scope

> What is explicitly not changing? Clarify boundaries.

## Open Questions

> One entry per question, with a stable ID, the full question with its option
> treatment (context, per-option meaning, gain, cost, and a concrete example),
> and a Disposition: answered (with its source), carried (with an owner and
> the artifact that will decide it), or out of scope (with a reason).

### D1 — <short title>

- Question: <full standalone question>
- Options:
  1. **<option name>** — <what it means>; gain: <what improves>; cost: <what
     gets harder or is given up>; in practice: <concrete example>
- Disposition: <answered | carried | out of scope> — <source, owner and
  deciding artifact, or reason>
