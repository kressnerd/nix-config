# Tasks — migrate-0-8-4-to-0-9-1

Maintenance checklist for a change with no product specification
(`.givn-skip` = `specs`). There is no observable host/system behaviour to bind
a `@check:` target to, so no scenario-shaped RED/GREEN/REFACTOR loop applies.
Each task records the exact command and its observed output as evidence, as
decided in the design review (Q3) and recorded in `design.md` under
"Verification binding and task evidence".

Release note for the change's revisions: **Migrate the project's Givn
instructions to 0.9.1 without dropping project-specific rules.**

## Task 1 — Preflight

- [x] **1.1** Confirm the installed contract and the change directory.
  - Command: `grep -n 'givn_config_version' givn/config.yaml`
  - Expected: `"0.9.1"`
  - Evidence:
    ```
    $ grep -n 'givn_config_version' givn/config.yaml
    16:givn_config_version: "0.9.1"
    ```
- [x] **1.2** Confirm the verify commands resolve and are distinct.
  - Command: `grep -n 'command:' givn/commands.yaml`
  - Expected: `verify.command` = `./scripts/givn-verify.sh`,
    `verify.e2e_command` = `./scripts/givn-verify-e2e.sh`; not identical.
  - Evidence:
    ```
    $ grep -n 'command:' givn/commands.yaml
    20:  command: "./scripts/givn-verify.sh"
    26:  e2e_command: "./scripts/givn-verify-e2e.sh"
    ```
- [x] **1.3** Confirm the pre-upgrade revision exists and the checkout is clean
  before the first edit.
  - Command: `git rev-parse 9207d06^ && git status --porcelain`
  - Expected: a hash; no output from `git status` before the first edit.
  - Evidence:
    ```
    $ git rev-parse 9207d06^
    a5543aaa47a8d561403b29185c8c37698f8de446
    $ git status --porcelain    # at session start, before any edit: no output
    $ git status --porcelain    # now: only this change's artifacts
     M givn/changes/migrate-0-8-4-to-0-9-1/design.md
    ?? givn/changes/migrate-0-8-4-to-0-9-1/arc42.md
    ?? givn/changes/migrate-0-8-4-to-0-9-1/design-review.md
    ?? givn/changes/migrate-0-8-4-to-0-9-1/tasks.md
    ```

## Task 2 — Inventory the displaced project rules

- [x] **2.1** Scan the pre-upgrade revision for tracked generated rule files.
  - Command:
    ```sh
    git ls-tree -r --name-only 9207d06^ \
      | grep -E '(skills/givn-[^/]+/SKILL\.md|commands/(givn|grill)-[^/]+\.md)$'
    ```
  - Expected: no output (`rules: local-only`).
  - Evidence:
    ```
    $ git ls-tree -r --name-only 9207d06^ | grep -E '(skills/givn-[^/]+/SKILL\.md|commands/(givn|grill)-[^/]+\.md)$'
    [exit=1, no output]
    ```
- [x] **2.2** Compare the managed project block of the agent guide (AGENTS.md,
  the fenced `givn-project` block) across the upgrade.
  - Command: `git diff 9207d06^ HEAD -- AGENTS.md`
  - Expected: no output.
  - Evidence:
    ```
    $ git diff 9207d06^ HEAD -- AGENTS.md
    [diff_exit=0, no output]
    ```
- [x] **2.3** Scan the current installed files in every configured target for
  a statement absent from both the served instruction and the tracked
  replacement.
  - Command: `givn skills sync` then inspect `givn instructions <id>` for each
    changed file; compare against `givn/artifacts/<id>/instructions.md` and
    `givn/skills/<name>/SKILL.md.tmpl`.
  - Expected: no statement absent from both; no hand-edited generated file.
  - Evidence:
    ```
    $ givn skills sync && diff -qr /tmp/oc.before .opencode
    [no output — every generated file equals the current sync render]
    $ for f in givn/skills/*/SKILL.md.tmpl; do n=$(basename "$(dirname "$f")"); \
        echo "$n $(wc -l < "$f") -> $(wc -l < ".opencode/skills/$n/SKILL.md")"; done
    givn-archive 146 -> 90
    givn-characterize 102 -> 102
    givn-design 148 -> 148
    givn-design-review 153 -> 147
    givn-implement 200 -> 200
    givn-propose 56 -> 56
    givn-review 202 -> 196
    givn-spec 80 -> 80
    givn-steps 283 -> 283
    givn-tasks 184 -> 182
    ```
    The ten replacement-backed skills render solely from the tracked templates
    (placeholder substitution only; line-count deltas come from
    `{{CHANGE_ID}}` / `{{VERIFY_COMMAND}}` expansion). The five built-in skills
    are 10–16 lines of trigger plus direction; the 15 commands per
    command-owning target trigger the served instruction. No statement exists
    that both the served instruction and the tracked replacement lack.
- [x] **2.4** Record the inventory outcome in `design.md`.
  - Expected: the inventory table with the "none found" row, the checked file
    list, and the operator confirmation (already recorded during hardening).
  - Evidence:
    ```
    $ grep -n 'none found' givn/changes/migrate-0-8-4-to-0-9-1/design.md
    235:Displaced statements: **none found**.
    239:| — | none found | — | — |
    ```

## Task 3 — Verify the installed files and the extension boundary

