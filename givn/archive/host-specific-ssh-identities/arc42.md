# arc42 Impact Assessment — host-specific-ssh-identities

## Status

STATUS: DONE

Assessment walked over all twelve chapters against `proposal.md`, `specs/` and
`design.md`. Four chapters are affected and were updated in place; the other
eight are unaffected.

| # | Chapter | Affected | Reason |
|---|---|---|---|
| 01 | Introduction and Goals | No | No quality goal or requirement changes; an existing requirement (usable work context) is met on one more device. |
| 02 | Architecture Constraints | No | No new technical, organisational or regulatory constraint; the existing `myHome.*` option convention is followed. |
| 03 | Context and Scope | No | External partners (GitHub, Bitbucket) and the system boundary are unchanged; only which local key a device presents changes. |
| 04 | Solution Strategy | No | The strategy (host declarations feed shared home-manager feature modules) already exists; this change applies it. |
| 05 | Building Block View | **Yes** | New options module `modules/home-manager/ssh/options.nix`; the SSH feature now depends on a host declaration. |
| 06 | Runtime View | No | No new runtime flow: identity selection happens before any SSH connection, exactly as today. |
| 07 | Deployment View | No | Nodes and topology unchanged; thiniel and the MacBook keep their roles. |
| 08 | Cross-cutting Concepts | **Yes** | New cross-cutting concept: per-host identity declaration (which identity material a device holds and may present). |
| 09 | Architecture Decisions | No | No ADR. The decision is not qualified: falsification test 1 (reversible within this change) and test 2 (constrains no second component or future change) both fail the candidate, `durable_consequence` and `lower_level_artifact` fail, and the register is empty (only `adr-template.md` exists). Canonical destination of the rationale: `design.md` (single owner — the capability spec owns the observable behaviour, not the rationale). |
| 10 | Quality Requirements | No | No measurable quality scenario changes; the security posture is preserved (fail-closed identity selection). |
| 11 | Risks and Technical Debt | **Yes** | A declared identity file that is absent fails closed and stays silent until the first connection (R-001); the work identity key names remain device-specific literals (TD-001). |
| 12 | Glossary | **Yes** | New terms: connection entry, identity declaration, identity file, identity material, personal identity, private workspace, work identity. |

Chapters 01, 02, 03, 04, 06, 07 and 10 still contain only their scaffold
placeholders (created in `5027ac4`, before this change) and are deliberately
left untouched: this change alters no goal, constraint, external interface,
strategy, runtime flow, deployment topology or quality scenario. Chapters 05,
08, 11 and 12 were placeholders too and are now filled for the parts this
change touches.

## Chapter updates performed

- `docs/arc42/05-building-block-view.md` — system decomposition and the new
  option module as a level-2 building block.
- `docs/arc42/08-crosscutting-concepts.md` — per-host identity declaration.
- `docs/arc42/11-risks-and-technical-debt.md` — R-001 to R-003 and TD-001.
- `docs/arc42/12-glossary.md` — identity declaration, identity file, identity
  material, personal identity, private workspace, work identity.

Chapter 09 register is unchanged: no ADR was created, so no register row and no
ADR index entry are added (`docs/arc42/adr/README.md` does not exist yet;
`docs/arc42/adr/` holds only the template).
