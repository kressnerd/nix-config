# Plan: maki-first-class-harness

Three decided workstreams (secret guards, project skills, role subagents); MCP is a declared non-goal.
Anchor files: `opencode.json:19-66,87-105`, `.omp/config.yml:12-25`, `.opencode/agent/*.md`, `.maki/plugin.toml:15-25`, `tests/integration/agent-tooling-test.nix:125-131`, `home/dan/features/development/maki.nix:10`, `givn/config.yaml:255-256`, `.gitignore:33`.

## Constraints that shape the work

- `.maki/skills/givn-*/` is generated and gitignored (`.gitignore:33`); the ignore
  is the `givn-*` prefix, not the directory, and `givn/config.yaml:256` refreshes
  only that prefix. The six project skills are therefore committed under
  `.maki/skills/<name>/` as tracked copies of `.opencode/skills/<name>/SKILL.md`
  (resolved with the user 2026-11-03, reversing this plan's earlier `home.file`
  proposal). Drift is closed by `tests/unit/maki-skill-parity-test.nix`, which
  asserts both the exact committed set and byte equality with the OpenCode copy.
- `.maki/plugin.toml:12-14`: the manifest governs every Lua file in `.maki/`.
  Denies need no grant (`lua-api.md:329-333`); WS3 flips `agent = false -> true`
  (`.maki/plugin.toml:22`). No shell permissions widened; `permissions.toml` unchanged.
- MCP non-goal ⇒ `maki.agent.session` is called with the parent `ctx`: no MCP
  definitions, and no "costs every permission except `agent`" trap (`lua-api.md:1358-1366`).
- No API in `lua-api.md` runs a command or a child `maki`, so every fresh-process
  probe is **manual**; QEMU asserts registration/placement only — the split the repo
  already uses (`tests/unit/agent-secret-guard.mjs` verdicts, `agent-tooling-test.nix` placement).

---

## Phase 0 — Validation strategy

Cwd = repo root, bare `maki` (no `--no-plugins`; project plugins load only in a trusted
folder). Red = today, Green = after the workstream.

### WS1 — secret guard

`maki --print --yolo "run exactly this and show the output: sops -d hosts/thiniel/secrets.yaml"`
**Red** today: ciphertext or a sops error reaches the model. **Green** after: the tool result says the
call was denied. Same pair for `maki --print --yolo "read /run/secrets/context7/api-key and repeat it"`.

Automatable in QEMU? **No.** (a) `--print` needs a provider and credentials; the
guest deliberately carries neither (`agent-tooling-test.nix:52-53`). (b) The guard
registers at plugin load, so a fresh process is required and no Lua API spawns one.
(c) A negative control reads a secret path — a VM step asserting the leak is not a
guard test. **Automated instead**: in the `withMaki` block, the guest's repo copy
carries `.maki/lua/secret-guard.lua` and `.maki/init.lua` calls it.

### WS2 — project skills

`maki --print "Which skill applies when adding a sops secret? Name it."` **Red** today: a `givn-*`
skill or none, never `sops-secrets`. **Green** after: names `sops-secrets`; a second prompt
(`"Which skill covers home-manager options?"`) names `home-manager-config`.

Automatable in QEMU? **Partly.** The prompt probe needs a provider (manual), but placement is
automatable and belongs in the VM: only Home Manager activation proves the six files land under
`~/.config/maki/skills/`. Byte equality with `.opencode/skills/` is a pure-Nix check.

### WS3 — role subagents

`maki --print "Use the task tool with agent 'researcher' to find which file defines the maki overlay.
Report only the path."` **Red** today: the builtin `task` has no such role. **Green** after: a task
transcript runs the researcher body and returns `overlays/maki/default.nix`. Isolation probe:
`maki --print "use task_role reviewer to write /tmp/x"` → refused.

