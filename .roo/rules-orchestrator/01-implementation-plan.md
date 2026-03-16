# RULE: Implementation Plan Management

## Rule ID: IMPL-PLAN-001

**Priority**: MANDATORY
**Applies to**: All new feature implementations

## Rule Statement

For EVERY new feature implementation, the AI agent MUST:

### 1. Plan Creation Phase (BEFORE ANY CODE)

```
MANDATORY ACTION: Create Implementation Plan BEFORE writing any code
```

- [ ] Search for relevant details in the current documentation in `@docs/` in Project Research Mode
- [ ] Search for relevant code sections in the source and search for similar configuration patterns in Project Research Mode
- [ ] Research further details from upstream documentation (NixOS manual, Home Manager docs, nixpkgs) in Project Research Mode
- [ ] Create implementation plan with sections: Goal, Context, Technical Analysis, Implementation Phases, Validation Strategy
- [ ] Fill ALL sections of the plan completely:
    - Goal and Context
    - Acceptance Criteria
    - Technical Analysis (based on architecture review)
    - Implementation phases with specific steps
- [ ] Save plan as: `docs/plans/<descriptive-name>-plan.md`
- [ ] Get human approval on plan BEFORE proceeding

### 2. Plan Execution Phase (DURING IMPLEMENTATION)

```
MANDATORY ACTION: Update plan status AFTER EACH STEP
```

#### Update Protocol

After completing EACH step:

1. **Mark step as complete**: Change `- [ ]` to `- [x]`
2. **Update Current Status section**:
   ```markdown
   ### Current Status
   - **Current Phase**: Phase X
   - **Current Step**: Step X.Y
   - **Blockers**: [Any blockers encountered]
   - **Questions**: [Any pending questions]
   ```
3. **Update Completion Log** when finishing a phase:
   ```markdown
   | Phase X | ✅ | 2h 15min | [Any relevant notes] |
   ```
4. **Do NOT commit the plan**

#### Progress Reporting

After EACH phase completion:

- Report: "Completed Phase X. Moving to Phase Y."
- Summarize any deviations from plan
- List any new risks or considerations discovered

### 3. Plan Compliance Verification

```
MANDATORY CHECK: Verify plan adherence at each checkpoint
```

Before moving to next phase, verify:

- [ ] All steps in current phase marked complete
- [ ] Quality checkpoints passed
- [ ] No steps were skipped
- [ ] Documentation updated as specified

### 4. Deviation Handling

```
MANDATORY PROTOCOL: Handle deviations transparently
```

If implementation requires deviation from plan:

1. **STOP** immediately
2. **Document** the required deviation in plan:
   ```markdown
   ### Deviation Log
   - **Step**: X.Y
   - **Reason**: [Why deviation is needed]
   - **Proposed Change**: [What needs to be different]
   - **Impact**: [How this affects other steps]
   ```
3. **Ask**: "The implementation plan specifies X, but I need to do Y because [reason]. Should I update the plan and
   proceed?"
4. **Wait** for approval
5. **Update** plan with approved changes
6. **Continue** only after plan is updated

### 5. Plan Completion

```
MANDATORY ACTION: Finalize plan when feature is complete
```

When all phases are complete:

- [ ] Verify all acceptance criteria are met
- [ ] Update plan status to `COMPLETED`
- [ ] Add completion summary:
  ```markdown
  ## Completion Summary
  - **Completed Date**: YYYY-MM-DD
  - **Total Duration**: X hours
  - **Deviations**: [List any deviations from original plan]
  - **Lessons Learned**: [Key insights for future implementations]
  ```
- [ ] Archive plan to `docs/plans/completed/`

## Enforcement

### Non-Compliance Consequences

- Code written without plan = MUST DELETE and start over
- Steps executed without updating plan = MUST STOP and update retrospectively
- Skipped phases or steps = MUST GO BACK and complete properly

### Monitoring

The AI agent must self-monitor compliance by:

- Checking for plan existence before any implementation
- Verifying plan currency before each work session
- Refusing to proceed if plan is not up-to-date

## Template Reference

Plans use the standard sections: Goal, Context, Technical Analysis, Implementation Phases, Validation Strategy, Completion Summary.

All sections must be present. Additional sections may be added when relevant.

## Example Compliance Check

```
Before writing code, ask yourself:
1. Do I have an approved implementation plan?
2. Is my plan up-to-date with my current progress?
3. Am I following the plan's current step?

If ANY answer is NO → STOP and fix the issue first.
```
