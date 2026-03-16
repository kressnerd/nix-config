# Documentation Standards

## Rule ID: DOC-STD-001

**Priority**: MANDATORY  
**Applies to**: All modes and all documentation artifacts

## Frameworks

| Concern | Framework |
|---------|-----------|
| Architecture documentation | [arc42](https://arc42.org) |
| Requirements documentation | [req42](https://req42.de) |
| Architecture Decision Records | MADR |
| Specifications | OpenSpec |

Use OpenSpec as the default to keep boundaries clear between frameworks.

## Principles

- **Lean**: Keep documentation as minimal as possible. Empty chapters and empty sections are acceptable — do not fill them with placeholder text.
- **No duplication**: Never document the same content in two places. Use cross-references instead (e.g., link from arc42 to the relevant req42 section).
- **Single source of truth**: Each fact lives in exactly one place.

## ADRs

- Architecture Decision Records (ADRs) follow the **MADR** format (Markdown Any Decision Records).
- arc42 MUST link to the MADR ADRs — never duplicate ADR content inside arc42.

## Dialect

All documentation is written in **Markdown** using **GitLab Flavored Markdown (GFM)** dialect.
