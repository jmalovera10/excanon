# Versioning policy

How excanon's version number and deprecations work. The maintainer owns this file, and changes to it are high impact (trigger 7). The API Compatibility Steward applies it, and the Release Engineer uses it to choose the next version.

## The public contract

Anything a user can rely on without reading excanon's source:

1. **Public modules and functions:** every module and function that isn't marked `@moduledoc false` or `@doc false`, with its arity and `@spec`. `scripts/agents/api-diff.sh` lists these. Today the public modules are `Excanon` and `StatefulRuleEngine`.
2. **The rule format:** rule fields (`name`, `description`, `conditions`, `actions`, `after`, `requires`), every operation keyword, its arguments and its documented result.
3. **Evaluation semantics:** ordering, `requires` gating, how actions modify facts, and what is rejected at load time.
4. **Result shapes:** `:ok`, `{:ok, _}` and `{:error, reason}` shapes, and which errors raise and which return.
5. **Supported versions:** the Elixir and OTP versions in the CI matrix.

The **text** of error messages isn't part of the contract and may be reworded in any release. Users should match on the result shape, not on the message.

## Version numbers

Excanon follows [Semantic Versioning](https://semver.org/) **strictly, as if it were already 1.x**:

| Change | Version bump | Example from 0.2.0 |
|---|---|---|
| Breaks anything in the public contract | **Major** | → **1.0.0** |
| Adds to the contract without breaking it (a new operation, function or option) | Minor | → 0.3.0 |
| Fixes behavior to match the documentation, with no contract change | Patch | → 0.2.1 |

The first breaking change after 0.2.0 therefore releases as **1.0.0**.

## Deprecation

Before anything in the public contract is removed or changed incompatibly:

1. **Deprecate it** in a minor release:
   - functions get `@deprecated "Use X instead"`,
   - rule features log a deprecation warning when a rule using them is loaded,
   - the changelog gets an entry under `Deprecated` saying what replaces it.
2. **Keep it working for at least one minor release.**
3. **Remove it** only in the next major release, with a migration note in the changelog.

Security fixes are the exception. If keeping a behavior is itself the vulnerability, it may change in a patch release, explained in the advisory and the changelog.

## Who applies it

- **The API Compatibility Steward** classifies every change against the contract and states the version bump it requires.
- **A change that requires a major bump is always high impact** (impact policy, trigger 2).
- **The Release Engineer** picks the next version from the bumps recorded since the last release. The maintainer approves it as part of the release.
