# Product direction

What excanon is for. Discovery roles judge every idea against this file. The maintainer owns it, and changes go through the impact policy (trigger 7).

## Who it's for

- **Elixir developers** who need business rules that change without a redeploy, such as pricing, discounts, eligibility, policy checks and workflow routing.
- Non-developers are **not** target users for now. Excanon is a technical library. Rules should stay readable, but features, docs and error messages are designed for developers.

## What excanon is

- A **library** embedded in the host application, not a service.
- Offered as a **stateful engine** (rules kept in a process, as today) and, as part of the direction, a **stateless engine** (rules passed in on each evaluation), sharing the same rule format and semantics.
- Rules are **JSON data**: conditions plus actions over a map of facts.
- Evaluation is **deterministic** for the same rules and facts, with explicit ordering (`after`, `requires`).
- Errors come back as **explicit `{:error, reason}` values** at load time, not surprises at evaluation time.

## Goals

1. **Readable rules:** a developer can understand what a rule does from its JSON alone.
2. **Predictable evaluation:** documented semantics for every operation, ordering and dependency.
3. **Small footprint:** few runtime dependencies (today, `jason` and `odgn_json_pointer`).
4. **Stable contract:** semantic versioning. Breaking changes are rare, documented, and come with a migration path.
5. **Competitive performance:** evaluation speed close to the leading rule engines in the benchmark list, measured on comparable rule sets. Performance claims are always backed by reproducible benchmarks.

## Non-goals

- A UI or visual rule editor.
- A distributed or persistent rule service, or a workflow orchestrator.
- A general-purpose programming language inside JSON. New operations must be justifiable as business-rule primitives.
- Rule storage. The host application owns where rules live.

## Principles for new features

- **Prefer data over code.** A feature expressible in rule JSON beats one that needs host Elixir code.
- **Rule trust is the user's responsibility.** Users verify the rules they load (see `SECURITY.md`). Excanon still reduces what a rule can do where it can: the planned direction for `call` is to scope it to module functions within the user's own project, instead of running arbitrary scripts.
- **Consistent with what exists.** New operations follow the naming, argument and error conventions of the current ones.
- **Learn from other engines; don't copy them blindly.** A feature common elsewhere is evidence, not a requirement.