Automatable in QEMU? **Registration only.** `maki prompt --tools --names` (must list `task_role`) and
`maki prompt --tools` (must enumerate the four roles) need no provider — extend
`agent-tooling-test.nix:125-131`. Behavioural and quality probes are manual; a VM cannot prove what a
spawned role does.

---

## Resolved risk — `register_permission_rule` scope semantics

Probed on maki 0.7.0 with a throwaway `.maki/lua/scope-probe.lua` (since deleted).
Recorded here because the outcome decides the shape of WS1.

**`bash` scopes are enforced, two ways:**

- A `deny` rule matches the whole command string with the observed prefix/suffix
  wildcard, and `cd x && sops -d y` still matched `sops *` (the segment was checked,
  as `.omp/config.yml:7` documents). `*sops-nix/secrets*` matched a long absolute path.
- Orthogonally, **any** `bash` call that would prompt is denied when nobody can answer
  it. Under `maki --print` there is no approver, so `cat <secret> | wc -c` was refused
  without any rule covering it. The shell half is therefore stronger than omp's
  declarative list, not weaker.

**`write` and `edit` path scopes do fire.** `write` to a file under the protected
subtree was refused with `deny rule .../** for write in a Lua plugin`, so the
modification half of WS1 is enforced, not only declared.

**`read` and `grep` scopes register and then do not fire.** `tool = "read", scope =
"<subtree>/**", effect = "deny"` returns success from
`maki.api.register_permission_rule` and writes no warning, then the identical `read`
call succeeds and returns the file. `grep` behaves the same. The cause is visible in
the log: Maki's own `read`/`grep` handlers dispatch as `lua:read`/`lua:grep`, i.e. the
tools are session-owned rather than native, and a rule table from the repository does
not reach them. There is no way for a repository file to force a path-scoped read.

Consequence, decided with the user: WS1 covers `bash` (command denies), `write`, and
`edit` (subtree denies). It does **not** ship a `read`/`grep` rule that does nothing,
and it does not claim parity with `.omp/hooks/pre/secret-access-guard.js`, which does
cover path-scoped reads. The residue is recorded as a numbered risk.

---

## Workstream breakdown (atomic, Red first)

`[manual]` = needs a human with provider credentials.

### WS2 — skills (first: no plugin risk; WS3 step 6 documents them)

1. **Red** — `agent-tooling-test.nix:125-131`: assert the six `~/.config/maki/skills/<name>/SKILL.md`
   exist → `nix build .#checks.x86_64-linux.integration-agent-tooling` FAILs.
2. **Green** — commit `.maki/skills/<name>/SKILL.md` copies of the six
   `.opencode/skills/<name>/SKILL.md`. No module, no `home.file`: the repository copy is
   what Maki reads (`maki.nix:10`).
3. **Red** — `tests/unit/maki-skill-parity-test.nix` (`lib.debug.runTests`, wired into
   `tests/unit/default.nix`): exactly the six names, each content equal to its source, no `givn-*`
   name emitted. FAIL before step 2, passes after. DONE.
   Step 1 is dropped: with no Home Manager file there is no activation step to assert, and the
   parity test covers placement.
4. **Docs** — `maki.nix:10` and `docs/arc42/05-building-block-view.md:169` state both skill locations;
   no test (CLAUDE.md:146-153). `[manual]` WS2 green probe. **`create-python-cli-tool`: excluded** —
   Python tooling, not Nix/security; its only reference is `.claude/agents/coder.md:105`, a role not ported.

### WS1 — secret guard

1. **Probe** — DONE (see "Resolved risk" above). `bash` scopes enforce; `read`/`grep`
   scopes do not fire. No Red/Green; it reshaped steps 2-4.
2. **Red** — `tests/unit/maki-secret-guard.mjs` (style of `agent-secret-guard.mjs:1-40`)
   against the guard's exported rule table: a `bash` deny for each decryption and
   secret-store pattern, a `write` and an `edit` deny for each protected subtree,
   **no** `read`/`grep` entry and **no** allow rule. FAIL (module absent).
