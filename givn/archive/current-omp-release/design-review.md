# Design Review — current-omp-release

- Date: 2026-10-13
- Reviewed artifacts: `proposal.md`, `specs/reproduce-working-environment/*`,
  `design.md`, `arc42.md` and the twelve `docs/arc42/` chapters
- Method: one grilling subagent in a fresh context (`reviewer`, no access to the
  session that wrote the design) read the planning artifacts and the relevant
  source, returned findings plus operator questions, and re-derived the arc42
  chapter assessment independently. Its findings are recorded below with their
  dispositions; everything it reported was re-checked against the tree before
  being accepted or rejected.

## Phase 1 — grilling findings and dispositions

| # | Finding | Severity | Disposition |
|---|---|---|---|
| F1 | The two `@check:unit-agent-secret-guard` scenarios cannot produce a behaviour-driven RED: the guard hook is tracked and unchanged by this change, so their only failure at wiring time is the missing flake output. `docs/GIVN-VERIFICATION.md:122` ("a scenario whose target already passes is not RED") and `:129` ("when a change introduces a new target, wire it in before RED") make that RED insufficient for a behaviour claim. | MAJOR | **Fixed.** The design now declares both scenarios *characterization* and records the mutation step as the failure demonstration (invert one expected verdict, observe a non-zero driver exit), keeping the target as their traceability binding. The new behaviour in this contract — the guard installed on the Mac — carries its own bindings (`@host:J6G6Y9JK7L`, the booted check). |
| F2 | The booted check's guest command (`sudo -u test env HOME=/home/test omp --version`) cannot find the agent: it is a Home Manager package of the test user, while the test driver runs as root with the system `PATH`; the check would exit 127 and never reach GREEN. | MAJOR | **Fixed.** The guest invokes the agent by the store path of the package the device declares (`${ompPackage}/bin/omp --version`), which is `PATH`-independent. The design states explicitly that a login-shell `PATH` resolution is *not* asserted, because that would test Home Manager's shell integration rather than the agent. |
| F3 | The claim "a missing key degrades one server rather than failing the activation" had no scenario or target. | MINOR | **Fixed.** The e2e scenario's Given now states that the device holds none of its servers' key material, and the booted check asserts that no key path exists under the user's `~/.config/sops-nix/secrets/` while the agent still starts. The design names the remaining, untested part (which header a failed read drops) as upstream behaviour this repository does not test. |
| F4 | The glossary's `Check` row did not list the two checks this change adds. | MINOR | **Fixed.** Both checks are listed, annotated with the change that adds them. |
| F5 | `docs/arc42/06-runtime-view.md` still said "the four `integration-*` checks". | MINOR | **Fixed.** Five checks, named explicitly; `unit-agent-secret-guard` added to the evaluation-scope list in the same scenario. |
| F6 | The same concept was named three ways (spec "shared servers", chapter 3 "Coding-agent model servers", design "MCP servers") and none was in the glossary; the design-review gate requires the design's terms to be in the glossary before sign-off. | MINOR | **Fixed.** New glossary term `Model server (MCP server)`; spec, chapter 3 and the design now use it. |
| F7 | The universal rule "a device that carries the agent also carries its guardrails" was asserted only for the Mac; a regression that dropped the guard from the shared module would fail on one device only. | INFO | **Fixed.** `tests/assertions/thiniel-invariants.nix` also asserts the declared guard installation, and the laptop scenario now says "current, guarded". |
| F8 | The proposal promises refusal "in every approval mode", which no scenario exercises. | INFO | **Recorded, claim kept.** The mode-independence is a property of the hook's unconditional `{ block: true, reason }` return, which the guard check asserts; no check can set an approval mode without a model-backed session (the same limit is recorded as `R-020`/`TD-014`). The design now states this instead of leaving the promise implicit. |
| F9 | The design said `ompPackage` goes into `specialArgs` in one row and `extraSpecialArgs` in another; the consumer is a Home Manager user module, so the system `specialArgs` would never reach it. | INFO | **Fixed.** Both places say `home-manager.extraSpecialArgs`. |

Rejected finding: the subagent's suggestion to record the two guard scenarios as
"bound to behaviour this change introduces" (F1 option c). The guard's verdict
table is not new behaviour, and moving the binding to the Mac's installation
would stop the target from proving the refusal cases the scenario names. The
characterization-plus-mutation record is the honest form.

## Phase 1 — operator question, closed

### Q1 — An agent installed on the work MacBook outside this configuration

- Status: closed 2026-10-13 (operator).
- Blocks: whether the change deletes a file outside the configuration on the
  Mac, and whether the asserted version floor describes the binary actually run.
- Context: the proposal's ledger item D4 carried this with the policy "the
  configured agent is authoritative" and no outcome. Nothing in this repository
  installs the agent on `J6G6Y9JK7L`; upstream's installer places its binary in
  `~/.local/bin`; the session cannot reach that machine, so the repository
  cannot answer it.
