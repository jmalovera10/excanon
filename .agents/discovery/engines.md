# Benchmark engines

The curated list of rule engines the Product Lead benchmarks excanon against. Discovery may propose additions it finds while scouting, in its weekly report. Additions land through a PR to this file.

For each engine, scouts record: the rule format, operations, ordering and dependencies, error handling, extension points, notable recent features, and anything excanon lacks or does better. Every claim needs a link to its source.

| Engine | Ecosystem | Why it's on the list | Source |
|---|---|---|---|
| JsonLogic | JavaScript, ported to many languages | The best-known JSON rule format; closest in spirit to excanon's operations | https://github.com/jwadhams/json-logic-js |
| json-rules-engine | JavaScript | JSON rules with facts, events and priorities | https://github.com/CacheControl/json-rules-engine |
| GoRules ZEN | Rust core, with JS, Go and Python bindings | Decision tables and graphs, with business-user focus | https://github.com/gorules/zen |
| Microsoft RulesEngine | .NET | JSON workflows of rules with expression evaluation | https://github.com/microsoft/RulesEngine |
| Grule | Go | A Rete-style engine with its own rule language | https://github.com/hyperjumptech/grule-rule-engine |
| Drools | Java | The reference production-rule system (Rete, decision tables, DMN) | https://github.com/apache/incubator-kie-drools |
| CEL | Go, C++, Java | A safe, non-Turing-complete expression language; relevant to "safe by default" | https://github.com/google/cel-spec |
| Open Policy Agent (Rego) | Go | Policy-as-code with a declarative evaluation model | https://github.com/open-policy-agent/opa |
| Easy Rules | Java | A small, embeddable library, close to excanon's scope | https://github.com/j-easy/easy-rules |
| durable_rules | Python, JS, Ruby | Forward-chaining rules over event streams | https://github.com/jruizgit/rules |
| Hex rule engines | Elixir and Erlang | Scouting finds and lists direct alternatives on Hex | https://hex.pm |
