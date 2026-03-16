# MANDATORY RULE: User Story Tasks Must Be Delegated to User Story Creator

## Rule ID: ORCH-STORY-001

**Priority**: MANDATORY
**Applies to**: All Orchestrator actions involving user story creation, modification, or refinement

## Core Rule

The Orchestrator MUST NEVER write user stories itself.
ANY task involving user story creation, writing, modification, or refinement MUST be delegated to the `user-story-creator` mode via `new_task`.

## Prohibitions

The Orchestrator MUST NOT:

- Write user stories directly
- Draft, modify, or refine acceptance criteria itself
- Formulate Gherkin scenarios or BDD steps
- Paraphrase or rewrite stories without delegating to `user-story-creator`

## Obligations

The Orchestrator MUST:

- **Always** delegate story-related tasks to `user-story-creator` via `new_task`
- Pass **all relevant context** to the subtask (see Context Requirements below)
- Treat the `attempt_completion` result of the subtask as the final story artifact
- NOT post-process or alter the story content returned by `user-story-creator`

## Trigger Conditions

Delegate to `user-story-creator` when the user request involves ANY of:

- Creating new user stories
- Writing story descriptions or acceptance criteria
- Refining or splitting existing stories
- Converting requirements or GitLab issues into user stories
- Reformatting stories to follow BDD/Gherkin format

## Story Format Requirement

All user stories produced via this delegation MUST follow **BDD (Behavior-Driven Development)** format with **Gherkin-style scenarios**:

- Stories use the `As a / I want / So that` structure
- Acceptance criteria are expressed as `Given / When / Then` scenarios
- Each scenario covers exactly one behavior or edge case

The full story structure as defined in `rules-user-story-creator/rules.md` is required in addition to BDD/Gherkin acceptance criteria. This includes: Story Header (ID, title, status, priority, labels), Consequence Analysis, Story Owner, Affected Components Checklist, Context and Scope, Technical Details (DEV/QA notes), and Open Points table. Stories missing any mandatory section MUST be rejected and re-delegated.

## Context Requirements

When delegating to `user-story-creator`, the Orchestrator MUST pass:

| Context Item | Required | Notes |
|---|---|---|
| GitLab issue details (title, description, labels) | If available | Include raw issue content |
| Business requirements or goals | Yes | From user request or research results |
| Research results | If applicable | Output from prior `project-research` subtask |
| Relevant domain terminology | If available | From glossary or prior architect analysis |
| Target epic or feature scope | If known | To bound story granularity |
| Priority | Yes | High / Medium / Low — from user request or GitLab issue |
| Labels | If available | GitLab labels from the issue |
| Story Owner (name, department) | If known | From GitLab issue assignee or stakeholder info |
| Affected systems/services | If known | To populate Affected Components section |

## Delegation Message Template

```
TASK: Create user story for [feature/requirement]

CONTEXT:
- Business Goal: [What the user/stakeholder wants to achieve]
- GitLab Issue: [Issue title and description, if available]
- Scope: [Epic or feature boundary]
- Domain Terms: [Relevant glossary entries, if available]
- Research Results: [Summary of findings from project-research, if applicable]
- Priority: [High/Medium/Low]
- Labels: [Relevant labels, if available]
- Story Owner: [Name, Department — if known]
- Affected Systems: [Services or components impacted, if known]

REQUIREMENTS:
- Follow BDD format: As a / I want / So that
- Acceptance criteria as Gherkin scenarios: Given / When / Then
- [Any additional constraints specific to the story]
```

## Workflow Position

```
User request for story creation/refinement
  → Orchestrator collects context (may trigger project-research subtask first)
  → Orchestrator delegates to new_task(user-story-creator) with full context
  → user-story-creator returns completed story via attempt_completion
  → Orchestrator forwards result to user or uses it in downstream tasks
```

## Enforcement

- Any user story content authored directly by the Orchestrator is a rule violation
- Delegation without passing relevant context is a rule violation
- Stories not in BDD/Gherkin format returned from subtasks MUST be rejected and re-delegated with explicit format instructions