- Options considered:
  1. **No out-of-band agent exists** — nothing is touched; the floor describes
     what is run; in practice `command -v omp` resolves under the Nix store.
  2. **It exists; remove it** — the configured agent becomes the only one, so
     the floor and the parity work describe the binary in use; cost: deleting a
     file outside the configuration, after the operator identifies it, and that
     hand-installed binary is not recoverable.
  3. **It exists; leave it** — nothing outside the configuration is touched;
     cost: whichever binary comes first on `PATH` wins, so the device
     configuration could assert 18.10 while the operator runs a different build
     with neither the servers nor the guard.
- Resolution: **option 1** — the operator confirmed no agent exists on that
  machine outside this configuration. Rejected: option 2, nothing to remove;
  option 3, the shadowing risk it priced does not exist here. The design records
  the decision under `Decides D4` and keeps one re-check on the Mac
  (`command -v omp` after activation), because the repository still cannot
  observe that machine.

## Branch coverage

| Branch | Verdict | Evidence |
|---|---|---|
| Scope | Minor gap, fixed | The five scenarios cover proposal points 1–5 with nothing extra; point 4's approval-mode wording is now recorded as inspection-backed (F8). |
| Tech choices | No issue | The dedicated pin is verified independently: `nixpkgs/master` carries `omp` 18.10.0 for `x86_64-linux` and `aarch64-darwin`, both outputs are served by `cache.nixos.org` (dry-run: 1 path / 397 MiB and 5 paths / 344 MiB, nothing compiled), and the derivation depends on bun 1.4.2 as the design claims. `lib/helpers.nix` is correctly left untouched. |
| Missing scenarios | Fixed | Key-less device (F3), thiniel's guard (F7); the floor refresh is deliberately not a scenario (nothing observable to bind, recorded in D1/R-018). |
| Testability | Fixed | Both host scenarios fail today for a named reason (18.8.4; no agent on the Mac). The two guard scenarios' RED model is now characterization plus mutation (F1). No tautology found. |
| Verification-binding completeness | Passes | Exactly one binding tag per scenario; `@e2e` binds to a VM check; `verify.command` (`./scripts/givn-verify.sh`) differs from `verify.e2e_command` (`./scripts/givn-verify-e2e.sh`). `scripts/givn-spec-trace.py` exits 1 with exactly the three expected findings — the two new check names do not exist yet, which is the planned RED. |
| Deployment & rollback | Passes | Apply, build-before-switch and rollback commands are recorded; `~/.omp` is already persisted on thiniel and the Mac's profile uses no persistence bind, so the guard file lands in ordinary user state and is refreshed by `install` each activation. No dangerous area is touched. |
| Risk | Recorded | Most likely failure (the VM guest invocation, F2) is fixed; second (the degenerate RED, F1) is fixed by declaring characterization. |
| Decision ledger | Passes | D1 answered in the proposal, D2 decided here, D3 answered in the proposal, D4 answered by the operator above. No unrecorded item. |
| Use-case and Persona context | Passes | Use case `reproduce-working-environment`; new capability `current-agent-tooling`; change-side `usecase.md` differs from the permanent one by exactly the capability, its interaction row, two rules and one example. The deviation from `givn spec route` (EXTEND `operational-data-separation`) is upheld: that capability governs what the public repository records, not device tooling. Personas: `owner--operator` relevant; `family--application-user` unaffected. No persona invented or promoted. |
| Ubiquitous language | Fixed | `Coding agent`, `Secret-access guard` (contrasted with the existing `Guard`), `Agent version floor` and now `Model server (MCP server)`; all used consistently in spec, design and chapters 3/12. |
| Architecture documentation | Passes after one fix | The subagent independently marked all twelve chapter-selection rows Yes against proposal/spec/design, matching `arc42.md`; it then found one stale sentence inside a chapter marked Yes (F5, fixed). All twelve chapter files exist, are non-placeholder, and contain no ASCII-art or unboxed pseudo-diagrams (Mermaid plus chapter 7's documented inline SVG and chapter 9's one formula block). Chapter 9 records no MADR for the non-qualifying candidate and routes it once to `design.md`; chapter 11 carries its consequences (`R-019`, `TD-014`). |
| Anything else | Passes | The flake's check wiring picks the new targets up (`givn-verify.sh` builds all non-integration checks and evaluates every host's assertions; `givn-verify-e2e.sh` globs `integration-*`); the guard hook is git-tracked, so the flake path resolves. |

## Phase 2 — hardening log