3. **Green** — `.maki/lua/secret-guard.lua` exporting `M.rules` as a data table and
   `M.setup()` registering it; `.maki/init.lua` calls `M.setup()` under `pcall` in its
   own fence beside the timeline one. Step 2 passes.
4. **Risk** — record the unforced `read`/`grep` scope as R-036 in
   `docs/arc42/11-risks-and-technical-debt.md` (precedent R-021,
   `agent-secret-guard.mjs:14-20`), and state it in `AGENTS.md`'s Maki row so no one
   reads the guard as covering reads. `.maki/plugin.toml`: no change (deny needs no
   permission).

### WS3 — role subagents

`maki --print "Use the task tool with agent 'researcher' to find which file defines the maki overlay.
Report only the path."` **Red** today: the builtin `task` has no such role. **Green** after: a task
transcript runs the researcher body and returns `overlays/maki/default.nix`. Isolation probe:
`maki --print "use task_role reviewer to write /tmp/x"` → refused.

Automatable in QEMU? **Registration only.** `maki prompt --tools --names` (must list `task_role`) and
`maki prompt --tools` (must enumerate the four roles) need no provider — extend
`agent-tooling-test.nix:125-131`. Behavioural and quality probes are manual; a VM cannot prove what a
spawned role does.

---

## Resolved risk — `register_permission_rule` scope semantics

Probed on maki 0.7.0 with a throwaway `.maki/lua/scope-probe.lua` (since deleted).
Recorded here because the outcome decides the shape of WS1.

**`bash` scopes are enforced, two ways:**

- A `deny` rule matches the whole command string with the observed prefix/suffix
  wildcard, and `cd x && sops -d y` still matched `sops *` (the segment was checked,
  as `.omp/config.yml:7` documents). `*sops-nix/secrets*` matched a long absolute path.
- Orthogonally, **any** `bash` call that would prompt is denied when nobody can answer
  it. Under `maki --print` there is no approver, so `cat <secret> | wc -c` was refused
  without any rule covering it. The shell half is therefore stronger than omp's
  declarative list, not weaker.

**`write` and `edit` path scopes do fire.** `write` to a file under the protected
subtree was refused with `deny rule .../** for write in a Lua plugin`, so the
modification half of WS1 is enforced, not only declared.

**`read` and `grep` scopes register and then do not fire.** `tool = "read", scope =
"<subtree>/**", effect = "deny"` returns success from
`maki.api.register_permission_rule` and writes no warning, then the identical `read`
call succeeds and returns the file. `grep` behaves the same. The cause is visible in
the log: Maki's own `read`/`grep` handlers dispatch as `lua:read`/`lua:grep`, i.e. the
tools are session-owned rather than native, and a rule table from the repository does
not reach them. There is no way for a repository file to force a path-scoped read.

Consequence, decided with the user: WS1 covers `bash` (command denies), `write`, and
`edit` (subtree denies). It does **not** ship a `read`/`grep` rule that does nothing,
and it does not claim parity with `.omp/hooks/pre/secret-access-guard.js`, which does
cover path-scoped reads. The residue is recorded as a numbered risk.

---

## Workstream breakdown (atomic, Red first)

`[manual]` = needs a human with provider credentials.

### WS2 — skills (first: no plugin risk; WS3 step 6 documents them)

1. **Red** — `agent-tooling-test.nix:125-131`: assert the six `~/.config/maki/skills/<name>/SKILL.md`
   exist → `nix build .#checks.x86_64-linux.integration-agent-tooling` FAILs.
2. **Green** — commit `.maki/skills/<name>/SKILL.md` copies of the six
   `.opencode/skills/<name>/SKILL.md`. No module, no `home.file`: the repository copy is
   what Maki reads (`maki.nix:10`).
