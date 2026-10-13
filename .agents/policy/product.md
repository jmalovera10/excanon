# Product direction

What excanon is for. Discovery roles judge every idea against this file. The maintainer owns it, and changes go through the impact policy (trigger 7).

> **Draft.** Written by an agent from the README and the code. Every line marked *(confirm)* needs the maintainer's decision before discovery relies on it.

## Who it's for

- **Elixir developers** who need business rules that change without a redeploy, such as pricing, discounts, eligibility, policy checks and workflow routing.
- **People next to those developers** (analysts, product owners) who read or write rules as JSON. *(confirm: are non-developers a target audience, or only developers?)*

## What excanon is

- A **library** embedded in the host application, not a service.
- Rules are **JSON data**: conditions plus actions over a map of facts.
- Evaluation is **deterministic** for the same rules and facts, with explicit ordering (`after`, `requires`).
- Errors come back as **explicit `{:error, reason}` values** at load time, not surprises at evaluation time.

## Goals

1. **Readable rules:** someone who knows the business, not Elixir, can understand a rule.
2. **Predictable evaluation:** documented semantics for every operation, ordering and dependency.
3. **Small footprint:** few runtime dependencies (today, `jason` and `odgn_json_pointer`).
4. **Stable contract:** semantic versioning. Breaking changes are rare, documented, and come with a migration path.
5. **Fast enough not to matter:** evaluation cost stays negligible next to the host's own work. *(confirm: any concrete latency or throughput target?)*

## Non-goals

*(confirm all)*

- A UI or visual rule editor.
- A distributed or persistent rule service, or a workflow orchestrator.
- A general-purpose programming language inside JSON. New operations must be justifiable as business-rule primitives.
- Rule storage. The host application owns where rules live.

## Principles for new features

- **Prefer data over code.** A feature expressible in rule JSON beats one that needs host Elixir code.
- **Safe by default.** *(confirm)* Today the `call` operation runs arbitrary scripts, so rules must come from trusted sources (see `SECURITY.md`). Should future work move toward rules that are safe to load from untrusted sources, for example by making code execution opt-in?
- **Consistent with what exists.** New operations follow the naming, argument and error conventions of the current ones.
- **Learn from other engines; don't copy them blindly.** A feature common elsewhere is evidence, not a requirement.

## Open questions for the maintainer

1. Who is the primary user: developers only, or also non-developers writing rules?
2. Is a stateless engine (the README hints at one) part of the direction?
3. Should untrusted rules ever be supported, and what would that mean for `call`?
4. Are there performance targets?
