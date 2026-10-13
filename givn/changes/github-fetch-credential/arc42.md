# arc42 Impact Assessment — github-fetch-credential

## Status

STATUS: DONE

All twelve chapters were walked against `proposal.md`, `specs/` and `design.md`.
Five are affected and were updated in place; seven are unaffected.

| # | Chapter | Affected | Reason |
|---|---|---|---|
| 01 | Introduction and Goals | No | No goal, stakeholder or quality goal changes: the owner's build machines already had to resolve the private input; the change removes the manual step and the plaintext file. The security requirement it does state is recorded as QS-017 in chapter 10. |
| 02 | Architecture Constraints | No | No new constraint: the change *follows* the existing sops-nix secret-store constraint (chapter 2 "Conventions": secrets are declared under `sops.secrets` and consumed through `sops.placeholder`) and the recorded rule that agents never run `sops`. Its alternatives would have *violated* those constraints (a credential as a configuration literal, or in a process environment). |
| 03 | Context and Scope | No | No new external partner or interface: GitHub is already a source of flake inputs, and the interaction is the same fetch with an added credential. No user-facing surface changes. |
| 04 | Solution Strategy | No | The strategy is unchanged and reused: shared option modules render from per-host declarations, secrets come from sops-nix, verification binds scenarios to native targets. |
| 05 | Building Block View | **Yes** | One new NixOS option pair (`modules/nixos/github-fetch-credential`); the two build machines opt in (the Mac declares its own pieces because nix-darwin cannot manage `nix.conf` there); the integration check gains a seventh test that builds its own SOPS fixture in a derivation. |
| 06 | Runtime View | **Yes** | New runtime flow: activation decrypts and renders the fragment, the machine's configuration includes it, and the owner's and root's clients present it — recorded as its own scenario, including the per-platform render layer. |
| 07 | Deployment View | No | No node, role or topology change; the credential is per-machine state and adds no deployment target. The MacBook's root-side configuration file is a per-machine detail recorded in chapter 6 and chapter 11 (R-028). |
| 08 | Cross-cutting Concepts | **Yes** | New concept: the GitHub fetch credential — where it may enter the system (never a configuration literal, store path, or environment variable), the per-platform render layer and include, the reach the owner selected (owner and root), and the custody invariant (readable by root and the owner only). |
| 09 | Architecture Decisions | **Yes** — a candidate row, not an ADR | The candidate "supply the credential through a runtime-rendered include file" was assessed and is **NOT_QUALIFIED**; a row was added to the candidate table and the register itself is unchanged (still one accepted ADR). Verdict and evidence below. |
| 10 | Quality Requirements | **Yes** | New scenario QS-017 (secret/access security: the credential is readable only where it must be, and both clients present it with nothing prepared). |
| 11 | Risks and Technical Debt | **Yes** | Four risks and one debt item recorded: the surviving plaintext token file (R-026), the repository's own evaluation that cannot fetch its input (R-027), the MacBook's root-side configuration file (R-028), the MacBook's session-time rendering (R-029), and the fixture's non-reproducible derivation (TD-016). |
| 12 | Glossary | **Yes** | New term: *GitHub fetch credential*, with its contrast pair against *identity file* and *operational value*. |

Chapters 01, 02, 03, 04 and 07 were re-read and deliberately left untouched.

## Chapter updates performed

- `docs/arc42/05-building-block-view.md` — one module row; the per-host profile
  table (`sops.secrets` count and declarations for thiniel and the MacBook); the
  integration-test inventory (seventh check, third Home-Manager-loading check,
  the fixture derivation).
- `docs/arc42/06-runtime-view.md` — new scenario "GitHub credential supply to a
  nix client" (sequence diagram, per-platform steps, evidence note).
- `docs/arc42/08-crosscutting-concepts.md` — new section "GitHub fetch
  credential", including the per-platform render-layer table.
- `docs/arc42/09-architecture-decisions.md` — one candidate-assessment row; the
  register, the ADR directory index and the ADR files are unchanged.
- `docs/arc42/10-quality-requirements.md` — QS-017, plus a clarification that
  the booted credential check decrypts a generated test fixture, never a host's
  credential.
- `docs/arc42/11-risks-and-technical-debt.md` — R-026 to R-029 and TD-016.
- `docs/arc42/12-glossary.md` — the term *GitHub fetch credential*.

These chapters describe the architecture this change produces. At authoring
time the change is at the design stage, so the statements are *declared*
(Nix source states it) and the booted proof is the new check; no live host was
inspected and no host credential was decrypted.

## ADR qualification verdict

```json
{
  "qualification": "NOT_QUALIFIED",
  "alternatives": "PASS",
  "architectural_impact": "PASS",
  "durable_consequence": "FAIL",
  "lower_level_artifact": "FAIL",
  "existing_adr_check": "PASS",
  "must_be_shared": "SUPPORTING",
  "routing": "CANONICAL_ARTIFACT",
  "canonical_artifact": "givn/changes/github-fetch-credential/design.md",
  "target_adr": null,
  "replacement_adr": null,
  "evidence": {
    "alternatives": [
      "a configuration literal: nix.settings.access-tokens would put the value in the world-readable /etc/nix/nix.conf and in a store path",
      "a session environment variable (NIX_CONFIG), which is today's shape: visible in /proc/<pid>/environ, absent for root's sudo invocation, absent after a root wipe, performed by hand every session",
      "netrc-file, which covers HTTP basic auth but not the GitHub API resolution the github: fetcher performs",
      "a root-owned file readable through an existing group: thiniel has no group containing only the owner (users.users.dan.group = \"users\"; the deliberate test account is in users with extraGroups = [ \"wheel\" ]) and macOS gives every standard account the owner's primary group staff",
      "appending the include to the Mac's Determinate-managed /etc/nix/nix.conf, which nix-darwin does not own there (nix.enable = false)",
      "home-manager-level rendering on the Linux build machine, which starts with the owner's session and would leave root's first build unauthenticated",
      "a committed test key for the VM fixture, which the repository's own gitleaks rules refuse",
      "a shell wrapper exporting NIX_CONFIG from the rendered file, which covers interactive shells only"
    ],
    "architectural_impact": [
      "fixes where a credential may enter the system: the sops-nix secret store, decrypted at activation into a runtime file, read through a configuration include — never a configuration literal, a store path, or a process environment",
      "fixes the reach the owner selected: the owner's clients and root's clients on the two build machines"
    ],
    "durable_consequence": [
      "reversible within one change: remove the option pair, the declarations and the include lines",
      "the boundary it relies on (SOPS with age, per-host recipients, decryption at activation) already exists and is recorded in chapter 2 and chapter 8"
    ],
    "lower_level_artifact": [
      "the complete rationale is owned by the change design.md (custody decision, rejected alternatives, per-platform render layer, Darwin injection point)"
    ],
    "existing_adr_check": [
      "the active register (chapter 9) and docs/arc42/adr/README.md hold one ADR, ADR-0001 (private operational values through an overridable flake input); it decides a different boundary (evaluation-time host values, kept out of the repository rather than encrypted)",
      "no active or archived record states where a runtime credential reaches nix; result: CANONICAL_ARTIFACT"
    ]
  }
}
```

Falsification test 1 applies: the decision is implementable and reversible
within one change and touches one concern (credential supply). Test 3 also
applies: the observable behaviour — a device presenting only the credential it
declares — is ownable by the capability spec plus Gherkin. Test 2 does not
apply, which is why `architectural_impact` passed: the rule that a credential
never becomes a configuration literal, a store path, or an environment variable
constrains every future credential addition.
