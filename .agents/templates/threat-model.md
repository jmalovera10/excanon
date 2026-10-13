<!--
Threat model, written by the Security Engineer from the spec and posted on the
backlog ticket. Keep it proportional: a short one for small changes. Never post
details of an unpublished vulnerability here. Those follow the embargoed
security response workflow.
-->

## Threat model: <ticket title>

**Spec:** <link>

### What's exposed

Where untrusted or semi-trusted input enters: rule JSON, facts, paths, script calls. And what it can reach.

### Threats

| # | Threat | Example | Likelihood | Impact | Mitigation in the spec |
|---|---|---|---|---|---|
| 1 | | | low / med / high | low / med / high | |

Always consider:
- code execution (`call`, `Code.eval_*`),
- resource exhaustion (deep nesting, huge lists, cycles),
- atom creation from input,
- path traversal,
- information leaks through logs or errors.

### Required tests

Security-relevant cases QA must add to the test plan.

### Verdict

`acceptable`, `acceptable with the mitigations above`, or `needs redesign`, with a reason.
