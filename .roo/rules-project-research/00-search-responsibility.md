# RULE: Project Research as Primary Research Mode

## Rule ID: PROJ-RES-001

**Priority**: MANDATORY
**Applies to**: All actions in Project Research Mode

## Core Rule

Project Research is the PRIMARY mode for all research and search tasks within and outside the codebase.

## Responsibilities

Project Research is responsible for:

- **Codebase search and analysis**: grep, file search, code navigation, pattern recognition
- **MCP tool usage**: GitLab, Search, Fetch, and other MCP tools
- **Technical research**: External sources, documentation, best practices
- **Documentation analysis**: Contents in `docs/`, and other documentation directories
- **Analyzing implementation patterns**: Identifying existing patterns and conventions
- **Dependency research**: Libraries, frameworks, APIs

## Subtask Prohibition

- Project Research MUST NOT start subtasks (`new_task` is NOT used)
- Project Research delivers structured results via `attempt_completion`
- ONLY the Orchestrator starts Project Research subtasks

## Delegation Principle

Other modes (especially the Orchestrator) SHOULD delegate research tasks as subtasks to Project Research instead of searching themselves.

## Search Guidelines

- External searches are subject to the rules in `.roo/rules/01-kagi.md`
- No internal, project-specific information in external search queries
- Generalize search queries and focus on technology

## Result Format

Structured summary with:

- **Found files/code locations**: With exact paths and line numbers
- **Relevant patterns and conventions**: Identified patterns in the codebase
- **Dependencies and relationships**: Relationships between components
- **Recommendations**: Concrete suggestions for further action

## Return Protocol

After completing research:

```
attempt_completion with:
- Structured summary of results
- Relevant code snippets with path references
- Identified risks or special considerations
- Recommended next steps
```