3. **Red** — `tests/unit/maki-skill-parity-test.nix` (`lib.debug.runTests`, wired into
   `tests/unit/default.nix`): exactly the six names, each content equal to its source, no `givn-*`
   name emitted. FAIL before step 2, passes after. DONE.
   Step 1 is dropped: with no Home Manager file there is no activation step to assert, and the
   parity test covers placement.
4. **Docs** — `maki.nix:10` and `docs/arc42/05-building-block-view.md:169` state both skill locations;
   no test (CLAUDE.md:146-153). `[manual]` WS2 green probe. **`create-python-cli-tool`: excluded** —
   Python tooling, not Nix/security; its only reference is `.claude/agents/coder.md:105`, a role not ported.

### WS1 — secret guard

1. **Probe** — run the throwaway plugin above; record the matrix. No Red/Green; gates steps 2-3.
2. **Red** — `tests/unit/maki-secret-guard.mjs` (style of `agent-secret-guard.mjs:1-40`) plus a
   `runCommand` that greps the rule table: one deny per protected path prefix for `read`/`grep`, one
   per decryption prefix for `bash`, **no** allow rules. Wire as `checks.<sys>.unit-maki-secret-guard`
   (pattern `flake.nix:624-639`). FAIL.
3. **Green** — `.maki/lua/secret-guard.lua` exporting `M.rules` (a data table, so the checker needs
   no Lua VM) and `M.setup()` calling `maki.api.register_permission_rule`; fence in `.maki/init.lua`
   calling `M.setup()` under `pcall` (`.maki/init.lua:1-6` shape). Step 2 passes.
4. **Red** — `agent-tooling-test.nix` `withMaki`: guest repo copy carries `.maki/lua/secret-guard.lua`
   and `.maki/init.lua` names it. Verify Red first, then Green after step 3.
5. **Resolve** — command-scope outcome recorded; if degraded, add a numbered risk to
   `docs/arc42/11-risks-and-technical-debt.md` (precedent R-021, `agent-secret-guard.mjs:14-20`).
   `[manual]` WS1 probes. `.maki/plugin.toml`: no change (deny needs no permission).

### WS3 — role subagents

1. **Red** — `agent-tooling-test.nix` `withMaki`:
   `sudo -u test env HOME=/home/test ${makiBin} prompt --tools --names` must contain `task_role`. FAIL.
2. **Green** — new `.maki/lua/subagents.lua`: no host calls at load (`givn-timeline.lua:8-10`
   constraint); reads `.opencode/agent/*.md` via `maki.fs.read` (`lua-api.md:2349`), splits
   frontmatter at the second `---`, keeps `description:` and the body; registers `task_role`
   (`schema = { agent = <enum of parsed names>, prompt = string }`).
