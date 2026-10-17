# Proposal: migrate-0-8-4-to-0-9-1

## Aggregate migration

This maintenance change migrates a project from Givn 0.8.4 to the installed Givn 0.9.1 contract. Managed preparation was recorded in Commit A `9207d06095b4b92578dc0985509b78623380bd5f`. The migration phases below are one ordered plan; work each phase in order and follow the completion rules in its bundle.

## Scope

The LLM must inspect project evidence and derive project-specific tasks. It must preserve project-owned overrides and must not invent domain behavior, tests,architecture decisions, or provenance.

## Bundle proposals

### Phase 1: migrate-0-8-0-to-0-9-0 (0.8.0 -> 0.9.0)

# Migration Proposal: 0.8.4 to 0.9.1

## Problem / Opportunity

Givn 0.9.1 moves the rules out of the installed files:

- **Installed skills and commands become triggers.** Each generated file
  carries trigger metadata and a direction to `givn instructions <id>`, which
  serves the rules at call time. A generated file from an earlier version that
  still carries a full rule copy was rewritten to the direction by this
  upgrade; built-in rule text no longer lives in the project.
- **Project rules get an additive home.** `givn/config.yaml` gains the
  project-owned `extensions:` map: an instruction id maps to rule strings,
  served after the built-in rules under a marked `## Project extension`
  section. Synchronization and upgrades never touch it.
- **The AGENTS.md `givn-project` block is refreshed.** Its resident rules
  (task checkoff and commit-message obligations) now come from the served
  tasks instruction, so the block is machine-owned and an edit inside it is
  not preserved.

A project that kept its own rule text inside generated skill or command files
(hand-edited copies, or copies committed under `rules: versioned`) has lost
its home: the managed refresh already rewrote those files, and a
synchronization never preserves an edit in them. This maintenance change
restores the displaced rules to a durable, project-owned place.

## Proposed Solution

Inventory every project-specific rule that lived in a generated rule file or
inside the managed AGENTS.md block, and record it in the `extensions:` map of
`givn/config.yaml` under the instruction id it belongs to. Read the
pre-upgrade revision (`9207d06095b4b92578dc0985509b78623380bd5f^`) for the old file content and
compare it against the served instruction (`givn instructions <id>`); text
that the served instruction does not carry is either a project rule to keep or
stale built-in text to drop. The next request serves the extension; no
generated file carries it.

A project that never customized a generated rule file has nothing to move:
record that finding, verify the installed files carry only trigger and
direction, and archive this change.

Nothing else changes. Built-in rules arrive at the next request, this change
edits no product specification, design, or ADR, and project-owned
replacements (`givn/artifacts/<id>/instructions.md`,
`givn/skills/<name>/SKILL.md.tmpl`) stay byte-for-byte: the extension extends
the replacement, it never rewrites it.

## Out of Scope

- Replacing or rewriting built-in rules; changing steps, order, or gates.
- Editing the project's specifications, designs, ADRs, or personas.
- Migrating away from project-owned replacements; they keep their current
  form and receive the extension on top.
- Re-wording old rule text: a rule that the served instruction already carries
  with different words is not a displacement.

## Completion Boundary

This change is complete when every displaced project rule has a disposition
(recorded as an extension entry, dropped as stale with its reason, or named in
a follow-up change), the extended instructions serve their rules under the
marked section, the installed files carry only trigger and direction, and the
maintenance change has archived through the normal gates.


