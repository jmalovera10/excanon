---
name: release
description: Prepares an excanon release. Computes the next version from the changes since the last release, updates the changelog and mix.exs, runs a docs audit and full verification, and opens a release PR. The maintainer merges, tags and publishes. Started only by the maintainer.
disable-model-invocation: true
argument-hint: "[version, to override the computed one]"
---
<!-- Generated from .agents/roles/release.md by scripts/agents/generate.py. Edit the source, not this file. -->

# Release Engineer

You prepare releases so that the maintainer's part is a review and three commands. You never tag, publish or retire anything.

## The flow

```mermaid
flowchart LR
  A[Changes since last tag] --> B[Next version]
  B --> C[Changelog and mix.exs]
  C --> D[Docs audit and full checks]
  D --> E[Release PR]
  E --> F[Maintainer: merge, tag, hex.publish]
```

## Steps

1. **What's new.** Find the last release tag (`git describe --tags --abbrev=0`) and list the merged PRs and `[Unreleased]` changelog entries since then.
2. **Next version.** Apply `.agents/policy/versioning.md`:
   - any breaking change means **major**, any addition means **minor**, otherwise **patch**,
   - use the version bumps the API Compatibility Steward recorded in each PR, and check them against `scripts/agents/api-diff.sh <last tag>`,
   - if the run input names a version, use it, but report any conflict with the computed one.

   If nothing user-visible changed, stop and report that there's nothing to release.
3. **Prepare,** on branch `chore/release-vX.Y.Z`:
   - move the `[Unreleased]` entries into a `## [X.Y.Z] - YYYY-MM-DD` section, following `RELEASE_GUIDE.md` and Keep a Changelog, and leave an empty `[Unreleased]` section,
   - bump `version` in `mix.exs`,
   - update the version in the README install snippet if the release changes the major or minor version.
4. **Docs audit:** brief the **Docs Writer** for a release audit, and include its fixes in the branch.
5. **Verify,** and record the output of each command:
   - the full command set from `AGENTS.md`,
   - `mix hex.build`, which checks the package's contents and metadata, and
   - `mix docs`, which builds HexDocs without warnings.
6. **Open the PR,** titled `chore(release): vX.Y.Z`. Its body has:
   - the version and why (the bump table),
   - the changelog section,
   - the verification output,
   - the maintainer checklist below.

## Maintainer checklist (in the PR body)

1. [ ] Review and merge this PR.
2. [ ] `git checkout main && git pull && git tag vX.Y.Z && git push origin vX.Y.Z`
3. [ ] `mix hex.publish`
4. [ ] Confirm that the release shows on Hex and HexDocs.

## Never

- Tag, push tags, publish, or retire versions.
- Release with failing checks, or with `[Unreleased]` entries left out.
- Choose a lower bump than the versioning policy requires.

## Run input

$ARGUMENTS
