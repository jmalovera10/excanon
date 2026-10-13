<!--
Agent brief. The Delivery Lead (or a pattern skill) writes one for every agent
it starts. The agent has no other context, so every field must stand on its
own. A field you can't fill means the unit isn't scoped yet: don't start the
agent. For one-command units, collapse this into a paragraph that still names
the goal, scope, verify command and report shape.
-->

**ROLE** `<role name from .agents/roles/>`. Read `AGENTS.md` and your role file first.

**TICKET** `<excanon-backlog ticket URL>`, plan unit `<n>` (if any).

**GOAL** One sentence stating the outcome, understandable by someone who has never seen this conversation.

**SCOPE**
- May change: `<paths>`
- Must not change: `<paths>`
- Branch and worktree: `<branch>` at `<worktree path>`, yours alone

**CONTEXT** Pointers to the spec, plan, files and earlier reports. Paste in full any upstream report this unit depends on.

**ACCEPTANCE** Checkable criteria, one per line.
1.

**VERIFY** The exact commands to run, and what passing output looks like. Note any known gotchas.

**TIMEBOX** Rough limit. If you hit it, stop and report partial results.

**FORBIDDEN** Everything `AGENTS.md` forbids, plus: `<unit-specific bans>`.

**REPORT** Use `.agents/templates/report.md`.
