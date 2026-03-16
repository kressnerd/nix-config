# Review Output Format

## Rule ID: REV-OUT-001

## Mandatory Output Format

Structure EVERY review result as follows:

```
## Review Report

### Summary
- **Review Type**: [FILE|COMMIT|BRANCH]
- **Scope**: [File paths / Commit hashes / Branch name]
- **Findings**: [Count] (X Critical, Y High, Z Medium, W Low, V Info)
- **Recommendation**: [APPROVE|REQUEST CHANGES|NEEDS DISCUSSION]

### Findings

#### [F-001] [SEVERITY] [CATEGORY] Short title
- **File**: `path/to/file.ext:line`
- **Description**: What was found
- **Problem**: Why this is problematic
- **Recommendation**: Concrete improvement
- **Code Example** (optional):
  Before: ...
  After: ...

[Further findings sorted by severity descending...]

### Positive Aspects
- What was done well (mention at least 2 points)

### Overall Recommendation
[Well-founded recommendation with concrete next steps]
```

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security breach, data loss possible | Must be fixed before merge |
| HIGH | Functional bug, severe design flaw | Should be fixed before merge |
| MEDIUM | Code smell, maintainability issue | Should be addressed soon |
| LOW | Style, conventions, minor improvements | Nice-to-have |
| INFO | Observation, question, note | For information |

## Overall Recommendation Criteria

| Recommendation | Condition |
|----------------|-----------|
| **APPROVE** | No CRITICAL/HIGH findings, max 3 MEDIUM |
| **REQUEST CHANGES** | At least 1 CRITICAL or HIGH finding |
| **NEEDS DISCUSSION** | Architecture questions or trade-offs requiring team decision |

## Sorting and Grouping

1. Sort findings by severity: CRITICAL → HIGH → MEDIUM → LOW → INFO
2. Group by category within same severity
3. Number sequentially: [F-001], [F-002], ...

## On Zero Findings

If no issues are found:

```
## Review Report

### Summary
- **Review Type**: [FILE|COMMIT|BRANCH]
- **Scope**: [...]
- **Findings**: 0
- **Recommendation**: APPROVE

### Findings
No findings. Code meets all review criteria.

### Positive Aspects
- [At least 2 concrete positive points]

### Overall Recommendation
APPROVE – Code is clean and can be merged.
```
