<!--
Test plan, written by QA from the spec before any code exists, and posted on
the backlog ticket. The Developer writes these tests first, and they must fail
before the implementation lands.
-->

## Test plan: <ticket title>

**Spec:** <link>

### Cases

Every acceptance criterion and every edge case in the spec maps to at least one case. Tests call the public API the way users do, and assert concrete results.

| # | Criterion or edge case | Input (rules and facts) | Expected result | Test file |
|---|---|---|---|---|
| 1 | | | | `test/…` |

### Regression

Existing behavior that must not change, and the existing tests that already cover it.

### Coverage

The modules this change touches, and the expected coverage after it. Total coverage stays at or above 90%.

### Doctests

The examples in `@doc` that must exist and run as doctests.

### Not tested, and why

Anything deliberately left untested, with the reason.
