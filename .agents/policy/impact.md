# Impact policy

Every unit of work gets an impact level before building starts. The level decides which maintainer gates apply. This file is the single source of truth for that classification.

## Levels

| Level | Meaning | Maintainer gate |
|---|---|---|
| **Trivial** | No effect on behavior, API or dependencies | Approves the PR |
| **Standard** | Changes internal behavior within the existing public contract | Approves the PR |
| **High impact** | Matches any trigger below | Approves the spec **before** building starts, then approves the PR |

Every pull request needs the maintainer's approval, whatever its level. The level decides whether a second gate comes earlier, at the spec.

### Trivial examples

- Typos, wording and formatting in docs or comments.
- New tests for existing behavior.
- Refactors with no change in behavior that touch one module and no public function.

### Standard examples

- A bug fix that makes the code match its documented behavior.
- An internal refactor across modules that keeps every public function, spec and error tuple unchanged.
- A performance improvement with no change in results.

## High-impact triggers

A change is high impact if it does **any** of the following:

1. **Changes the public API or documented behavior.** That means adding, removing or renaming a public module, function or option; changing a `@spec`; changing an error tuple; or changing what a rule, operation or JSON field means.
2. **Breaks compatibility** for existing users, including dropping an Elixir or OTP version.
3. **Adds or replaces a dependency** of any kind, including dev-only and test-only ones, unless it's listed under [Pre-approved dependencies](#pre-approved-dependencies).
4. **Redesigns core functionality:** rule evaluation, rule ordering and dependencies (`rule_graph`), operation dispatch, or the stateful engine's process model.
5. **Touches code execution:** the `call` operation, `Code.eval_*`, or anything that loads or runs code chosen by a rule.
6. **Changes CI or automation permissions:** workflow permissions, secrets usage, environments or triggers.
7. **Changes agent rules:** `AGENTS.md` or any file under `.agents/policy/`.

## How classification works

1. The role that writes the spec (usually the Architect) proposes a level and names the trigger, if any.
2. Two roles check the proposed level independently:
   - The **API Compatibility Steward** checks triggers 1 and 2.
   - The **Security Engineer** checks triggers 2 through 7, because each one can open a new attack surface: a compatibility break, a new dependency, a core redesign, a code-execution path, a CI permission or an agent rule.
3. **When unsure, pick the higher level.**
4. The level and its reason go on the backlog ticket and in the PR description.
5. If the work grows into a high-impact trigger during building, it stops and returns to the spec gate.

## Changing this policy

1. Anyone, including agents (usually the Retro role), may propose a change through a pull request that edits this file.
2. The PR explains the case that prompted it, with evidence.
3. Changes to this file are always high impact (trigger 7), so only the maintainer can approve them.
4. Each change is recorded below.

## Pre-approved dependencies

Dependencies the maintainer has already approved. Adding one of these is not a high-impact trigger by itself. The change that adds it is classified on its other merits.

| Dependency | Scope | Approved for | Date |
|---|---|---|---|
| `benchee` | `only: [:dev, :test]`, `runtime: false` | Performance benchmarks | 2026-10-14 |

## Change log

| Date | Change | PR |
|---|---|---|
| 2026-10-12 | Initial policy | #14 |
| 2026-10-14 | Pre-approve `benchee` as a dev and test dependency | (PR 7) |
