#!/usr/bin/env python3
"""Generate tool-specific agent files from the canonical definitions in .agents/.

Claude Code adapter:
  .agents/roles/<name>.md with `runs-as: main`  ->  .claude/skills/<name>/SKILL.md
  .agents/skills/<name>/**                     ->  .claude/skills/<name>/**

Usage:
  scripts/agents/generate.py           write the generated files
  scripts/agents/generate.py --check   exit 1 if the generated files are missing or stale
"""

import shutil
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / ".agents"
TARGET = ROOT / ".claude" / "skills"
NOTICE = "<!-- Generated from {src} by scripts/agents/generate.py. Edit the source, not this file. -->\n"
REQUIRED_ROLE_KEYS = ("name", "description", "tier", "runs-as")
TIERS = ("judgment", "standard", "fast")


def split_frontmatter(text, path):
    if not text.startswith("---\n"):
        sys.exit(f"{path}: missing frontmatter")
    end = text.index("\n---\n", 4)
    meta = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if not sep:
            sys.exit(f"{path}: bad frontmatter line {line!r}")
        meta[key.strip()] = value.strip()
    return meta, text[end + 5 :]


def skill_file(meta, body, src):
    head = f"---\nname: {meta['name']}\ndescription: {meta['description']}\n---\n"
    return head + NOTICE.format(src=src) + body


def build(out):
    names = {}

    for role in sorted((SOURCE / "roles").glob("*.md")):
        rel = role.relative_to(ROOT)
        meta, body = split_frontmatter(role.read_text(), rel)
        missing = [k for k in REQUIRED_ROLE_KEYS if k not in meta]
        if missing:
            sys.exit(f"{rel}: missing frontmatter keys {missing}")
        if meta["name"] != role.stem:
            sys.exit(f"{rel}: name must match the file name")
        if meta["tier"] not in TIERS:
            sys.exit(f"{rel}: tier must be one of {TIERS}")
        if meta["runs-as"] != "main":
            sys.exit(f"{rel}: runs-as {meta['runs-as']!r} has no Claude Code adapter yet")
        names[meta["name"]] = rel
        dest = out / meta["name"] / "SKILL.md"
        dest.parent.mkdir(parents=True)
        dest.write_text(skill_file(meta, body, rel))

    for skill_dir in sorted(p for p in (SOURCE / "skills").iterdir() if p.is_dir()):
        rel = skill_dir.relative_to(ROOT)
        if skill_dir.name in names:
            sys.exit(f"{rel}: name collides with {names[skill_dir.name]}")
        names[skill_dir.name] = rel
        for src in sorted(p for p in skill_dir.rglob("*") if p.is_file()):
            dest = out / skill_dir.name / src.relative_to(skill_dir)
            dest.parent.mkdir(parents=True, exist_ok=True)
            if src.name == "SKILL.md":
                meta, body = split_frontmatter(src.read_text(), src.relative_to(ROOT))
                if meta.get("name") != skill_dir.name or "description" not in meta:
                    sys.exit(f"{src.relative_to(ROOT)}: needs name matching its folder and a description")
                dest.write_text(skill_file(meta, body, src.relative_to(ROOT)))
            else:
                shutil.copyfile(src, dest)


def files(root):
    return {p.relative_to(root): p.read_bytes() for p in root.rglob("*") if p.is_file()} if root.exists() else {}


def main():
    check = sys.argv[1:] == ["--check"]
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "skills"
        out.mkdir()
        build(out)
        if check:
            expected, actual = files(out), files(TARGET)
            stale = sorted(str(p) for p in expected.keys() | actual.keys() if expected.get(p) != actual.get(p))
            if stale:
                print("Generated agent files are out of date. Run scripts/agents/generate.py and commit:")
                print("\n".join(f"  .claude/skills/{p}" for p in stale))
                sys.exit(1)
            print("Generated agent files are up to date.")
        else:
            shutil.rmtree(TARGET, ignore_errors=True)
            shutil.copytree(out, TARGET)
            print(f"Wrote {len(files(TARGET))} files to {TARGET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
