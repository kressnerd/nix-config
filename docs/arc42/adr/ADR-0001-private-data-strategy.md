---

status: accepted
date: 2026-10-12
decision-makers: dan (owner/operator)
consulted: none
informed: none

# Supply private operational values through an overridable flake input

## Qualification

ADR-QUALIFICATION: PASS

### Qualification verdict

qualification: QUALIFIED
alternatives: PASS
architectural_impact: PASS
durable_consequence: PASS
lower_level_artifact: PASS
existing_adr_check: PASS
must_be_shared: SUPPORTING
routing: NEW_ADR
canonical_artifact: null
target_adr: null
replacement_adr: null

Evidence:

- `alternatives`: six materially different mechanisms were compared in
  `docs/plans/private-data-remediation-plan.md` (Part 3A.7, Section 3.1): a
  gitignored file in the public repository, a permanently staged file,
  `builtins.pathExists` + `--impure`, `extraSpecialArgs` + `--impure`,
  SOPS-nix for the values, and a private git submodule, against the chosen
  overridable input.
- `architectural_impact`: it fixes where a host's operational values come from —
  a deployment and data boundary. Every host configuration is completed by an
  input module, every deploy command must override that input, and the public
  fallback must stay non-operational.
- `durable_consequence`: the `git+file://` source rule (below) makes a
  gitignored file unusable for evaluation, so reverting would require rewiring
  every host module, the deploy commands and the guard, not editing one file.
- `lower_level_artifact`: the change's `design.md` records the implementation of
  this change, and it is archived with the change; the rule here constrains
  every future host addition and every future deploy, so its durable home is
  this record (referenced from [chapter 8](../08-crosscutting-concepts.md) and
  [chapter 4](../04-solution-strategy.md)), not the archived design.
- `existing_adr_check`: the active register
  ([chapter 9](../09-architecture-decisions.md)) and
  [`adr/README.md`](README.md) contain no record of this boundary; the search
  result is `NEW_ADR`.
- `must_be_shared` (supporting): a contributor who does not know the rule would
  add a gitignored `private.nix` and break every host evaluation.

### MADR checklist evidence

- [x] **Hard to reverse** — Reverting later would cost significant effort
      because the host modules, the flake wiring, the deploy commands and the
      guard all encode the input contract, and the `git+file://` constraint
      blocks returning to a gitignored file for evaluation.
- [x] **Shapes quality attributes** — It materially affects security and
      reproducibility because the public repository's recorded content and
      published history carry no operational value, and a clean clone still
      evaluates without any private access.
- [x] **Structural** — It defines a boundary and a dependency direction because
      the public flake depends on an overridable input that supplies the host
      modules, and the public fallback is a stub that may not carry values.
- [x] **Must be shared** — Developers unfamiliar with it would systematically
      violate the architecture because the obvious move — a gitignored
      `private.nix` — is exactly the mechanism the constraint forbids.

## Context and Problem Statement

The repository is a public Nix flake whose host configurations need operational
values — addresses, gateway, resolvers, ports — that must not appear in the
public repository or its history. The obvious mechanism, a gitignored per-host
`private.nix` imported by the host module, does not work: when a flake lives in
a git worktree, `nix flake check`, `nix build .` and `nixos-rebuild --flake`
evaluate through a `git+file://` source that only sees files in the git index,
so an untracked file is invisible and every host build fails with
`path '…/private.nix' does not exist`. The values must therefore reach the
evaluator through a mechanism the evaluator can see and the operator can
override.

## Decision Drivers

- Operational values must never be recorded in the public repository or its
  history.
- A clean clone and CI must evaluate with zero private access.
- The mechanism must be usable at evaluation time (the values feed
  `systemd.network`, `networking.*`, firewall ports).
- Deployment must remain reproducible and reversible per host.
- A solo operator must be able to run it; a second repository is acceptable
  friction, a credential service is not.

## Considered Options

- Gitignored per-host `private.nix` in the public repository
- Permanently staged `private.nix` (`git add`, never commit)
- Overridable `private` flake input with an in-tree stub default
- `builtins.pathExists` / `extraSpecialArgs` with `--impure`
- git-crypt on `hosts/*/private.nix`
- SOPS-nix for the values

