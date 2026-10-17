# Design: migrate-0-8-4-to-0-9-1

## Migration metadata

- source_version: `0.8.4`
- target_version: `0.9.1`
- upgrade_commit: `9207d06095b4b92578dc0985509b78623380bd5f`
- migration_type: aggregate maintenance change without a product specification

## Execution order

Work the following phases strictly in sequence. Follow each bundle's own completion rules; a bundle may direct that the repairs run as named follow-up changes. The complete sequence is also recorded in `migration.yaml`.

### Phase 1: migrate-0-8-0-to-0-9-0 (0.8.0 -> 0.9.0)

# Migration Design: 0.8.4 to 0.9.1

Self-contained procedure for the project LLM. You have no access to the Givn
source repository; everything required is in this document. The managed
refresh and the `givn_config_version` bump are already done by `givn upgrade`
(Commit 9207d06095b4b92578dc0985509b78623380bd5f); this maintenance change carries the
project-specific work and intentionally has no product specification.

## Execution model

Unlike the 0.7.0-to-0.8.0 bundle, this migration carries its work directly: it
edits one project-owned configuration file, `givn/config.yaml`. There are no
corpus repairs.

- Work the phases in order. Record the inventory as a table in this change's
  `design.md` (append it below this bundle text).
- Derive this change's tasks from the inventory rows before implementing; the
  change runs through the normal gates (design-review before tasks, review,
  archive), and its tasks evidence the verification below.
- When a disposition is not derivable from the project's own artifacts, stop
  and ask the human — one question at a time, with the old rule text and the
  candidate dispositions.
- If the project never customized a generated rule file and did not hand-edit
  the managed AGENTS.md block, record the "none found" finding with the file
  list you checked; the change then completes with the verification only.

## Preflight

1. Confirm `givn/config.yaml` declares
   `givn_config_version: "0.9.1"` and that this maintenance
   change exists (its id is `migrate-0.8.4-to-0.9.1`,
   or the aggregate id of the route that produced it).
2. Confirm the checkout is clean and committed before the first edit.
3. Read `skills.targets` in `givn/config.yaml` (default `opencode`). The
   generated rule directories are `<target>/skills/givn-*/SKILL.md` for every
   target, and `<target>/commands/givn-*.md` plus `grill-*.md` for the
   command-owning targets (`opencode`, `omp`).
4. Confirm the pre-upgrade revision: `9207d06095b4b92578dc0985509b78623380bd5f^` is the revision
   before the managed refresh and holds the old generated files. If the
   generated rules were never tracked (the default `rules: local-only`
   policy), the old content is not recoverable from history — ask the human
   for any project-specific rules they kept, and treat "none" as the finding.

## Phase 1 — Inventory the displaced project rules

1. List the managed rule paths present in the pre-upgrade revision, filtered
   to the configured targets, for example:

   ```sh
   git ls-tree -r --name-only 9207d06095b4b92578dc0985509b78623380bd5f^ \
     | grep -E '(skills/givn-[^/]+/SKILL\.md|commands/(givn|grill)-[^/]+\.md)$'
   ```

   A Fossil project uses the equivalent revision listing; if no listing is
   available, ask the human to supply the previous files.

2. Map every old file to its instruction id:

   | Installed file | Instruction id |
   | --- | --- |
   | `givn-propose` | `proposal` |
   | `givn-spec` | `specs` |
   | `givn-design` | `design` |
   | `givn-design-review` | `design-review` |
   | `givn-tasks` | `tasks` |
   | `givn-implement` | `tasks` (both files route to the same instruction) |
   | `givn-review` | `review` |
   | `givn-archive` | `archive` |
   | `givn-explore` | `explore` |
   | `givn-ideation` | `ideation` |
   | `givn-steps` | `steps` |
   | `givn-reverse-engineer` | `reverse-engineer` |
   | `givn-characterize` | `characterize` (reverse review: `review-reverse`) |
   | `givn-domain-modeling` (when enabled) | `domain-modeling` |
   | `givn-dev-principles` (when enabled) | `dev-principles` |
   | `grill-me` / `grill-with-docs` (when enabled) | `grill-me` / `grill-with-docs` |

3. For each old file, read its content from the pre-upgrade revision and the
   served instruction (`givn instructions <id> --change <this-change-id>`).
   Collect every rule statement the old file carries and the served content
   does not. Compare semantically: built-in rules may be reworded, moved
   between sections, or merged — that is not a displacement; a statement with
   no counterpart in the served content is.

4. Classify every collected statement:

   - **Project rule to keep** → an extension entry under the mapped
     instruction id (Phase 2). This includes house conventions, domain rules,
     and local constraints.
   - **Stale built-in text** → drop it; record the reason in the inventory
     row ("superseded by the served rules").
   - **Uncertain** → ask the human before choosing a disposition.

5. Inventory the `<!-- givn:begin:givn-project -->` …
   `<!-- givn:end:givn-project -->` block in AGENTS.md in the pre-upgrade
   revision the same way: the block is machine-owned and was refreshed by the
   upgrade, so an edit inside it is a displacement. Project guidance that must
   stay in AGENTS.md belongs outside the managed block.

6. Record the inventory in this change's `design.md` as one row per displaced
   statement:

   ```markdown
   | Old file | Displaced statement | Classification | Target instruction id |
   |---|---|---|---|
   | .opencode/skills/givn-propose/SKILL.md | <text> | project rule | proposal |
   ```

   Record the checked file list and a "none found" line when there are no
   displacements.

## Phase 2 — Record the extensions

1. Add or extend the `extensions:` map in `givn/config.yaml` (uncommented,
   project-owned; `givn upgrade` never touches user-owned lines):

   ```yaml
   extensions:
     proposal:
       - <the project rule>
     specs:
       - <the project rule>
   ```

2. Respect the recorded semantics: an id maps to a list of non-empty rule
   strings; an empty list is valid and adds nothing; list a rule under several
   ids to extend each of them; a repeated instruction key keeps the last
   entry; an unknown id or a malformed entry warns and is skipped at request
   time, and the built-in rules are served alone.

3. Verify each extended instruction:
   `givn instructions <id> --change <this-change-id>`. The served content
   must end with the marked `## Project extension` section carrying the rules
   in config order, and the built-in rules above it must stay unchanged. The
   section states that extensions add to the built-in rules and never
   override, suppress, or reorder them; a rule that contradicts a built-in
   rule stays visible to the project to resolve.

4. When the instruction has a project-owned replacement
   (`givn/artifacts/<id>/instructions.md`), the replacement is the base the
   extension extends — do not edit the replacement file.

## Phase 3 — Verify and complete

1. Spot-check the installed files in every configured target: they carry
   trigger, direction, and no rule copy; no extension text appears in them.
2. Confirm the extension lives only in `givn/config.yaml`: it is in no
   generated file and no managed refresh revision.
3. Run the project's suite (`verify.command`).
4. Derive this change's tasks from the inventory rows, run design-review
   before tasks, and complete the normal review and archive gates.

## Validation and completion

1. Every displaced statement has a disposition: an extension entry, a
   recorded "dropped as stale" reason, or a named follow-up change; the
   inventory records the checked file list (or the "none found" finding).
2. Each extended instruction serves its rules under the marked section and
   the built-in rules stay unchanged.
3. The installed files carry only trigger and direction.
4. The maintenance change archives through the normal gates; the migration is
   complete with that archive.


## Completion boundary

This generated design does not contain `DESIGN-REVIEW: PASS`, `REVIEW: PASS`, or implementation evidence. The project LLM must derive tasks and complete the normal Givn gates after the ordered bundle phases are understood, including any follow-up changes a bundle names.
