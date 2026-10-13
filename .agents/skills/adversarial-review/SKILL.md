---
name: adversarial-review
description: Have independent reviewers try to break a change (a diff, spec or plan) from different angles, then triage their findings into act on, consider, noted or dismissed. Use before a high-impact or contested change ships.
---

# Adversarial review

Reviewers each try to prove the change is wrong. They work independently, from different angles. A lead then triages their findings. The deliverable is a verdict. Nothing gets fixed automatically.

## Steps

1. **State the intent.** Write one paragraph on what the change is meant to do, from the spec, plan and commits. If it's unclear, stop and ask the caller. Reviewing against the wrong intent produces noise.
2. **Fan out.** Start 2 or 3 read-only reviewers at once, each with the same intent and diff but a different angle:

   | Angle | Hunts for |
   |---|---|
   | Correctness | Wrong results, unhandled edge cases (empty lists, `nil`, deep nesting, huge inputs), broken error tuples, callers left inconsistent |
   | Contract and security | Public API or behavior drift, code execution paths, injection through rule JSON, resource exhaustion, unsafe defaults |
   | Maintainability | Needless abstraction, missing tests for new logic, tests that check implementation instead of behavior, unclear naming |

   Each reviewer lists only findings it can support with a concrete input, a line reference or a failing test. Guesses are labeled as guesses.
3. **Triage.** The caller, or a fresh judge at the `judgment` tier for high-impact changes, merges duplicates and sorts each finding:
   - **Act on:** a real issue that would block a careful human reviewer.
   - **Consider:** a legitimate point, but the cost may outweigh it. Goes to the maintainer.
   - **Noted:** valid but not worth acting on now.
   - **Dismissed:** wrong or out of context. One line on why.

   A finding raised independently by two or more reviewers is the strongest signal.
4. **Hand back.** "Act on" findings go back to the build stage as a fix brief. "Consider" findings go into the PR description for the maintainer.

## Output

The verdict (`ship`, `fix first` or `rethink`) and the triaged findings table.

## Cost

Reviewers, plus an optional judge: 2–4 agents.
