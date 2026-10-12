# Proposal: private-data-remediation

## Release note

The repository can be published publicly without disclosing operational network
or hosting-provider data, and every host still builds and deploys from the
values it holds outside the repository.

## Use-Case Context

- Use-case ID: `publish-infrastructure-configuration` (new — introduced by this
  change; no permanent use case exists yet, `givn/specs/` is absent)
- Ideation topic: none — this change does not come from the
  infrastructure-growth topic. Its source is the remediation plan at
  `docs/plans/private-data-remediation-plan.md`.
- Seed path: none
- Confirmed Personas: `owner--operator` (confirmed 2026-10-11) — the affected
  surface is the operator's own repository content and the deployability of the
  operator's hosts, and the operator is the only actor who publishes the
  repository and judges whether the hosts still build.
  `family--application-user` is not affected: no hosted application, shared
  resource, or access path changes here.

## Problem / Opportunity

The configuration repository is intended to be public, but it currently
discloses operational data that identifies and maps the operator's
infrastructure, and the arrangement meant to keep that data out of the
repository does not work.

Observable today:

- The host network defaults, and several planning and deployment documents,
  record the real home-LAN address and gateway, the WireGuard range, the
  hosting provider's resolver addresses, and the non-standard SSH port the edge
  server listens on.
- The two per-host private-value files — meant to exist only on the operator's
  own machine — are present in the repository and would be published with the
  next revision; their real values are recorded in its history.
- The repository's history still records the edge server's public address,
  gateway and hardware address, the per-host private-value files, and a private
  notes file.
- No guard refuses a revision that would reintroduce any of this.

Operator impact: publishing the repository hands a reader a map of the home
LAN, the edge server and the hosting provider, together with the addresses and
the port to aim at. Removing a value now does not remove it from the
repository's history, so every value already recorded must be treated as
disclosed.

## Proposed Solution

Observable outcomes of this change:

- Every host keeps evaluating, building and deploying with its real network
  values. Those values reach a build from a private source the operator holds
  outside the public repository.
- The public repository's recorded content contains no operational network
  address, gateway, hardware address, provider resolver or non-standard port,
  no per-host private-value file, and no unencrypted secret file. The host
  network defaults are documentation-range placeholders.
- A checkout that holds no private values still evaluates and passes its
  checks, so the repository can be built and reviewed by anyone without the
  operator's private source.
- A guard refuses any revision that would record an operational value, a
  per-host private-value file, or an unencrypted secret file — both before a
  change leaves the operator's machine and on the repository's continuous
  integration.
- The published history no longer records the operational values or the
  per-host private-value files.

## Capability Routing

`givn spec route --change private-data-remediation` reports no signal: the
permanent corpus is empty (`givn/specs/` does not exist), so there is nothing to
match against. The recommendation column records that and the decision follows.

| Proposed capability | Route's recommendation | Decision | Rationale (if you deviated from route) |
|---|---|---|---|
| operational-data-separation | no signal — no command, token or lexical overlap, because the permanent corpus is empty | NEW in publish-infrastructure-configuration | No existing goal owns this. The six confirmed goals cover application availability, per-application reachability, application-state protection, hosted recovery, personal working-environment reproduction, and shared-information access — none owns repository content or publication. The new goal's single outcome — the published configuration discloses no operational data while the hosts remain deployable — is the only fitting owner. |

## Out of Scope

- Generating, rotating, copying or transferring any key material or secret. The
  one secret file involved is already encrypted and stays exactly as it is.
- Any change to network behaviour or topology: no address, route, firewall rule
  or tunnel on any host changes.
- The operational responses to the disclosure — assigning a new address from the
  hosting provider, rotating the provider token, regenerating host keys, moving
  the SSH port. These act on live providers and hosts, not on repository or
  configuration state, and the project's verification targets cannot prove them
  (see D2). The history rewrite is in scope; it is a task the operator executes.
