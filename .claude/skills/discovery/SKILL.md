---
name: discovery
description: Runs excanon's discovery cycle. The Product Lead and Staff Engineer gather evidence and rank candidate ideas, the strongest ones across both are refined into at most 3 scoped proposals, and a report is posted to the private backlog. Runs weekly and on demand.
disable-model-invocation: true
argument-hint: "[product | tech | both]"
---
<!-- Generated from .agents/workflows/discovery.md by scripts/agents/generate.py. Edit the source, not this file. -->

# Discovery

You coordinate one discovery cycle. You don't research or write proposals yourself. You brief the Product Lead and the Staff Engineer, choose which candidates get refined, and publish the report.

Run input: `product`, `tech` or `both`. Empty means `both`.

## Budget

- **Proposals:** at most **3 per run**, shared between product and technical work.
- **Benchmark rotation:** at most **4 engines per run** from `.agents/discovery/engines.md`, plus one scouting slice. Pick the engines least recently benchmarked, according to earlier discovery reports. The whole list is covered every few weeks.
- **Agents:** soft cap of **30 per run**, panel and swarm members included, plus 6 more on monthly runs for the security sweep and performance study. Before going over the cap, stop and report what is left.

## Steps

1. **Context.** Read `AGENTS.md`, `.agents/policy/product.md`, the latest discovery report (a backlog issue labeled `report`), and the open `stage:idea` and `stage:proposal` tickets.

2. **Gather, in parallel.** Brief the Product Lead and/or the Staff Engineer, following the run input, for **phase 1** of their role files. If no earlier discovery report this calendar month exists, mark the Staff Engineer's brief `monthly`, which brings in the security sweep and the performance study. They gather findings, record `stage:idea` tickets, and return a ranked list of candidates. Name the engines for this rotation in the Product Lead's brief.

3. **Choose.** Merge the two ranked lists and pick at most 3 candidates. Weigh user value, risk reduced, strength of evidence, fit with `product.md`, and size. Don't fill the budget with weak candidates: fewer, stronger proposals are better.

   A **pending proposal** is one already at `stage:proposal` and waiting on the maintainer. If 3 or more are pending, refine only 1 new candidate. That keeps the maintainer's queue from growing faster than they can decide.

4. **Refine.** For each chosen candidate, brief the lead who found it for **phase 2** of its role file (refine, scope review, promote), naming the candidate. Several candidates can be refined in parallel.

5. **Report.** Post a backlog issue titled `Discovery report <YYYY-MM-DD>` with the `report` label. Close the previous report issue. It contains:
   - **Proposals promoted** to `stage:proposal`, one line each with a link. These are what the maintainer prioritizes.
   - **Ideas recorded** at `stage:idea`, one line each.
   - **Candidates not chosen**, and why.
   - **Benchmark highlights:** which engines were covered this run, the key gaps and strengths found, and suggested additions to `engines.md`.
   - **Health summary** from the Staff Engineer.
   - **Questions for the maintainer**, especially conflicts with `product.md`.
   - **Agents used** against the cap.

6. **Digest.** Reply in the session with the report's link and its first two sections.

**Embargoed findings** from the security sweep never go into the report or the backlog. Put them only in the session digest, under a heading **"Embargoed: for the maintainer only"**, and tell the maintainer to save each finding to a local file and run `/security-response <file>` on their machine.

## Never

- Promote more than 3 proposals in one run.
- Set `stage:prioritized` or `priority:` labels.
- Edit repository files. Changes to `engines.md` or `product.md` are suggested in the report, and the maintainer makes them through a PR.

## Run input

$ARGUMENTS
