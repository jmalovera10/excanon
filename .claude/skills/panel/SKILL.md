---
name: panel
description: Refine a proposal, spec or decision by having independent personas critique it, then a separate judge consolidate the result. Use when a document benefits from opposing viewpoints before it moves on.
---
<!-- Generated from .agents/skills/panel/SKILL.md by scripts/agents/generate.py. Edit the source, not this file. -->

# Panel

Several personas each review the same artifact independently. Then a judge, who wrote none of the reviews, consolidates them into one revised artifact and a short rationale. The value comes from **independence**: personas never see each other's output.

## Inputs

- **Artifact:** the document to refine, as a path or link.
- **Goal:** what "better" means for it, such as clearer scope, feasibility, or user value.
- **Personas:** from the role or plan that called the panel. The default set:

| Persona | Asks |
|---|---|
| Enthusiast | What's the most valuable version of this? What is it underselling? |
| Critic | What's wrong, missing, risky or unjustified? What would make this fail? |
| Pragmatist | What's the smallest version that delivers the core value? What can be cut? |
| User advocate | How would a developer using excanon experience this? Is it clear, safe and consistent with the rest of the API? |

## Steps

1. **Frame.** Write the goal and a rubric of 3–5 criteria the judge will score against. Personas see the goal but not the rubric.
2. **Fan out.** Start one agent per persona, all at once, each with a brief (`.agents/templates/brief.md`). Each one gets the artifact, the goal and its persona, and is told it is one independent voice. Each returns findings, every one labeled `must`, `should` or `could`, with its reasoning.
3. **Judge.** Start a fresh judge agent at the `judgment` tier, with the artifact, all persona outputs and the rubric. The judge:
   - weighs findings on their merits, not by how many personas raised them,
   - says which findings it accepts, rejects (with a reason) or defers,
   - produces the revised artifact.
4. **Check.** The caller reads the revised artifact against the rubric before accepting it. Points where personas disagreed and the judge picked a side go in the outcome, so they're visible.

## Output

The revised artifact, plus a table of findings with columns *finding · raised by · accepted/rejected/deferred · reason*.

## Cost

Personas plus one judge: 5 agents with the default set. Count them against the run's cap.