- Everything owned by the infrastructure-growth topic: application
  availability, per-application reachability, application-state protection,
  hosted recovery, personal working-environment reproduction, and
  shared-information access.

## Open Questions

### D1 — Which permanent goal owns the separation of operational data from the published configuration?

- Question: Should this change introduce the new permanent goal "publish the
  infrastructure configuration" as the owner, with the single outcome "the
  published configuration discloses no operational data while the hosts remain
  deployable"?
- Context: The change needs a permanent owner for its capability. The permanent
  corpus is empty, and the six confirmed goals
  (`givn/ideation/infrastructure-growth/use-case-definitions.md`) do not own
  repository content or publication, so attaching the capability to one of them
  would stretch it.
- Options:
  1. **Adopt the new goal** — the operator publishes their configuration and the
     public repository discloses no operational data; boundary: it does not
     change host network behaviour and does not rotate credentials.
     In practice: a later change that adds a host must put that host's real
     values outside the repository and record documentation-range placeholders,
     because this goal owns it.
     Gain: an owner for publication behaviour that is not stretched onto an
     unrelated goal.
     Cost: a new permanent use case and its contract must be written and
     reviewed.
  2. **Revise the goal or boundary first** — change the actor, the outcome, or
     the boundary before it becomes the owner.
     In practice: if the goal should also own the private source and host
     deployability as separate outcomes, split it before writing the contract.
     Gain: avoids building the capability on a wrong goal.
     Cost: the specs wait until the goal is settled.
- Disposition: **answered** — option 1, adopted by the operator (2026-10-12).
  The new goal `publish-infrastructure-configuration` owns the capability
  `operational-data-separation`, with the outcome and boundary stated above.
  Rejected: revising the goal or boundary first — the six confirmed goals do
  not own repository content or publication, so no existing goal could take the
  capability without being stretched, and the stated outcome and boundary are
  the ones the operator wants.

### D2 — Which parts of the remediation does this change carry?

- Question: Does this change carry only the repository and configuration work,
  or also the destructive history rewrite and the live operational responses?
- Context: The remediation plan contains steps that act outside the repository:
  a history rewrite (approved by the operator, executed manually) and
  post-publication responses on live providers and hosts. This project verifies
  behaviour through a repository check or a host evaluation
  (`docs/GIVN-VERIFICATION.md`); neither can prove a history rewrite or a
  provider-side rotation.
- Options:
  1. **Repository and configuration only** — the private source that supplies
     values, the removal of operational values from recorded content, the
     documentation-range defaults, the guard, and the goal's contract. History
     rewrite and live responses are separate.
     In practice: the change is done when a checkout without private values
     evaluates, its checks pass, and the guard refuses a revision that records
     an operational value.
     Gain: everything in this change is provable by a check or a host
     evaluation.
     Cost: the history still records the values until a separate step runs.
  2. **Also carry the history rewrite** (option 1 plus the rewrite) — the
     operator executes the rewrite, and the change's task list ends with
     confirming the history is clean.
     In practice: the disclosure is closed within this change's record.
     Gain: one record closes the disclosure.
     Cost: a destructive manual step joins the change, and the check suite
     cannot prove it — its completion rests on the operator's confirmation.
  3. **Also carry the live responses** (option 2 plus the provider and host
     actions).
     In practice: tasks include assigning a new address, rotating the provider
     token, regenerating host keys, and moving the SSH port.
     Gain: one record for the whole remediation.
     Cost: unverifiable by this project's targets; mixes operating actions into
     a configuration change.
- Disposition: **answered** — option 2, chosen by the operator (2026-10-12).
  This change carries the repository and configuration work **and** the history
  rewrite; the rewrite is a task the operator executes, and the task list ends
  with confirming the published history records no operational value. Live
  provider and host responses stay out of scope. Rejected: option 1, because
  the published history would still disclose the values and the release note
  would hold only for tracked content; option 3, because a provider-side
  rotation is not provable by this project's verification targets and would mix
  operating actions into a configuration change.
