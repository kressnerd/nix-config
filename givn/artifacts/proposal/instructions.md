# Instruction: proposal

Write a proposal that describes the WHAT and WHY of this change, in domain
language that a non-technical stakeholder can read and validate.

This repository is a declarative Nix configuration for hosts (NixOS and
nix-darwin), an edge gateway, and supporting scripts. A change touches hosts,
services, modules, secrets, firewall rules, boot behaviour, or persistence.
Read `docs/GIVN-VERIFICATION.md` first: it is the canonical verification model
that every artifact uses.

**Rules (enforced by default):**
- **Release note (required).** The proposal carries one complete, user-facing
  sentence naming what the change does; every revision the change records
  carries the release note as its message subject, with the scenario title in
  the message body. A one-scenario change may reuse its scenario sentence as
  the release note.
- Describe observable host/system behaviour, not implementation. No module
  paths, option names, helper functions, or derivation internals.
- The only permitted implementation-flavoured content is an aspect that is
  *itself* an externally observable requirement (e.g. "the service listens on
  port 443", "the secret file is owned by root with mode 0400", "state
  survives a reboot"). Heuristic: if it would still be true if the host were
  re-declared differently, it belongs in the spec; otherwise it belongs in
  design/tasks.
- Write in the language of the operator and the system (hosts, services,
  firewall, secrets), not in the vocabulary of an application framework.
- **Verification invariant.** Every scenario produced downstream (in the
  `specs` artifact) binds to exactly one native target — a flake check
  (`@check:<name>`), a host configuration evaluation (`@host:<name>`), or a
  deploy test (`@deploy:<name>`) — and the `verify.command` chosen in
  `design.md` runs those targets. There is no step runner and no
  hand-maintained parallel test: the bound target's assertion is the
  executable specification. See `docs/GIVN-VERIFICATION.md`. Keep this in
  mind: every behaviour you describe here must be assertable against a host,
  a running service, or a Nix evaluation.
- **Use-case context.** When a change has a permanent use-case ID or an
  ideation change seed, read its `usecase.md` and record the ID, source topic,
  and confirmed affected Persona IDs. Never invent or auto-promote Personas;
  do not copy Persona biographies into the proposal. An infrastructure change
  almost always records `none` with a reason.
- **Seed stamping.** When the change originates from an ideation change seed,
  record the seed path in the proposal's Use-Case Context and set the seed's
  status line to `Status: proposed by <change-id>`. The seed's original text
  stays unchanged; only the status line is edited.
- **Question disposition.** When the change originates from an ideation seed,
  every intersecting seed question is dispositioned in the proposal before
  specs: **answered** with its source, **carried** with an owner and the
  artifact that will decide it, or **out of scope** with a reason. An
  undispositioned intersecting question blocks the specs step; the same
  structure is advisory without an ideation source. "Resolved in `design.md`"
  alone is not a disposition. A statement qualified `(open: Q<N>)` names a
  question that must be dispositioned here.
- **Question IDs.** Open questions carry stable IDs `D1`, `D2`, … (`D<n>` in
  the templates) with the full question and its option treatment; the
  design's ledger resolves each ID.
- **Capability routing.** Run `givn spec route --change <id>`. When it
  reports signal, record route's recommendation and the decision in the
  Capability Routing table. When it reports no signal, omit the
  recommendation column and record the decision with its rationale directly.
  The recorded decision stays mandatory either way.
- **Persona confirmation.** A change with a user-visible surface names at
  least one confirmed Persona, or records `none` with the reason and the
  operator confirmation. An infrastructure change almost always records
  `none`.

**Structure:**
1. Release note — one complete, user-facing sentence naming what the change does.
2. Problem / Opportunity — what is wrong or missing?
3. Proposed Solution — what should the system do, observably?
4. Out of Scope — what is not changing?
5. Open Questions — unresolved decisions before moving to specs.
