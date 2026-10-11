# ADR Template

This is the template for an individual Architecture Decision Record (ADR). Copy
this file to `docs/arc42/adr/ADR-NNNN-short-slug.md` and tailor it to the
decision. It is self-contained: it embeds the frontmatter contract, the
Qualification gate, the LLM qualification verdict, the MADR checklist evidence,
and every required MADR section. An ADR is complete only when every value is
real and no prompt, placeholder, or ellipsis remains.

Before writing or modifying an ADR, apply the complete qualification procedure
from the resolved Arc42 addon instruction (`givn instructions arc42-docs`). This
template records the structure and the ADR-specific contract; the instruction
owns the full qualification rules. A decision that does not pass all five
mandatory qualification dimensions is not an ADR.

<!-- ========================================================================
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     Copy everything below this banner into the new ADR file, then replace
     every {{...}} value and remove the instructional comments.
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     ======================================================================== -->

---

status: proposed
date: {YYYY-MM-DD}
decision-makers: {list everyone involved}
consulted: {list subject-matter experts consulted}
informed: {list everyone kept up-to-date}

# {Short title representative of solved problem and found solution}

## Qualification

ADR-QUALIFICATION: <PASS | FAIL>

### Qualification verdict

Fill every value from the structured verdict recorded in the change's `arc42.md` before creating this file.

qualification: <blank until recorded>
alternatives: <blank until recorded>
architectural_impact: <blank until recorded>
durable_consequence: <blank until recorded>
lower_level_artifact: <blank until recorded>
existing_adr_check: <blank until recorded>
must_be_shared: <blank until recorded>
routing: <blank until recorded>
canonical_artifact: <blank until recorded>
target_adr: <blank until recorded>
replacement_adr: <blank until recorded>

This records the decision classification and exactly one canonical target or
ADR relationship. Replace every value with the decision-specific verdict
produced before drafting. The record is complete only when all mandatory values
are supported by concrete evidence and the route-specific target fields are
correct. The five mandatory fields are `PASS` only when their own supplied
evidence is present. `qualification` is `QUALIFIED` only when all five are
`PASS`; otherwise it is `NOT_QUALIFIED`. This verdict is an authoring record; it
is not evaluated by the Givn runtime and it must not be invented from anything
other than facts and alternatives supplied by the author or source artifacts.

Routing is exactly one of:

- `NEW_ADR` for a qualified independent decision without an existing record.
- `AMEND_ADR` for a qualified refinement, with `target_adr` naming the existing
  record. Parallel ADRs for the same decision boundary are not allowed.
- `SUPERSEDE_ADR` for a qualified replacement, with `replacement_adr` naming the
  new record and the old record retaining the relationship. The old record must
  keep an explicit replacement link.
- `CANONICAL_ARTIFACT` for a non-qualifying candidate, with
  `canonical_artifact` naming exactly one destination.

### MADR checklist evidence

- [ ] **Hard to reverse** - Reverting later would cost significant effort
      because: _specific reason_.
- [ ] **Shapes quality attributes** - It materially affects [quality attribute]
      because: _specific reason_.
- [ ] **Structural** - It defines a boundary, contract, or dependency direction
      because: _specific reason_.
- [ ] **Must be shared** - Developers unfamiliar with it would systematically
      violate the architecture because: _supporting reason, never a gate_.

The four checklist items are evidence prompts, not independent qualification
criteria. Use them to support the five mandatory dimensions above, but do not
create an ADR unless every mandatory dimension passes. Do not invent
alternatives, impact, consequences, participants, or provenance; missing
evidence stays empty and causes its gate to fail. A single checked criterion,
including `Must be shared`, is never sufficient.

## Context and Problem Statement

{Describe the context and problem in 2-4 sentences. Make the scope explicit by
pointing to structural elements such as components and connectors.}

## Decision Drivers

- desired software quality, constraint, or concern
- ...

## Considered Options

- Option title 1
- Option title 2

List real, distinct options rather than strawmen.

## Decision Outcome

Chosen option: "Option title N", because {justification, giving the chosen
option plus its single most important reason}.

### Consequences

- Good, because project-specific positive consequence
- Bad, because project-specific negative consequence

List only non-obvious or project-specific effects; every "Bad, because..."
consequence recorded here is a risk or piece of technical debt that warrants a
line in Arc42 chapter 11.

### Confirmation

Name the concrete test type, fitness function, linting rule, or review
checkpoint that confirms implementation and compliance. Do not write merely "we
will review it".

## Pros and Cons of the Options

### Option title 1

- Good, because argument
- Neutral, because argument
- Bad, because argument

### Option title 2

- Good, because argument
- Bad, because argument

## More Information

Additional evidence, team agreement, links to related decisions, or resources.
