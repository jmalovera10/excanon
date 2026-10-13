# Agent architecture

This folder holds the canonical definitions for excanon's agent team: roles, skills, workflows, templates and policy. It does not depend on any one tool. Tool-specific files (for example `.claude/agents/`) are generated from these definitions and checked in CI so they can't drift.

## Principles

Authority, trust boundaries and the quality bar are defined once, in `AGENTS.md`. This folder adds how the team is organized:

1. **Handoffs are documents.** Each stage produces a written artifact in a fixed format. The next stage reads that artifact, not a chat transcript.
2. **Separation of duties.** The agent that builds something never reviews or verifies it.
3. **Lessons become structure.** A correction made twice becomes a rule, a check or a template field.

## Layout

```
AGENTS.md                 rules for every agent (repo root)
CLAUDE.md                 Claude Code entry point; imports AGENTS.md
.agents/
  README.md               this file
  policy/                 maintainer-owned rules (changes are high impact)
    impact.md             impact levels and high-impact triggers
  backlog/                backlog protocol and canonical label set
  roles/                  one file per role: mission, inputs, outputs, limits
  skills/                 reusable procedures (SKILL.md folders)
  workflows/              end-to-end flows across roles
  templates/              handoff documents: proposal, spec, brief, report
scripts/agents/           helper scripts: backlog label sync, adapter generator
.claude/skills/           generated for Claude Code; never edit by hand
```

## Role files

Each file in `roles/` starts with frontmatter that tools and the generator read:

| Key | Meaning |
|---|---|
| `name` | Identifier, matching the file name |
| `title` | Human-readable name |
| `description` | When to use the role. Tools use it for routing. |
| `tier` | `judgment`, `standard` or `fast`. See the table below. |
| `runs-as` | `main`: runs in the maintainer's session, which the maintainer starts directly. `subagent`: started by another agent. Either kind can start agents, at most three layers below the maintainer's session. |
| `invocation` | Optional. `manual` means only the maintainer can start the role; tools never start it on their own. |
| `argument-hint` | Optional. Shows what to pass when starting a `main` role, for example `"<ticket number> \| next"`. |

### Model tiers

| Tier | For | Claude Code model |
|---|---|---|
| `judgment` | Orchestration, architecture, review, security, and judges in collaboration patterns | `opus` |
| `standard` | Implementation, research, test writing | `sonnet` |
| `fast` | Mechanical work: label updates, log reading, formatting | `haiku` |

A `main` role runs on whatever model the maintainer's session uses. For it, the tier is a recommendation.

## Adapters

Canonical files in `.agents/` are the only ones edited by hand. `scripts/agents/generate.py` produces tool-specific copies from them, and the `Agent definitions in sync` CI job fails when those copies drift. After editing anything under `.agents/roles/` or `.agents/skills/`, run:

```bash
scripts/agents/generate.py
```

| Tool | Generated files |
|---|---|
| Claude Code | `main` roles and skills → `.claude/skills/<name>/SKILL.md`. Start a role with `/<name>`, for example `/delivery-lead next`. The arguments reach the role as its run input. |

`subagent` roles get their Claude Code adapter together with the first such role.


## Pipeline

```
Discovery ─► Proposal ─► [maintainer: prioritize]
   ─► Spec + test plan + threat model ─► [maintainer: approve, if high impact]
   ─► Execution plan ─► Build ─► Verify (QA · Security · Review · API · Perf)
   ─► Pull request ─► [maintainer: approve + merge]
   ─► Release PR ─► [maintainer: tag + publish]
```

Work state lives as labeled issues in the private `jmalovera10/excanon-backlog` repository, following the [backlog protocol](backlog/README.md). The maintainer follows it on a GitHub Projects board.

## Roles

| Tier | Role | Mission |
|---|---|---|
| Orchestration | Delivery Lead | Runs the pipeline, writes briefs, routes work and PR comments, batches decisions for the maintainer. Never writes code. |
| Discovery | Product Lead | Benchmarks rule engines, gathers user signals, ideates and refines product proposals. |
| Discovery | Staff Engineer | Owns the technical backlog: gathers proposals from the specialist roles and proposes refactors, upgrades and debt work. |
| Discovery | Scope Reviewer | Keeps each proposal functional but right-sized so it can be built and evaluated. |
| Build | Architect | Writes technical specs and decision records, and proposes the impact level. |
| Build | API Compatibility Steward | Guards the public contract, semantic versioning and deprecations. |
| Build | Elixir Developer | Implements specs in isolated worktrees. |
| Build | QA Engineer | Writes the test plan before code, holds coverage at 90% or more, verifies against acceptance criteria. |
| Guardian | Security Engineer | Threat-models specs, reviews PRs, hardens the supply chain. |
| Guardian | Code Reviewer | Reviews independently, in a fresh context. |
| Guardian | Performance Engineer | Benchmarks, profiles, guards against slowdowns and proposes performance improvements. |
| Operations | Release Engineer | CI and release preparation. Publishing stays with the maintainer. |
| Operations | CI Doctor | Diagnoses CI failures and hands each fix to the owning role. |
| Operations | Triage | Reproduces and routes incoming issues, after the maintainer approves the run. |
| Operations | Bug Investigator | Reproduces bugs and finds root causes. Stops after three failed attempts. |
| Operations | Docs Writer | README, module docs, doctests, changelog. |
| Operations | Retro | Turns repeated corrections into rules, checks and templates. |
| Security | Security Response Coordinator | Prepares embargoed vulnerability fixes and advisory packages for the maintainer to file. |
