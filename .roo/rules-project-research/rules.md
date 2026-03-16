# Project Research Mode Rules

## 🎯 1. Initialization & Continuity

**At Story Start:**

1. Initialize Research Plan from template
2. Conduct first discovery session (min. 30 minutes)
3. Populate initial Knowledge Base
4. Formulate initial hypotheses

**Continuous Updates:**

- **After each significant finding**: Update Knowledge Base
- **Every 2 hours of active work**: Status update in plan
- **On blockers**: Document immediately with solution approach

## 🔍 2. Iterative Deep Analysis

```markdown
WHILE (success criteria not met) DO:
1. Identify next critical investigation area
2. Formulate specific investigation questions
3. Conduct targeted analysis:
   - Code review with concrete metrics
   - Documentation analysis with source citations
   - External research with validation
4. Document findings with:
   - Evidence (screenshots, code snippets, links)
   - Confidence level (0-100%)
   - Impact assessment
5. Update Living Knowledge Base
6. Check if new insights require scope adjustment
END
```

## 📝 3. Documentation Standards

**Each finding must contain:**

- **What**: Precise description
- **Where**: Exact location (File, Line, System)
- **Why relevant**: Business/Technical impact
- **Evidence**: Screenshots, code, logs
- **Confidence**: Percentage certainty
- **Next Steps**: Concrete follow-up actions

**Diagram Creation:**

```markdown
Diagrams can be created for each analysis:

- 1x System Context Diagram (C4 Level 1)
- 1x Component Diagram (C4 Level 2)
- 1x Process Flow (BPMN or Sequence)
- Optional: Data Flow, State Machines, ER Diagrams
```

## 🔄 4. Phase Flexibility

**Dynamic Phase Design:**

- Phases can run **in parallel**
- Phases can be **repeated**
- New phases can be **inserted**
- Phases can be **skipped** (with justification)

**Triggers for Phase Change:**

- All must-have criteria of phase fulfilled
- New critical insights require different focus
- External dependencies block progress

## 📊 5. Final Deliverables

**Mandatory components of analysis document:**

1. **Executive Summary** (1 page)
2. **Detailed Analysis** with:
    - Business context
    - Technical assessment
    - Risk assessment
3. **Visualizations**:
    - At least 5 meaningful diagrams
    - Annotations and explanations
4. **Action Recommendations**:
    - Prioritized measures
    - Effort estimates
    - Implementation roadmap
5. **Appendices**:
    - Raw data
    - Detailed code analyses
    - References

## ⚡ 7. Efficiency Rules

**Time-Boxing:**

- Discovery: Max. 2 hours
- Deep-dive per area: Max. 4 hours
- Document creation: Max. 3 hours
- Review & validation: Max. 2 hours

**Quality Over Quantity:**

- 5 high-quality diagrams better than 20 mediocre ones
- 10 validated findings better than 50 assumptions
- 1 actionable recommendation better than 5 vague suggestions

## 🚨 8. Escalation Points

**Stop and escalate when:**

- Blocker cannot be resolved within 1 hour
- Critical security/compliance issue discovered
- Scope significantly larger than estimated
- Required expertise not available

## 📋 9. Research Completion Criteria

Research is complete when ALL of the following are true:

- [ ] All initial research questions answered
- [ ] Confidence level ≥ 80% for all major findings
- [ ] At least 5 meaningful diagrams created
- [ ] Action recommendations prioritized and estimated
- [ ] Stakeholders can make informed decisions based on findings
- [ ] All blockers documented with workarounds/solutions
- [ ] Knowledge Base is complete and searchable
