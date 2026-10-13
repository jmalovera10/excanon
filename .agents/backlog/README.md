# Backlog protocol

How agents and the maintainer track work in the private `jmalovera10/excanon-backlog` repository. Every unit of work is one issue there, and labels record its state. The maintainer follows those issues on a GitHub Projects board. Agents read and write the issues and labels only.

## Why a private repository

- Proposals, benchmarks and specs stay private until the maintainer decides to make something public.
- Only the maintainer and `excanon-bot` can write there, so agents treat its contents as trusted, unlike issues in the public repository.
- The bot manages issues and labels through its own GitHub App identity. No personal token is involved.

**Security vulnerabilities never go into the backlog.** They follow the embargoed security response workflow and GitHub's private advisories.

## Ticket lifecycle

```
idea ──► proposal ──► [M] prioritized ──► spec ──► [M] spec-approved ──► build ──► verify ──► review ──► [M] closed
                 └──► [M] closed (declined)          (high impact only)
```

`[M]` marks a transition that only the maintainer makes. A standard or trivial ticket goes straight from `spec` to `build`.

| Stage label | Meaning | Who sets it | Next |
|---|---|---|---|
| `stage:idea` | Raw idea from discovery, not yet refined | Product Lead, Staff Engineer, Triage, Retro, maintainer | `proposal` |
| `stage:proposal` | Refined proposal, ready for prioritization | Product Lead, Staff Engineer (after Scope Review) | `prioritized` or closed |
| `stage:prioritized` | Approved for work | **Maintainer only** | `spec` |
| `stage:spec` | Spec, test plan and threat model in progress | Delivery Lead | `spec-approved` (high impact) or `build` |
| `stage:spec-approved` | High-impact spec approved | **Maintainer only** | `build` |
| `stage:build` | Implementation in progress | Delivery Lead | `verify` |
| `stage:verify` | QA, Security, Review, API and Performance checks | Delivery Lead | `review` or back to `build` |
| `stage:review` | Public PR open, awaiting the maintainer | Delivery Lead | closed when merged |

Rules:

1. **One stage label per open ticket.** Changing the stage removes the old label in the same operation.
2. **Agents never set `stage:prioritized` or `stage:spec-approved`,** and never close a ticket as declined. Those transitions are the maintainer's decisions.
3. **A ticket closes when its PR merges,** or when the maintainer declines it. Agents close a ticket only after confirming its PR was merged.
4. **Going backwards is allowed.** For example, `verify` returns to `build` when a check fails. Leave a comment saying why.
5. **High impact found mid-build:** if building uncovers a high-impact trigger, the ticket returns to `stage:spec` with `impact:high`, and work stops until the spec is approved.

## Other labels

| Group | Labels | Who sets them |
|---|---|---|
| **Type** (exactly one) | `type:feature`, `type:tech`, `type:bug`, `type:docs`, `type:chore` | The role that creates the ticket |
| **Impact** (exactly one, from `spec` onward) | `impact:trivial`, `impact:standard`, `impact:high` | Architect, checked per the [impact policy](../policy/impact.md) |
| **Priority** (at most one) | `priority:high`, `priority:medium`, `priority:low` | **Maintainer only** |
| **Source** (exactly one) | `from:product`, `from:staff`, `from:triage`, `from:retro`, `from:maintainer` | The role that creates the ticket |
| **Owner** (at most one) | `role:<role-name>`, for example `role:architect` | Delivery Lead, when it hands work over |
| **Flags** | `needs:maintainer`, `blocked` | Any agent; the maintainer clears `needs:maintainer` when answering |

`labels.tsv` holds the canonical list. To create or update the labels in the backlog repository, run [`scripts/agents/sync-backlog-labels.sh`](../../scripts/agents/sync-backlog-labels.sh).

## Asking the maintainer

When a ticket needs a decision, the agent:

1. adds `needs:maintainer`,
2. posts a comment in the [decision request](../templates/decision-request.md) format, and
3. moves on to other work. It never waits idle on the answer.

The maintainer replies in the ticket and removes `needs:maintainer`. A reply that answers a gate also changes the stage label, for example to `stage:prioritized`.

## Linking to the public repository

- Public PRs link their ticket by URL. Only the maintainer and the bot can open that link, so nothing private leaks.
- A ticket that should become public, such as a confirmed bug that users should know about, gets a public issue in `excanon` only when the maintainer asks. That public issue never copies private discussion.
- Nothing from a ticket's body or comments goes into public commits, PRs or docs unless the task says so.

## Templates

Tickets are created from these templates. Each heading must be filled in, or marked `n/a` with a reason.

- [Proposal](../templates/proposal.md): `type:feature` and `type:tech`.
- [Bug](../templates/bug.md): `type:bug`.
- [Decision request](../templates/decision-request.md): a comment format, not a ticket.

Specs, test plans and threat models arrive with the build roles.

## Following the board

The maintainer's GitHub Projects board shows backlog issues, and the stage labels drive what it shows. A board can't group by label, so make one saved view per stage, filtered with `label:"stage:<name>"`. Add a `needs:maintainer` view to see everything waiting on a decision. The project's built-in **Auto-add** workflow, filtered to `repo:jmalovera10/excanon-backlog`, puts every new ticket on the board automatically.
