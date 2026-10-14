<!--
Execution plan. The Delivery Lead writes it after the spec is settled and posts
it on the ticket. The Architect and QA validate it independently before build.
Fill in every section, or write "n/a: <reason>".
-->

## Plan for <ticket title>

**Spec:** <link> · **Test plan:** <link> · **Impact:** <level>

### Work units

Each unit is the smallest change that ends in a check.

| # | Unit | Files | Depends on | Tier | Verify |
|---|---|---|---|---|---|
| 1 | | | — | standard | `<command>` |

**Tier** is `standard` by default. Mark a unit `judgment` when it touches core evaluation, ordering, concurrency or code execution, or when the spec flags it as subtle.

### Order and parallel streams

- **First, blocking:** units that must finish before anything else starts.
- **Parallel streams:** units that touch separate files. Each stream gets its own branch and worktree.
- **Shared files:** units that must run one after another because they write the same files.

### Pull requests

How the units group into PRs. Each PR must be self-contained and reviewable on its own, and units that only make sense together go in the same PR.

| PR | Units | Title (conventional commit) |
|---|---|---|
| 1 | | |

### Verification after build

Which checks run in the verify stage, and why:

- [ ] QA: always
- [ ] Code Reviewer: always
- [ ] Security: <yes/no and reason>
- [ ] API Compatibility Steward: <yes/no and reason>
- [ ] Performance: <yes/no and reason>

### Collaboration patterns

Any arena, panel, adversarial review or swarm this plan uses, where, and why. Or "none".

### Risks

What could make the plan wrong, and the signal that would send the ticket back to `stage:plan`.
