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

---

## Project hardening — design-review 2026-10-17

This section records the project-specific decisions the generated bundle leaves
to the project LLM, plus the corrections the design-review grilling produced.
It supersedes the bundle text where they disagree.

### Preflight corrections

- The change id is `migrate-0-8-4-to-0-9-1` (kebab-case). The dotted form
  `migrate-0.8.4-to-0.9.1` in the bundle preflight is a display title; the CLI
  rejects it (`change id must be kebab-case`).
- `9207d06^` tracks **zero** generated skill/command files. `rules: local-only`
  (givn/config.yaml) and `.gitignore` keep them out of git, so the pre-upgrade
  generated content is not recoverable from history.
- The AGENTS.md `givn-project` block is machine-owned, **unchanged by this
  upgrade** (`git diff 9207d06^ HEAD -- AGENTS.md` is empty). It carries only
  generic Givn text, no project rule.
- `migration.yaml`'s bundle label `0.8.0 -> 0.9.0` names the applied migration
  route; the installed contract is `0.8.4 -> 0.9.1` (`source_version` /
  `target_version` in the same file).
- Phase 1 step 3 correction: compare every old statement against **both** the
  served instruction (`givn instructions <id>`) and the tracked project-owned
  replacement (`givn/artifacts/<id>/instructions.md` or
  `givn/skills/<name>/SKILL.md.tmpl`). Text present in either place is not
  displaced; only text absent from both is. The templates are preserved by
  definition and must not be duplicated into `extensions:`.
- Phase 1 adds a scan of the **current** untracked generated files (the four
  target directories), so a stale or restored local copy cannot hide a
  displaced rule.

### Inventory (Phase 1 result)

Operator confirmation (2026-10-17): no hand edits to generated skill/command
files or the managed AGENTS.md block existed under 0.8.4.

Checked file list:

- Pre-upgrade revision `9207d06^` — `git ls-tree -r --name-only 9207d06^`
  filtered to `skills/givn-*/SKILL.md` and `commands/(givn|grill)-*.md`:
  0 files.
- `AGENTS.md` `givn-project` block — no diff across the upgrade; no
  project-specific statement.
- Current installed files — 15 skills × 4 targets (`.opencode`, `.agents`,
  `.claude`, `.omp`), 15 commands in each command-owning target
  (`.opencode`, `.omp`); `givn skills sync` is idempotent (empty diff).
- Tracked replacements — `givn/artifacts/{proposal,specs,design,design-review,tasks,review}/instructions.md`
  and 10 `givn/skills/*/SKILL.md.tmpl` files; unchanged across the upgrade
  (`git diff 9207d06^ HEAD -- givn/skills givn/artifacts` is empty).

Displaced statements: **none found**.

| Old file | Displaced statement | Classification | Target instruction id |
|---|---|---|---|
| — | none found | — | — |

No `extensions:` entry is added; `givn/config.yaml` is unchanged by this
change.

### Installed-file criterion

The bundle's "installed files carry only trigger and direction" cannot apply to
files backed by a tracked project-owned replacement: those files deliberately
carry the project's rules. The criterion is therefore scoped:

- Files **without** a replacement — 5 built-in skills (`givn-ideation`,
  `givn-explore`, `givn-reverse-engineer`, `givn-domain-modeling`,
  `givn-dev-principles`) and all 15 commands per command-owning target — carry
  trigger, direction, and no rule copy.
- Files **with** a replacement — the 10 template-backed skills — must equal the
  `givn skills sync` render (idempotent) and must carry no extension text.
- No generated file in any target carries `## Project extension`.

This preserves the proposal's out-of-scope rule: replacements stay
byte-for-byte; migrating them into `extensions:` is not this change.

### Exact evidence commands

```sh
# 1. Nothing displaced was tracked before the upgrade.
git ls-tree -r --name-only 9207d06^ \
  | grep -E '(skills/givn-[^/]+/SKILL\.md|commands/(givn|grill)-[^/]+\.md)$'
# expected: no output

# 2. The managed AGENTS.md block was not refreshed.
git diff 9207d06^ HEAD -- AGENTS.md
# expected: no output

# 3. Replacement-backed skills equal a fresh sync render (all four targets).
cp -a .opencode /tmp/oc.before && givn skills sync && diff -qr /tmp/oc.before .opencode
# expected: no output

# 4. No extension text leaked into a generated file.
grep -RIl 'Project extension' .opencode .agents .claude .omp givn/skills
# expected: no output

# 5. The repository suite stays green.
./scripts/givn-verify.sh

# 6. Traceability stays clean.
python3 scripts/givn-spec-trace.py
```

`givn/commands.yaml` resolves: `verify.command` is `./scripts/givn-verify.sh`
and `verify.e2e_command` is `./scripts/givn-verify-e2e.sh`; they are distinct
and executable.

### Verification binding and task evidence

This change has no product specification (`.givn-skip` = `specs`). No scenario
exists, so no binding tag is required and no `@check:` target is added. Tasks
are a maintenance checklist whose evidence is the exact command and its
observed output for each step above. The regression gate remains the existing
`verify.command` suite; the durable guard for future upgrades is the
`extensions:` mechanism itself.

### Architecture impact, blast radius, rollback

- No product module, host profile, option, flake input, secret, firewall rule,
  persistence path, or boot setting changes.
- Blast radius is developer tooling only: generated files under the four target
  directories (gitignored, local-only), the change directory, and the arc42
  marker. `givn/config.yaml` is unchanged.
- No dangerous area is touched (`boot.loader`, `networking`,
  `fileSystems`/disko, `environment.persistence`/impermanence, kernel, secret
  wiring), so deployment and rollback are N/A. Had an extension been recorded,
  rollback would be: remove the `extensions:` entry and run `givn skills sync`;
  no host deployment is involved.
- Persona / use case: `none` — developer tooling change with no user-visible
  system surface; no use-case ID applies.

### Recorded observations

- A future displaced rule routed to `archive`, `characterize`, `steps`, or
  `implement` would need an entry-point check: the installed skill templates for
  those steps do not all load their served instruction (the slash commands do).
  An extension there would be served by `givn instructions <id>` but not
  necessarily read by an agent following the installed skill. No rule was
  displaced now, so this is recorded for the next migration, not acted on.
- Release note for the change's revisions: "Migrate the project's Givn
  instructions to 0.9.1 without dropping project-specific rules."
