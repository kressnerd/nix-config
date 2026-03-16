# Implementation Plan Management

## Overview

Implementation Plans structure feature development into clear phases with specific steps. They serve as both planning and execution documents.

## Plan Creation

Create a plan document before any implementation:

### Plan Creation Phase Checklist

- [ ] Retrieve requirements (e.g., from task description)
- [ ] Search for relevant documentation in project docs
- [ ] Search for relevant code sections and similar configuration patterns
- [ ] Research further technical details from available documentation sources
- [ ] Create implementation plan with sections: Goal, Context, Technical Analysis, Implementation Phases, Validation Strategy
- [ ] Save plan to `docs/plans/<descriptive-name>-plan.md`
- [ ] Get human approval on plan BEFORE proceeding

## Plan Execution

During implementation:

1. **Mark step as complete**: Change `- [ ]` to `- [x]`
2. **Update Current Status section** after each step
3. **Document blockers and questions** as they arise
4. **Do NOT commit the plan**

### Progress Reporting

After EACH phase completion:

- Report: "Completed Phase X. Moving to Phase Y."
- Summarize any deviations from plan
- List any new risks or considerations discovered

## Plan Structure

### Mandatory Sections

- **Business Context**: What problem does this solve?
- **Acceptance Criteria**: How do we know it's done?
- **Technical Analysis**: Architecture and implementation approach
- **Implementation Phases**: Specific phases with numbered steps
- **Current Status**: Real-time progress tracking
- **Completion Log**: Record of completed phases

## Plan Compliance Verification

Before moving to next phase:

- [ ] All steps in current phase marked complete
- [ ] Quality checkpoints passed
- [ ] No steps were skipped
- [ ] Documentation updated as specified

## Deviation Handling

If implementation requires deviation from plan:

1. **STOP** immediately
2. **Document** the required deviation
3. **Ask**: "The implementation plan specifies X, but I need to do Y because [reason]. Should I update the plan and proceed?"
4. **Wait** for approval
5. **Update** plan with approved changes
6. **Continue** only after plan is updated

## Plan Completion

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
- [ ] Link completed plan in relevant issue/story (if applicable)
- [ ] Archive plan for future reference

## Enforcement

### Non-Compliance Consequences

- Implementation without plan = MUST DELETE and start over
- Steps executed without updating plan = MUST STOP and update retrospectively
- Skipped phases or steps = MUST GO BACK and complete properly

### Self-Monitoring

Before proceeding:

1. Do I have an approved implementation plan?
2. Is my plan up-to-date with my current progress?
3. Am I following the plan's current step?

If ANY answer is NO → STOP and fix the issue first.
