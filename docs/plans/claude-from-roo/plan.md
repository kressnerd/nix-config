# Plan: Port Roo Code Config into Claude Code

**Status:** COMPLETED  
**Date:** 2026-05-25

## Business Context

The repo had a mature Roo Code configuration (`.roomodes`, `.roo/rules*/`, `.roo/skills/`, `.roo/mcp.json`) with deep, nix-config-specific guidance. Claude Code has parallel structures but the existing pieces were thin compared to the Roo equivalents. This plan documents the migration.

## Acceptance Criteria

- [x] Five project-level subagents override the thin global ones with Roo-sourced depth
- [x] `CLAUDE.md` includes commit cadence, planning workflow, communication style, search etiquette
- [x] `.claude/settings.json` allowlists the nixos MCP tools (no per-call prompts)
- [x] No duplication of existing CLAUDE.md content (test-first, safety rules, architecture)
- [x] Skills untouched (already mirror Roo skills exactly)

## Changes Made

### New files

| File | Source |
|---|---|
| `.claude/agents/reviewer.md` | `.roo/rules-reviewer/00-03.md` |
| `.claude/agents/architect.md` | `.roo/rules-architect/00-02.md` |
| `.claude/agents/researcher.md` | `.roo/rules-project-research/*` |
| `.claude/agents/coder.md` | `.roo/rules-code/01-05.md` |
| `.claude/agents/user-story-writer.md` | `.roo/rules-user-story-creator/rules.md` |
| `.claude/settings.json` | `.roo/mcp.json` alwaysAllow list |

### Modified files

| File | What changed |
|---|---|
| `CLAUDE.md` | Appended: Communication Style, Commit Cadence, Planning & Agent Workflow, External Search Etiquette |

### Unchanged (already aligned)

- `.claude/skills/` — identical to `.roo/skills/`
- `.mcp.json` — identical to `.roo/mcp.json` server registration
- `.claude/settings.local.json` — user-local, not touched

### Dropped Roo content

- `.roo/rules-orchestrator/` — Roo dispatch model, no Claude equivalent
- `.roo/rules/03-code-mode-delegation.md` — same reason
- `.roo/rules-code/00-simple-tasks.md` — Roo-specific atomic-task framing

## Verification

```bash
# No Nix files changed — these should still pass
nix flake check --no-build
nix fmt . --check   # or: nix fmt . && git diff --exit-code

# Confirm new agent files exist
ls .claude/agents/
cat .claude/settings.json
```

Functional tests (manual):
- Spawn `reviewer` subagent → output should contain `## Review Report` with six-category structure
- Spawn `architect` subagent → output should include Phase 0 validation strategy
- Spawn `researcher` subagent → findings should include confidence levels
- Ask a question in chat → response should be in German, blunt style
