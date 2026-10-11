# Instruction: specs

Write Gherkin `.feature` files that serve as the specification for this
change. These files are the delta — they are merged into the permanent spec on
archive.

This repository is a declarative Nix configuration for hosts and services:
there is no in-process application interface and no step runner. Read
`docs/GIVN-VERIFICATION.md` first — it is the canonical verification model, and
this instruction summarises it rather than restating its tables.

**Rules (enforced by default):**
- Scenarios assert **observable host/system state** in domain language
  (Given/When/Then about a host, a running service, a firewall decision, a
  file, a user/group, a systemd unit, a secret, or the result of an
  evaluation). Never reference internal module structure, option names,
  helper functions, or derivation internals.
- The only permitted implementation-flavoured content is an aspect that is
  *itself* an externally observable requirement (e.g. "the unit is active",
  "the port is listening", "the secret file has mode 0400").
- Tag the Feature `@givn.delta @<capability>`.
- Tag each Scenario `@givn.added` (default), `@givn.modified`, or
  `@givn.removed`.
- Tag `@wip` while the scenario's bound target is not yet implemented.
- Tags go on the line **before** `Scenario:`, never inside the scenario body.
- `@givn.removed` scenarios include exactly one placeholder step so the parser
  accepts them; givn lint suppresses warnings for them.
- **Exactly one binding tag per scenario.** Every scenario carries exactly one
  `@check:<name>`, `@host:<name>`, or `@deploy:<name>` tag naming the native
  target that proves it. `docs/GIVN-VERIFICATION.md` owns the tag-to-target
  table and the per-target run commands; `scripts/givn-spec-trace.py` enforces
  the binding, and a binding that does not resolve is a hard failure of the
  traceability check.

<example caption="Correct tag placement with a binding tag">
@givn.delta @my-capability

Feature: My Capability

  @givn.added @wip @host:my-host
  Scenario: The service is active after the host evaluates
    Given a host with the service enabled
    When the host configuration is evaluated
    Then the service unit is active and listening on its port
</example>

## What a scenario asserts

A scenario asserts externally observable state of a host or system, for
example:

- a service is active and listening on a port;
- a firewall drops or accepts a connection;
- a file, user, group, or systemd unit exists with the expected properties;
- a secret is materialised at the declared path with the declared owner/mode;
- the system evaluates and builds, and every declared assertion holds;
- after a VM boot, the described state holds.

Internal module structure, option names, and helper functions belong in
`design.md`, not in the spec. `docs/GIVN-VERIFICATION.md` owns the full list.

## End-to-end scenarios (`@e2e`)

The `@e2e` tag marks a scenario that exercises the real interaction surface —
for a declarative configuration that means an actual boot or a live host, not
an evaluation. An `@e2e` scenario MUST bind to one of:

- `@check:integration-<name>` — a `pkgs.testers.runNixOSTest` VM test (real
  boot, real service startup, real port binding);
- `@host:<name>` — a host configuration evaluation that a deploy test then
  confirms on real hardware; or
- `@deploy:<name>` — a deploy test against a live host.

Binding an `@e2e` scenario to a plain unit or lint check is a traceability
failure. `@e2e` scenarios run via `verify.e2e_command`, not `verify.command`
(both are configured in `givn/commands.yaml`). Every capability MUST include at
least one `@e2e` scenario that proves the system actually boots or is actually
deployed — not merely that it evaluates. `@e2e` names a distinct real outcome
(a boot, a deployment, a live connection), not a variant or error case of a
non-e2e scenario. The `@e2e` tag is immutable — never remove it to bypass the
gate.

## Merge semantics

- `@givn.added`: appended to the permanent spec (error if title already exists).
- `@givn.modified`: replaces scenario by title (error if not found).
- `@givn.removed`: deletes scenario by title (error if not found).
- On archive, all `@givn.*` tags are stripped, leaving clean runnable Gherkin.
  The `@e2e` tag is preserved (it is not a `@givn.*` tag).
