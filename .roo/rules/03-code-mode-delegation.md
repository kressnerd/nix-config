# Code Mode Delegation

## Subtask Hierarchy

Code Mode is EXCLUSIVELY invoked via subtasks (`new_task`) by the **Orchestrator**:

```
Orchestrator → Code Mode (via new_task)
```

- **ONLY the Orchestrator** starts Code Mode subtasks
- The **Architect** plans the tasks, the **Orchestrator** delegates them as subtasks to Code Mode
- Code Mode executes the task and reports results via `attempt_completion`
- No other mode starts subtasks — only the Orchestrator

### Why Subtasks Instead of Mode Switch?

- Clean, bounded context per task
- Clear result reporting via `attempt_completion`
- Traceable task chain
- Orchestrator maintains the overall overview

## Principle

Code Mode is optimized for **execution**, not **thinking**. It receives explicit, atomic tasks.

## When to Switch to Code Mode

Code Mode is suitable for **explicit, atomic tasks**.

### Suitable Tasks (→ Code Mode)

- ✅ "Add package `ripgrep` to `home/dan/features/cli/shell-utils.nix`"
- ✅ "Create feature module `home/dan/features/cli/tmux.nix` with tmux configuration"
- ✅ "Enable `services.headscale` in `hosts/cupix001/headscale.nix`"
- ✅ "Add firewall rule for port 443 in `hosts/cupix001/firewall.nix`"
- ✅ "Import new feature `./features/cli/tmux.nix` in `home/dan/thiniel.nix`"
- ✅ "Run `nix flake check` and report results"

### Unsuitable Tasks (→ stay in Orchestrator and delegate to suitable mode)

- ❌ "Set up a new server" (too vague — decompose first in Architect Mode)
- ❌ "Decide between Hyprland and Sway" (decision — Architect Mode)
- ❌ "Research how nix-darwin services work" (research — Project Research Mode)
- ❌ "Plan the migration to impermanence" (planning — Architect Mode)
- ❌ "Compare networking options" (analysis — Architect Mode)

## Task Routing Criteria

### Route to Code Mode when ALL apply:

- [ ] Task is atomic (single file or tightly coupled set of files)
- [ ] Location is precisely specified (file path)
- [ ] Success criterion is verifiable (`nix flake check`, build test)
- [ ] No design decisions required

### Stay in Architect Mode when ANY applies:

- [ ] Task requires decomposition
- [ ] Multiple valid approaches exist
- [ ] Trade-off decision needed
- [ ] Research or analysis required
- [ ] Task specification is ambiguous

## Handoff Protocol

When delegating to Code Mode, transfer the following state:

### Required Context

1. **Goal**: What should be achieved (one sentence)
2. **Location**: Exact file path(s)
3. **Specification**: What to add/modify/remove
4. **Verification**: How to verify success (`nix flake check`, `nixos-rebuild build --flake .#hostname`)
5. **Relevant Context**: Max 5 lines of information needed to understand the task

### Handoff Message Template

```
TASK: [Create|Modify|Delete|Run] [target]
LOCATION: [path/to/file.nix]
SPEC: [What to add/change/remove]
VERIFY: [Validation command]
CONTEXT:
- [Relevant fact 1]
- [Relevant fact 2]
```

### Example

```
TASK: Add tmux configuration as a new feature module
LOCATION: home/dan/features/cli/tmux.nix
SPEC: Create HM module with programs.tmux.enable, set prefix to C-a, enable mouse
VERIFY: nix flake check
CONTEXT:
- Follow pattern from home/dan/features/cli/vim.nix
- Import will be wired in a separate task
```

## Return Protocol

After task completion, Code Mode MUST return:

### Success Response

```
STATUS: DONE
RESULT: [What was created/modified/deleted]
FILES: [List of changed files]
VALIDATION:
- flake check: PASS/FAIL
- build (<hostname>): PASS/FAIL/SKIPPED
QUALITY:
- deadnix: PASS/FAIL
- statix: PASS/FAIL
- format: PASS/FAIL
NEXT: [Suggested next step or NONE]
```

### Failure Response

```
STATUS: BLOCKED
REASON: [Why the task could not be completed]
ATTEMPTED: [What was tried]
NEED: [What information or decision is required]
```

### Partial Completion

```
STATUS: PARTIAL
COMPLETED: [What was done]
REMAINING: [What is still open]
BLOCKER: [What prevents completion]
```

## Nix Workflow — EDIT → CHECK → FORMAT → APPLY

Code Mode executes the Nix workflow autonomously when successful. Returns to Orchestrator only on completion or blocker.

### Execution Flow

```
EDIT → [nix flake check?] → FORMAT/LINT → [clean?] → DONE
          ↓ fail                 ↓ fail
        BLOCKED               BLOCKED
```

### Phase Definitions

1. **EDIT**: Make the specified change to `.nix` file(s)
   - Self-check: File is syntactically valid Nix

2. **CHECK**: Validate the change
   - Run: `nix flake check`
   - Optional: `nixos-rebuild build --flake .#<hostname>` if a specific host was modified
   - If check fails: attempt fix (max 2 iterations), then BLOCKED

3. **FORMAT/LINT**: Ensure code quality
   - Run: `nixfmt` or `alejandra` on changed files
   - Run: `statix check` and `deadnix` on changed files
   - Auto-fix safe issues with `statix fix`
   - If issues remain after auto-fix: BLOCKED

### Return Conditions

| Condition | Action |
|-----------|--------|
| All phases complete successfully | Return DONE with summary |
| Any phase fails self-check | Return BLOCKED with details |
| Ambiguity in specification | Return BLOCKED with specific question |
| Build error after 2 fix attempts | Return BLOCKED with error |

### Delegation Format for Nix Task

When delegating a Nix task, specify:

```
NIX TASK: [Feature/change to implement]
LOCATION: [target file(s)]
SPEC: [Implementation requirements]
VERIFY: [Validation command]
```

### Example

Delegation:

```
NIX TASK: Add WireGuard interface configuration
LOCATION: hosts/cupix001/default.nix
SPEC: Add networking.wg-quick.interfaces.wg0 with listenPort 51820, privateKeyFile from sops
VERIFY: nix flake check && nixos-rebuild build --flake .#cupix001
```

Return:

```
STATUS: DONE
RESULT: Added WireGuard wg0 interface configuration
FILES:
- hosts/cupix001/default.nix (modified)
VALIDATION:
- flake check: PASS
- build (cupix001): PASS
QUALITY:
- deadnix: PASS
- statix: PASS
- format: PASS
NEXT: Deploy with nixos-rebuild switch, add firewall rule for UDP 51820
```

## Fallback Mechanisms

### On Build Error

1. Code Mode reads the error message and attempts fix (max 2 iterations)
2. If unresolved: Return BLOCKED with full error output
3. Orchestrator escalates to Architect Mode for analysis

### On Option Path Error

1. Code Mode queries MCP nixos server for correct option path
2. If MCP unavailable: Return BLOCKED with the attempted option path

### On Ambiguity

1. Code Mode does NOT guess
2. Returns BLOCKED with specific question
3. Orchestrator clarifies and re-delegates

### Escalation Threshold

After 3 failed attempts at same task: Escalate to user with full context.

## Clarification: Import Wiring

When creating a new feature module, the **import statement** in the host profile (e.g., `home/dan/thiniel.nix`) should be handled as a **separate atomic task** unless explicitly included in the current task specification. This prevents accidental side effects.
