# User Story Creation Guide

## Core Principle: BDD-First Stories

All user stories MUST follow **Behavior-Driven Development (BDD)** principles:
- Story descriptions use the **As a / I want / So that** structure
- ALL acceptance criteria are expressed as **Gherkin scenarios** using **Given / When / Then**
- Each scenario covers exactly ONE behavior or edge case
- Scenarios must be concrete, testable, and verifiable

## Story Format

Create user stories with these mandatory sections:

### Story Header

```
# User Story: [XXX-YYY]  
**Title:** [Concise, descriptive title - max. 60 characters]  
**Status:** Backlog  
**Priority:** [High/Medium/Low]  
**Labels:** [Relevant labels]  
```

### Story Description

**Use this pattern:**

```
As [specific role/persona]  
I want [concrete action/functionality]  
To [measurable benefit/business value]
```

**Consequence Analysis:**
```
If this story is not implemented,
[describe concrete negative impact]
```

**Story Owner:** [Name], [Department]

### Affected Components Checklist

- **System Services**: Which system services are impacted?
- **NixOS Modules**: Are new/changed NixOS modules involved?
- **Home Manager Features**: Are Home Manager feature modules affected?
- **Overlays/Packages**: Are overlays or custom packages involved?
- **Host Configurations**: Are specific host profiles affected?
- **Labels**: Are all relevant labels set?

### Context and Scope

**Context:** 
- Describe the business context
- Explain dependencies to other systems
- Define scope precisely

**Out of Scope:**
- What is NOT part of this story
- Which features are deliberately excluded

### Acceptance Criteria (BDD/Gherkin — MANDATORY)

**Use Given-When-Then Format:**

```
#### Scenario [Nr]: [Descriptive Title]

**Given** [initial situation]
**When** [action/trigger]
**Then** [expected result]
**And** [additional conditions]
```

**MANDATORY**: All acceptance criteria MUST use Gherkin syntax. Free-form bullet-point criteria are NOT acceptable.

Create at least 2-3 scenarios for:
- Happy Path (main scenario)
- Edge Cases
- Error handling

#### Gherkin Best Practices
- Use concrete values in examples, not placeholders
- One `Then` assertion per scenario (split complex assertions into separate scenarios)
- Use `And` for additional preconditions or postconditions, not for unrelated assertions
- Scenario titles must be descriptive enough to understand the test without reading the steps

### Technical Details

**DEV Notes:**
- Technical implementation hints
- API endpoints
- Database changes
- Performance requirements

**QA Notes:**
- Test data requirements
- Special test cases
- Regression tests

### Open Points

| Question | Answer/Decision | Responsible |
|----------|-----------------|-------------|
| [Open question] | [To be clarified] | [Person] |

## Writing Guidelines

### Do's:
- **Be specific**: Use concrete roles instead of "User" (eg. "Clerk", "Billing Administrator", "Supplier")
- **Measurable**: Use quantifiable criteria
- **Active voice**: Use active verbs
- **INVEST Principle**: Independent, Negotiable, Valuable, Estimable, Small, Testable
- **Domain language**: Use correct terminology

### Don'ts:
- No technical implementation details in story description
- No vague terms like "fast" or "user-friendly" without metrics
- No compound stories (use linked stories instead)
- No solution proposals in problem description

## Story Sizing Guidance:
- **Small (1-3 PT):** Simple UI change, small bugfix
- **Medium (5-8 PT):** New feature component, API integration
- **Large (13+ PT):** Should be split into smaller stories

## Quality Checks:
Before finalizing:
1. ✓ Story is self-contained and independently testable
2. ✓ All acceptance criteria are measurable
3. ✓ Business context is clear for developers
4. ✓ No technical solution prescribed (unless necessary)
5. ✓ Story delivers real business value
6. ✓ All relevant labels are set
7. ✓ All acceptance criteria use Gherkin Given/When/Then format (no free-form bullet points)
