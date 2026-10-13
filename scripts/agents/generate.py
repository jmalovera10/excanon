#!/usr/bin/env python3
"""Generate tool-specific agent files from the canonical definitions in .agents/.

Claude Code adapter:
  .agents/roles/<name>.md, runs-as: main      ->  .claude/skills/<name>/SKILL.md
  .agents/roles/<name>.md, runs-as: subagent  ->  .claude/agents/<name>.md
  .agents/workflows/<name>.md                 ->  .claude/skills/<name>/SKILL.md
  .agents/skills/<name>/**                    ->  .claude/skills/<name>/**

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
MANAGED = ("skills", "agents")  # subfolders of .claude/ owned by this script
NOTICE = "<!-- Generated from {src} by scripts/agents/generate.py. Edit the source, not this file. -->\n"
REQUIRED_KEYS = ("name", "description", "tier", "runs-as")
MODELS = {"judgment": "opus", "standard": "sonnet", "fast": "haiku"}
ACCESS = {"read-only": "Edit, Write, NotebookEdit", "write": None}


def fail(message):
    sys.exit(message)


def split_frontmatter(path):
    text = path.read_text()
    rel = path.relative_to(ROOT)
    if not text.startswith("---\n"):
        fail(f"{rel}: missing frontmatter")
    end = text.index("\n---\n", 4)
    meta = {}
    for line in text[4:end].splitlines():
        key, sep, value = line.partition(":")
        if not sep:
            fail(f"{rel}: bad frontmatter line {line!r}")
        meta[key.strip()] = value.strip()
    return meta, text[end + 5 :], rel


def validate(meta, rel, stem):
    missing = [k for k in REQUIRED_KEYS if k not in meta]
    if missing:
        fail(f"{rel}: missing frontmatter keys {missing}")
    if meta["name"] != stem:
        fail(f"{rel}: name must match the file name")
    if meta["tier"] not in MODELS:
        fail(f"{rel}: tier must be one of {tuple(MODELS)}")
    if meta["runs-as"] not in ("main", "subagent"):
        fail(f"{rel}: runs-as must be main or subagent")
    if meta.get("invocation", "auto") not in ("manual", "auto"):
        fail(f"{rel}: invocation must be manual or auto")
    if meta.get("access", "write") not in ACCESS:
        fail(f"{rel}: access must be one of {tuple(ACCESS)}")


def skill_file(meta, body, rel, takes_input):
    head = f"---\nname: {meta['name']}\ndescription: {meta['description']}\n"
    if meta.get("invocation") == "manual":
        head += "disable-model-invocation: true\n"
    if "argument-hint" in meta:
        head += f"argument-hint: {meta['argument-hint']}\n"
    head += "---\n" + NOTICE.format(src=rel)
    if takes_input:
        body += "\n## Run input\n\n$ARGUMENTS\n"
    return head + body


def agent_file(meta, body, rel):
    head = f"---\nname: {meta['name']}\ndescription: {meta['description']}\nmodel: {MODELS[meta['tier']]}\n"
    denied = ACCESS[meta.get("access", "write")]
    if denied:
        head += f"disallowedTools: {denied}\n"
    return head + "---\n" + NOTICE.format(src=rel) + body


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)


def build(out):
    names = {}

    def claim(name, rel):
        if name in names:
            fail(f"{rel}: name collides with {names[name]}")
        names[name] = rel

    for folder in ("roles", "workflows"):
        for path in sorted((SOURCE / folder).glob("*.md")):
            meta, body, rel = split_frontmatter(path)
            validate(meta, rel, path.stem)
            if folder == "workflows" and meta["runs-as"] != "main":
                fail(f"{rel}: workflows must run as main")
            claim(meta["name"], rel)
            if meta["runs-as"] == "main":
                write(out / "skills" / meta["name"] / "SKILL.md", skill_file(meta, body, rel, True))
            else:
                write(out / "agents" / f"{meta['name']}.md", agent_file(meta, body, rel))

    for skill_dir in sorted(p for p in (SOURCE / "skills").iterdir() if p.is_dir()):
        claim(skill_dir.name, skill_dir.relative_to(ROOT))
        for src in sorted(p for p in skill_dir.rglob("*") if p.is_file()):
            dest = out / "skills" / skill_dir.name / src.relative_to(skill_dir)
            if src.name == "SKILL.md":
                meta, body, rel = split_frontmatter(src)
                if meta.get("name") != skill_dir.name or "description" not in meta:
                    fail(f"{rel}: needs a name matching its folder and a description")
                write(dest, skill_file(meta, body, rel, False))
            else:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(src, dest)


def files(root):
    found = {}
    for sub in MANAGED:
        base = root / sub
        if base.exists():
            found.update({p.relative_to(root): p.read_bytes() for p in base.rglob("*") if p.is_file()})
    return found


def main():
    check = sys.argv[1:] == ["--check"]
    target = ROOT / ".claude"
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        build(out)
        expected = files(out)
        if check:
            actual = files(target)
            stale = sorted(str(p) for p in expected.keys() | actual.keys() if expected.get(p) != actual.get(p))
            if stale:
                print("Generated agent files are out of date. Run scripts/agents/generate.py and commit:")
                print("\n".join(f"  .claude/{p}" for p in stale))
                sys.exit(1)
            print("Generated agent files are up to date.")
            return
        for sub in MANAGED:
            shutil.rmtree(target / sub, ignore_errors=True)
            if (out / sub).exists():
                shutil.copytree(out / sub, target / sub)
        print(f"Wrote {len(expected)} files to .claude/")


if __name__ == "__main__":
    main()
