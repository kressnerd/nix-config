# Architecture Documentation (arc42)

This directory contains the project's arc42 architecture documentation.
Maintained by the `arc42-docs` givn artifact — updated with each change via `givn`.

| Chapter | File | Description |
|---|---|---|
| 1 | [Introduction and Goals](01-introduction-and-goals.md) | Requirements, quality goals, stakeholders |
| 2 | [Architecture Constraints](02-architecture-constraints.md) | Technical, organisational, legal constraints |
| 3 | [Context and Scope](03-context-and-scope.md) | System boundaries, external interfaces |
| 4 | [Solution Strategy](04-solution-strategy.md) | Fundamental decisions and approaches |
| 5 | [Building Block View](05-building-block-view.md) | Static decomposition into modules/components |
| 6 | [Runtime View](06-runtime-view.md) | Important runtime scenarios and flows |
| 7 | [Deployment View](07-deployment-view.md) | Infrastructure and deployment topology |
| 8 | [Cross-cutting Concepts](08-crosscutting-concepts.md) | Error handling, security, config, etc. |
| 9 | [Architecture Decisions](09-architecture-decisions.md) | ADR register/index; individual ADRs are in [`adr/README.md`](adr/README.md) |
| 10 | [Quality Requirements](10-quality-requirements.md) | Measurable quality scenarios |
| 11 | [Risks and Technical Debt](11-risks-and-technical-debt.md) | Known risks and debt |
| 12 | [Glossary](12-glossary.md) | Domain and technical terms |

## ADR Storage

One architecturally significant decision gets exactly one ADR, and each ADR
body is stored in its own Markdown file. With the default output directory,
use these paths:

- `docs/arc42/09-architecture-decisions.md` is the chapter-09 register/index.
  It contains one row or link per ADR, not multiple ADR bodies or repeated
  MADR sections.
- `docs/arc42/adr/README.md` is the index of the ADR directory. Keep it aligned
  with the chapter-09 register.
- `docs/arc42/adr/ADR-NNNN-short-slug.md` is the path for an active ADR.
- `docs/arc42/adr/archive/ADR-NNNN-short-slug.md` is the path for an archived
  historical ADR. Preserve its ID and update both indexes when moving it.

The current binary uses the fixed `docs/arc42/` output root and does not
implement an `arc42.output_dir` override. `givn/archive/<change>/` is reserved
for archived changes and is not a location for ADR bodies. The addon does not
automatically scaffold individual ADR files; create the directory, file, and
index entries manually.

## Qualification Gate

Before creating an ADR or registering it, read the complete qualification
procedure from the resolved Arc42 addon instruction. This chapter README owns
storage and index rules only; it does not duplicate the qualification formula,
LLM verdict schema, or routing values. If a mandatory dimension fails, no ADR is
created and the decision is routed once to its canonical artifact. A refinement
amends an existing ADR instead of creating a new file.

## Status and Supersession

Every individual ADR uses MADR frontmatter. The allowed `status` values are
`proposed`, `rejected`, `accepted`, `deprecated`, and `superseded by ADR-NNNN`.
The last form must name a concrete existing replacement ID, such as
`superseded by ADR-027` or `superseded by ADR-0042`; a bare or placeholder ID is
invalid. Completed ADRs
must have a real date and real participant values, contain all MADR sections,
and contain no template placeholders. The register and both ADR indexes must
link to the current file path and preserve historical links for archived or
superseded records.