- [x] **3.1** Prove the replacement-backed skills equal a fresh sync render.
  - Command:
    ```sh
    cp -a .opencode /tmp/oc.before && givn skills sync && diff -qr /tmp/oc.before .opencode
    ```
  - Expected: no output (idempotent render).
  - Evidence:
    ```
    $ rm -rf /tmp/oc.before; cp -a .opencode /tmp/oc.before; givn skills sync; diff -qr /tmp/oc.before .opencode
    [sync_diff_exit=0, no output]
    ```
- [x] **3.2** Prove files without a project-owned replacement carry only
  trigger and direction.
  - Command:
    ```sh
    for f in .opencode/skills/givn-{ideation,explore,reverse-engineer,domain-modeling,dev-principles}/SKILL.md; do
      wc -l "$f"; grep -c 'givn instructions' "$f"; done
    ```
  - Expected: 10–16 lines each and at least one direction to
    `givn instructions <id>`; commands likewise.
  - Evidence:
    ```
    .opencode/skills/givn-ideation/SKILL.md lines=12 directions=3
    .opencode/skills/givn-explore/SKILL.md lines=10 directions=2
    .opencode/skills/givn-reverse-engineer/SKILL.md lines=12 directions=3
    .opencode/skills/givn-domain-modeling/SKILL.md lines=16 directions=2
    .opencode/skills/givn-dev-principles/SKILL.md lines=10 directions=2
    $ head -9 .opencode/commands/givn-archive.md
    ...
    Archive completed change `<change-id>`. Load the step's rules with `givn instructions archive` and follow them; this file only triggers the step.
    ```
- [x] **3.3** Prove no extension text leaked into a generated file and that
  the project-rules map is unchanged.
  - Command:
    ```sh
    grep -RIl 'Project extension' .opencode .agents .claude .omp givn/skills
    grep -n '^extensions:' givn/config.yaml
    ```
  - Expected: no output from the first; no `extensions:` key in the second
    (no rule was displaced).
  - Evidence:
    ```
    $ grep -RIl 'Project extension' .opencode .agents .claude .omp givn/skills
    [grep_exit=1, no output]
    $ grep -n '^extensions:' givn/config.yaml
    [cfg_exit=1, no output]
    ```
- [x] **3.4** Record the extension-serving check as not applicable.
  - Expected: `design.md` states no instruction is extended, so the
    `## Project extension` serve check has no subject. No command is run; the
    statement is the evidence.
  - Evidence:
    ```
    $ grep -n 'entry is added' givn/changes/migrate-0-8-4-to-0-9-1/design.md
    241:No `extensions:` entry is added; `givn/config.yaml` is unchanged by this
    ```

## Task 4 — Verify and commit

- [x] **4.1** Run the repository suite (non-@e2e scope).
  - Command: `./scripts/givn-verify.sh`
  - Expected: exit 0, `[givn-verify] OK`.
  - Evidence:
    ```
    $ ./scripts/givn-verify.sh
    [givn-verify] system=x86_64-linux
    [givn-verify] 1/5 spec traceability
    givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)
    [givn-verify] 2/5 flake evaluation (all outputs, current system)
    all checks passed!
    [givn-verify] 3/5 build non-VM checks (unit + lint)
    [givn-verify] 4/5 host configuration assertions (tests/assertions)
    [givn-verify]   nixosConfiguration.adlerkopf
    [givn-verify]   nixosConfiguration.cupix001
    [givn-verify]   nixosConfiguration.nixos-vm-minimal
    [givn-verify]   nixosConfiguration.thiniel
    [givn-verify]   darwinConfiguration.J6G6Y9JK7L
    [givn-verify] 5/5 python test suite (scripts/)
    256 passed in 7.99s
    [givn-verify] OK
    [verify_exit=0]
    ```
- [x] **4.2** Run the traceability gate.
  - Command: `python3 scripts/givn-spec-trace.py`
  - Expected: exit 0, `0 finding(s)`.
  - Evidence:
    ```
    $ python3 scripts/givn-spec-trace.py
    [warn] integration check 'integration-adlerkopf' is not referenced by any scenario
    [warn] integration check 'integration-vm-minimal-ssh' is not referenced by any scenario
    givn-spec-trace: 29 scenario(s) across 6 feature file(s), 0 finding(s)
    [trace_exit=0]
    ```
- [x] **4.3** Commit the maintenance change with the release note as subject.
  - Command:
    ```sh
    givn commit -m "chore(givn): Migrate the project's Givn instructions to 0.9.1 without dropping project-specific rules."
    ```
  - Expected: one revision touching the change artifacts (design, design
    review, arc42 marker, tasks); record the hash.
  - Evidence:
    ```
    $ givn commit -m "chore(givn): Migrate the project's Givn instructions to 0.9.1 without dropping project-specific rules."
    [14:41:20] committed revision on the Git backend
    [commit_exit=0]
    $ git log -1 --format='%H %s'
    971670a9eef5449d63dc85af6261eaa95ce3302b chore(givn): Migrate the project's Givn instructions to 0.9.1 without dropping project-specific rules.
    ```
  - Revision: `971670a9eef5449d63dc85af6261eaa95ce3302b`

## Task 5 — Close the gates

- [ ] **5.1** Complete the review artifact and its hooks.
  - Command: `givn status --change migrate-0-8-4-to-0-9-1`, then the review
    step; `givn check review` must pass.
  - Evidence:
    ```
    (paste the review check output)
    ```
- [ ] **5.2** Archive through the normal gates.
  - Command: `givn archive migrate-0-8-4-to-0-9-1`
  - Evidence:
    ```
    (paste the archive output)
    ```

## Completion rule

All boxes checked, each with pasted command output, and the recorded revision.
The @e2e scope is not applicable: no `@e2e` scenario exists in this change.