| Artifact | Change |
|---|---|
| `design.md` | Architecture Impact: `extraSpecialArgs` wording, thiniel guard assertion, Mac assertion list. Verification Binding: characterization + mutation RED for the two guard scenarios, laptop scenario renamed, e2e row names the PATH-independent invocation and the key-less assertion. Test Targets: mutation note, PATH-independent guest command, key-less assertion, both hosts' guard assertions. Decisions: D4 answered (nothing to remove). Local Runnability: PATH obstacle and its fix replace the `HOME`-only obstacle. Secrets: the key-less half of the missing-key claim is now bound. Risks: approval-mode limit recorded. |
| `specs/reproduce-working-environment/current-agent-tooling.feature` | Laptop scenario renamed and given the guard Then; e2e scenario Given names the key-less condition; "the same two shared model servers" uses the glossary term. |
| `docs/arc42/12-glossary.md` | `Model server (MCP server)` added; `Check` row lists the two new checks. |
| `docs/arc42/06-runtime-view.md` | Evaluation-scope check list gains `unit-agent-secret-guard`; the integration check count corrected to five and named. |
| `docs/arc42/03-context-and-scope.md` | Interface renamed to the glossary term; status reflects the key-less observation. |
| `arc42.md` | Rows 3 and 12 updated to match the chapter content. |

## Phase 2 — verification

| Check | Result |
|---|---|
| `givn lint --change current-omp-release` | exit 2 (allowed): the five `@wip` findings and one advisory — the laptop scenario is a strict subset of the Mac's, which is inherent, since one host's assertions are a superset of the other's and a scenario carries exactly one binding tag, so they cannot be merged. |
| `python3 scripts/givn-spec-trace.py` | exit 1 with exactly the three expected findings: `@check:unit-agent-secret-guard` (×2) and `@check:integration-agent-tooling` do not exist in the flake yet — the planned RED state, to be cleared in the implementation step. |
| Guard verdict driver (already run at design time) | 14 crafted tool calls under bun: all verdicts as specified, exit 0. |
| Fresh pin substitutability | `nixpkgs/master` `omp` 18.10.0 for both target systems, nothing compiled. |
| arc42 row re-derivation | Twelve of twelve rows Yes by independent read; chapter contents match the design after F5. |

## Deferrals

None. No mandatory check was deferred and no operator decision was deferred; the
Mac's runtime behaviour is not deferred but out of reach — this repository has no
`tests/deploy/` layer, so the Mac's scenarios assert declared state and the
running agent is confirmed at activation. `TD-014` records the same limit for a
live agent session.

## Addendum — findings raised during implementation (2026-10-13)

The design-review sign-off above stands; these two items were found while
implementing the tasks and are recorded here because both change what the
artifacts say, not what the plan is.

### F10 — The guard's coverage is a glob set, and this repository's own decrypted keys sit outside it

- Evidence: the guard check's first run failed on a case of mine that expected a
  refusal for `grep` over `~/.config/sops-nix/kagi/api-key`. The hook refused only
  the paths in its declared set — `/run/secrets/*`, a `sops/age/` path,
  `/var/lib/sops-nix/*` — so a `read` of that path returns no verdict. sops-nix
  places *user-side* secrets under `~/.config/sops-nix/secrets/`, which is where
  this repository's `context7` and `kagi` keys are decrypted (the agent module's
  `!cat $HOME/.config/sops-nix/secrets/…` reads them there).
- Impact: the machine-enforced half of the rule "agents never read decrypted
  secret material" does not cover that path, so a *direct* read of it by the
  agent's tools is not refused. It does not mean the agent handles the key in
  normal MCP use: the `!command` indirection is resolved by the MCP plugin, not
  by the agent's tools. Pre-existing and unchanged by this change — the change
  installs the same hook, so the same coverage applies on the second device.
- Disposition: **closed — accepted as designed (operator decision, 2026-10-13).**
  The keys must stay where sops-nix places them, and the agent does not receive
  key material in normal use: the MCP declaration's `!command` indirection is
  resolved by the MCP plugin on the client side of the connection, not by the
  agent's tools, so the model never sees the value. The residual property — a
  session that deliberately asks the agent to read that path is not blocked by
  the guard — is accepted by the operator and left to the process rule in
  `CLAUDE.md`. No follow-up change follows. Actions already taken stand: the
  driver's case table matches the guard's declared set (the gap is never pinned
  as expected behaviour), the scenario names the surfaces the guard actually
  covers, and the durable docs carry the accepted property as `R-021` in
  `docs/arc42/11-risks-and-technical-debt.md`.

### F11 — The two characterization scenarios share one revision

- The two `@check:unit-agent-secret-guard` scenarios are characterization: the
  hook is unchanged, and their deliverable — the verdict check and its driver —
  landed with the verification plumbing in revision `270ed64` (their T1 setup),
  which also removed the need for two spec-only revisions.
- Disposition: accepted and recorded in `tasks.md` (T4.COMMIT / T5.COMMIT). The
  givn rule "a commit touching only the spec skeleton means the task is not done"
  is what that merge avoids; each scenario still has its own mutation RED, its own
  GREEN and its own evidence recorded.

DESIGN-REVIEW: PASS