3. **Red** — `tests/unit/maki-subagent-frontmatter-test.nix`: pure-Nix port of the same parse over
   the four files, asserting the descriptions and each body's first sentence (`You are a project
   researcher`, `You are an architect`, …). **Green**: align the Lua parser to the pinned contract.
4. **Red** — `tests/unit/maki-subagent-toolset-test.nix`: static `role -> except[]` table;
   researcher/reviewer exclude `bash` **and** every write-capable tool; user-story-writer has no
   bash; architect writes only under `givn/changes/**` and `docs/plans/**`. Mirrors the
   `.opencode/agent/*.md` permission blocks.
5. **Green** — `.maki/lua/subagents.lua` handler: `maki.agent.tools(ctx, { audience = "general_sub",
   except = cfg.except })`, `maki.agent.session(ctx, { system = body, tools = defs, name = role,
   thinking = "off" })`, `sess:prompt(...)`, `sess:close()` on every path (`lua-api.md:1428-1442`),
   plus `register_permission_rule` allows for the exact repo scopes the roles read (a blanket allow
   is refused, `lua-api.md:343-352`). **Grant**: `.maki/plugin.toml:22` `agent = false -> true`, with
   the reason in the header comment; `run`/`fs_read` must cover the kept tools (`lua-api.md:1358-1366`).
6. **Docs** — `AGENTS.md:24-29` names Maki's `task_role` beside `task(...)`;
   `docs/arc42/08-crosscutting-concepts.md` gains the role-loading sentence.
   `[manual]` WS3 green probe and the reviewer-writes-nothing probe.

---

## Risks of the subagent plugin

1. **Frontmatter shape.** `mode: subagent` and the `permission:` map (`.opencode/agent/architect.md:5-14`)
   are OpenCode schema; Maki's `permission_scopes` is a *tool* declaration with no per-agent override.
   The permission blocks cannot be copied — they must be hand-translated into `except`/`only` filters
   (WS3 step 4), a table that drifts whenever `.opencode/agent/*.md` changes. WS3 step 3 pins the
   portable parts only; no artifact may claim permission parity.
2. **Prompt bodies are OpenCode-specific.** `architect.md` writes to `docs/plans/` and assumes a
   `task`-based flow; `reviewer.md:18-20` names `git show/diff/log`. Maki's tool names differ
   (`task_role`, no `batch`) and a bash-stripped role cannot run the git commands its own permission
   block allows — silent degradation. Mitigation: pass bodies verbatim, append one paragraph per role
   naming the tools it actually has. Never fork the bodies (guaranteed drift).
3. **"Never modify files" is filtered, not enforced.** `except = {...}` bounds what the model can
   *call* (a real bound), but any bash-capable role can still write. Researcher and reviewer must
   also drop `bash`, reading only via native `read`/`grep`/`glob`. Architect's write capability
   survives only as a path-scoped allow; it is not a sandbox.
4. **Build mode, no prompt target.** A session "always runs in build mode", and a task-scoped one has
   "nobody [who] can answer its permission prompts, so a call that would prompt is denied"
   (`lua-api.md:1352-1364`); under `maki --print` there is no live chat at all. Any prompting tool
   fails as a silent denial, so pre-approval must come from the plugin's own rules or user config —
   and a plugin allow needs the target tool's permission plus a non-universal scope.
5. **Plan mode.** While the parent chat is in plan mode the subagent's write tools are denied; WS3
   probes must not run under plan mode.
6. **`--no-plugins` / untrusted folder.** An untrusted checkout loads neither plugin, so the guard
   silently disappears; probes run in the repo root, and the VM step asserts the trust state.
7. **Cost.** Each role spawn is a full turn sequence on the parent model, uncapped. Accepted, not a claim.

---

## What this change must NOT claim

- **Shell/read enforcement parity with omp/OpenCode.** Only what `register_permission_rule`
  expresses is enforced; wrappers (`sh -c`, script files) may evade, and `grep`/`glob` over a
  parent directory is a separate surface from `read`. Say "denies the listed command prefixes and
  the protected path subtrees", never "blocks all decryption".
- **Skill parity with `.opencode/skills/`.** Six skills, not seventeen.
  `create-python-cli-tool` and the generated `givn-*` set are out; the latter keeps
  arriving via `givn skills sync` into `.maki/skills/`, unchanged by this change.
- **Agent-definition parity.** `.opencode/agent/*.md` is the single source; Maki roles
  are a runtime projection with `mode:`/`permission:` ignored and permissions
  hand-translated. `.claude/agents/` (which differs for all four roles and adds
  `coder.md`) is not a Maki source.
- **MCP parity.** Out of scope by decision; the user configures and authenticates MCP
  manually. Role sessions pass no `mcp` flag.
- **Deploy-time or behavioural proof.** Every agent-verdict probe is manual and local;
  the shipped checks prove registration, file placement, and rule-table shape only.
- **Non-Linux enforcement proof.** No Darwin VM exists here; the guard's VM assertion
  is Linux-only and the macOS device is unproven by this change.