## Decision Outcome

Chosen option: "Overridable `private` flake input with an in-tree stub default",
because the input is visible to the `git+file://` evaluator and can be replaced
per command with `--override-input private git+file:///home/dan/dev/PRIVATE/nix-private`,
which no gitignored or encrypted file can do.

### Consequences

- Good, because a clean clone and CI evaluate with the in-tree stub and need no
  private access, so `nix flake check` is meaningful on any machine.
- Good, because the public `flake.lock` records only the in-tree stub path
  (`./private-stub`), never the private flake's URL, so the lock discloses no
  private location.
- Bad, because adding a host now requires touching two repositories (the stub
  module in the public one, the real module in the private one) — a deliberate
  friction recorded in [chapter 11](../11-risks-and-technical-debt.md).
- Bad, because a deploy that forgets `--override-input` evaluates the stub, and
  that evaluation is indistinguishable from a clean-clone evaluation; the stub
  assertion guards the *defaults* but cannot detect the forgotten override, so
  the deploy path must carry its own preflight that refuses when the override
  supplied no values.

### Confirmation

- `@check:private-data-hygiene` (`scripts/private_data_hygiene.py` over the
  recorded tree) fails if an operational value, a per-host private-value file,
  or an unencrypted secret is recorded.
- `@check:private-data-defaults` fails when the stub is active and a host
  default is not a documentation-range placeholder or empty. (The bound target
  is a check, not `@host:adlerkopf`: that host's toplevel does not evaluate on
  any revision — see R-017 — so the canonical `@host:` command cannot isolate
  the assertion.)
- The deploy path's preflight refuses to deploy when the override supplied no
  values (the per-host rebuild alias; operator-owned, recorded in the change's
  design).
- `@e2e @check:integration-private-data-separation` boots a machine whose
  network values are supplied from outside the repository and asserts the
  booted interface carries them.

## Pros and Cons of the Options

### Gitignored per-host `private.nix` in the public repository

- Good, because it is pure module system with no extra repository.
- Bad, because `.gitignore` does not untrack an already-committed file, so the
  values were published once and remain in history.
- Bad, because it is structurally unusable: the `git+file://` source cannot see
  the untracked file, so `nix flake check` fails the moment it is untracked.

### Permanently staged `private.nix` (`git add`, never commit)

- Good, because the file stays visible to the evaluator.
- Bad, because an accidental `git commit` publishes the values.

### Overridable `private` flake input with an in-tree stub default

- Good, because the evaluator sees a stub by default and the operator's private
  flake by override, so both CI and deployment work from one flake.
- Good, because the private flake is a separate repository that can later be
  pushed to a private remote without changing the public flake.
- Bad, because it adds a second repository and a stub to keep in sync.

### `builtins.pathExists` / `extraSpecialArgs` with `--impure`

- Good, because it needs no second repository.
- Bad, because it breaks pure evaluation: `nix flake check` cannot use it, and
  the same revision can produce different configurations on different machines.

### git-crypt on `hosts/*/private.nix`

- Good, because it is a single-repository workflow with the values available at
  evaluation time after `git-crypt unlock`.
- Bad, because CI and a clean clone see ciphertext, so `nix flake check` fails
  without a deployment key; a forgotten `.gitattributes` entry publishes
  plaintext.

### SOPS-nix for the values

- Good, because sops-nix is already the repository's secret mechanism.
- Bad, because sops-nix decrypts at activation, not at evaluation, while the
  values feed `systemd.network` and `networking.*` at evaluation time.

## More Information

- Change `private-data-remediation` (`givn/changes/private-data-remediation/`):
  proposal, capability spec `operational-data-separation`, and design.
- [`docs/plans/private-data-remediation-plan.md`](../../plans/private-data-remediation-plan.md)
  holds the full comparison and the one-time history rewrite procedure; it stays
  out of the recorded tree because it quotes the values.
- [Chapter 8](../08-crosscutting-concepts.md) states the concept;
  [chapter 2](../02-architecture-constraints.md) records the `git+file://`
  constraint as a technical constraint.
