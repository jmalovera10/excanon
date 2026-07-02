# Release Guide

This document describes the recommended process for releasing a new version of Excanon.

## 1. Prepare the Release

- Update `CHANGELOG.md` under the `[Unreleased]` section with the new changes.
- Confirm the version in `mix.exs` matches the planned release version.
- Ensure all tests pass:

```bash
mix deps.get
mix test
```

- Review documentation and examples for any changes that should be included in the release.

## 2. Update the Changelog

- Move release notes from `[Unreleased]` into a new section for the version being released.
- Add the release date in `YYYY-MM-DD` format.
- Keep the changelog entries categorized by `Added`, `Changed`, `Fixed`, `Deprecated`, `Removed`, and `Security` as needed.

Example:

```md
## [0.1.1] - 2026-05-01

### Added

- Support for new operation types.

### Fixed

- Corrected JSON Pointer array resolution.
```

## 3. Bump the Version

- Update the version in `mix.exs`.
- If using a release branch, create a branch like `release/v0.1.1`.

## 4. Commit and Tag

- Commit the changelog and version bump with a clear message, such as:

```bash
git add mix.exs CHANGELOG.md
git commit -m "Release v0.1.1"
```

- Create a tag for the release:

```bash
git tag v0.1.1
```

- Push the branch and tag:

```bash
git push origin main --follow-tags
```

## 5. Publish

If publishing to Hex.pm:

- Ensure you are authenticated with Hex: `mix hex.user auth`
- Publish the package:

```bash
mix hex.publish
```

If publishing documentation or other artifacts, follow your normal release workflow.

## 6. Post-Release

- Update `CHANGELOG.md` to prepare the next release by restoring the `[Unreleased]` section if needed.
- Merge any release branches back into the main branch.
- Confirm the release is visible on the project and package registry.

## Notes

- Keep release notes concise and user-focused.
- Avoid publishing experimental or incomplete APIs without clear versioning and compatibility notes.
- For security or hotfix releases, keep the process minimal and clearly document the change.
