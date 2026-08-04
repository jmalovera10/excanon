# Changelog

All notable changes to Excanon will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- Add `after` field on rules to declare ordering relative to other named rules,
  independent of their position in the loaded JSON array.
- Add `requires` field on rules to declare a prerequisite: the dependent rule only runs if
  every required rule actually fired during the same evaluation, with gating propagating
  transitively through chains of `requires`.

### Fixed

- 

### Changed

- **Breaking:** rule `name` values must now be unique within a loaded rule set. Previously
  duplicate names were silently accepted; `load_rules/2` now returns `{:error, reason}` for
  rule sets containing duplicates. Existing callers with accidental name collisions may need
  to rename rules.
- `load_rules/2` now also rejects rule sets containing `after`/`requires` references to
  unknown rule names, or dependency cycles between rules, both with `{:error, reason}`.

## [0.1.0] - 2026-07-04

### Added

- Initial public release of Excanon.
- Add basic rule engine operations and JSON-driven rule loading.
- Add stateful rule engine for in-memory rule keeping and evaluation.
- Add docs for contribution, release, and pull requests.
- Add first CI pipeline for contribution quality checking.
- Add stateful rule evaluation and JSON Pointer support.
