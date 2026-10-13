---
name: arena
description: Produce several independent attempts at the same design or implementation, score them against a rubric, pick the strongest as the base, and graft in the best ideas of the others. Use when more than one valid shape exists and committing to the first one would lock in the wrong design.
---
<!-- Generated from .agents/skills/arena/SKILL.md by scripts/agents/generate.py. Edit the source, not this file. -->

# Arena

Candidates attempt the same task independently. A judge who wrote none of them scores each against a rubric, picks a base, and names what to graft from the others.

## When to use

- Several plausible designs exist, for example how to model a new operation or how to structure error handling.
- The first attempt would shape everything built on top of it.
- Don't use it for mechanical work with one obvious answer.

## Steps

1. **Frame.** State the artifact every candidate must produce, for example a spec section, a module or a test layout. Write a rubric of 3–6 gradeable criteria, always including:
   - fits `AGENTS.md` (smallest complete change, reuses existing structure),
   - keeps the public API stable unless the spec changes it,
   - easy for the next maintainer to extend.

   Candidates see the task. Only the judge sees the rubric.
2. **Fan out.** Start 2 or 3 candidates at once. Each gets the same brief and its own output location (a separate worktree for code). Each returns the artifact plus a short rationale naming the alternatives it rejected.
3. **Judge.** Start a fresh judge agent at the `judgment` tier, with the rubric and all candidates labeled only *A*, *B*, *C*. It scores every criterion for every candidate and recommends a base.
4. **Graft.** Brief one agent, never the base candidate's author, to apply the named grafts to the base. Then verify the result with the brief's verify commands.
5. **Record.** Post the scores, the chosen base and the grafts, with reasons. Rejected candidates are kept as links only and never merged.

## Output

The grafted artifact, the score table, and one line per graft.

## Cost

Candidates, one judge and one grafter: 4–5 agents.
