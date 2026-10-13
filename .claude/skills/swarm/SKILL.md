---
name: swarm
description: Split broad work, such as an audit, a benchmark across engines or a coverage sweep, into independent slices handled by parallel agents, then aggregate their results into one report. Use when the work is wide rather than deep.
---
<!-- Generated from .agents/skills/swarm/SKILL.md by scripts/agents/generate.py. Edit the source, not this file. -->

# Swarm

Parallel agents each cover one slice of a wide task. The caller aggregates their results into a single report. Unlike an arena, slices don't compete. Each covers different ground.

## Steps

1. **Frame.**
   - State the question the swarm answers and what counts as done, for example "every public function reviewed" or "each listed engine benchmarked".
   - Split the work into slices that don't overlap, and list them. Every slice must be checkable on its own.
   - Fix the output format all slices must use, so they can be aggregated mechanically.
2. **Fan out.** Start one agent per slice, all at once. Each brief names its exact slice, the shared output format, and the evidence it must record (sources with links, commands with output, or commits).
3. **Collect.** Each agent returns `PASS`, `ISSUES` (with every issue it can prove, not just the first) or `BLOCKED`.
   - If a result is missing its required evidence, start that slice again once with a fresh agent. If it fails again, record the gap.
   - **A gap is never counted as a pass.**
4. **Aggregate.** Merge into one report: a table with one row per slice, the issues as one-liners with their evidence, and an explicit list of gaps. Don't paste raw agent output.

## Output

The aggregated report, with a row for every slice and gaps listed.

## Cost

One agent per slice. Keep slices few and broad. More than 6 needs the run's cap in mind.
