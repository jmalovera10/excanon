<!--
Advisory package, written by the Security Response Coordinator to
.embargo/<id>/advisory.md. EMBARGOED: never commit or publish this file. The
maintainer copies its parts into the GitHub security advisory form.
-->

# Advisory package: <neutral id>

**Status:** embargoed · **Severity:** <critical | high | medium | low> · **Target fix date:** <YYYY-MM-DD>

## For the advisory form

- **Title:** <short, factual: what kind of issue, in which feature>
- **Ecosystem and package:** Erlang (Hex), `excanon`
- **Affected versions:** `>= <first affected>, < <fixed version>`
- **Patched version:** `<fixed version>`
- **CVSS 4.0 vector:** `CVSS:4.0/...`, score <n.n>
- **CWE:** CWE-<id>, <name>

### Description

What the issue is, who is affected, and the impact, in plain language. Don't include a working exploit.

### Workarounds

What users can do before upgrading, or "none".

### Credits

The reporter's name or handle, if they want credit.

## How it works (maintainer only)

The root cause, the reproduction, and how the fix closes it. Include a Mermaid diagram if it helps. **This part never goes into the public advisory.**

## Fix

- Patches: `.embargo/<id>/patches/`
- Verification: the commands run and their results, from QA, the Code Reviewer, the Security Engineer and the API Steward
- Compatibility: the API Steward's verdict, and the migration note if behavior changes

## Changelog entry (publish with the release)

```markdown
### Security

- <one line, without exploit details; link the advisory once it's public>
```

## Maintainer checklist

1. [ ] Create a draft security advisory in GitHub (**Security → Advisories → New draft**) and copy in the form fields above.
2. [ ] Request a CVE from the draft advisory.
3. [ ] Create the advisory's temporary private fork, apply the patches (`git am .embargo/<id>/patches/*.patch`), and push to it.
4. [ ] Merge the fix from the private fork.
5. [ ] Release the patched version: bump the version, move the changelog entry into the release section, tag, then `mix hex.publish`.
6. [ ] Retire the affected versions: `mix hex.retire excanon <version> security --message "<one line, link to advisory>"`.
7. [ ] Publish the advisory.
8. [ ] Delete `.embargo/<id>/` once everything is public.
