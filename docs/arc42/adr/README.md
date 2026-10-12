# Architecture Decision Records

Index of individual ADR files for this project. Owned by the `arc42-docs`
artifact; kept in sync with the chapter-09 register at
[`docs/arc42/09-architecture-decisions.md`](../09-architecture-decisions.md).

## Convention

One architecturally significant decision gets exactly one ADR file. Create the
file by copying [`adr-template.md`](adr-template.md) to
`ADR-NNNN-short-slug.md` and tailoring every section; the template is
self-contained. A decision that fails a mandatory qualification dimension is not
an ADR — it is routed to exactly one canonical artifact, and no file is created
here. Archived historical records keep their ID and move to
`archive/ADR-NNNN-short-slug.md`.

## Active records

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](ADR-0001-private-data-strategy.md) | Supply private operational values through an overridable flake input | accepted | 2026-10-12 |

## Archived records

None.

| ADR | Title | Status | Archive date |
|---|---|---|---|
| — | *None* | — | — |
