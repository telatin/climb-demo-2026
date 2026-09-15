#!/usr/bin/env python3
"""Scaffold missing module directories from _data/course.yml.

Also audits modules/ for two kinds of drift:
  - stray *.md files directly inside modules/{module}/ (should live in _posts/)
  - module directories not declared in _data/course.yml

Pass --clean to delete both kinds of drift instead of just warning.
"""

import argparse
import ast
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
COURSE_YML = ROOT / "_data" / "course.yml"
MODULES_DIR = ROOT / "modules"

POST_TEMPLATE = """---
title: {title}
---

## {title}

TODO: write an introduction for the "{name}" module.
"""


def slugify(name):
    slug = name.strip().lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug)
    return slug.strip("-")


def load_modules(path):
    for line in path.read_text().splitlines():
        line = line.strip()
        if line.startswith("modules:"):
            return ast.literal_eval(line.split(":", 1)[1].strip())
    raise ValueError(f"no 'modules:' entry found in {path}")


def scaffold_missing_modules(modules):
    print(f"\n== Scaffolding modules declared in {COURSE_YML.relative_to(ROOT)} ==")
    slugs = set()

    for name in modules:
        slug = slugify(name)
        slugs.add(slug)
        module_dir = MODULES_DIR / slug

        print(f"checking module {name!r} -> expected dir modules/{slug}")

        if module_dir.is_dir():
            print(f"  skip:   modules/{slug} already exists")
            continue

        posts_dir = module_dir / "_posts"
        print(f"  create: modules/{slug}/_posts (missing, creating now)")
        posts_dir.mkdir(parents=True)

        intro_file = posts_dir / "2000-01-01-intro.md"
        intro_file.write_text(POST_TEMPLATE.format(title=name.title(), name=name))
        print(f"  create: {intro_file.relative_to(ROOT)}")

    return slugs


def find_stray_md_files(module_dir):
    """*.md files directly inside module_dir (not inside module_dir/_posts)."""
    return sorted(p for p in module_dir.glob("*.md") if p.is_file())


def audit_modules(expected_slugs, clean):
    print("\n== Auditing modules/ for stray files and undeclared modules ==")

    if not MODULES_DIR.is_dir():
        print(f"  modules/ directory not found at {MODULES_DIR}, skipping audit")
        return

    module_dirs = sorted(p for p in MODULES_DIR.iterdir() if p.is_dir())
    print(f"found {len(module_dirs)} module director{'y' if len(module_dirs) == 1 else 'ies'} on disk")

    stray_count = 0
    unused_count = 0

    for module_dir in module_dirs:
        slug = module_dir.name
        print(f"\ninspecting modules/{slug}")

        # 1) stray *.md files that should be under _posts/
        stray_files = find_stray_md_files(module_dir)
        for stray in stray_files:
            stray_count += 1
            print(f"  WARNING: {stray.relative_to(ROOT)} is a .md file outside _posts/")
            if clean:
                print(f"    removing (--clean): {stray.relative_to(ROOT)}")
                stray.unlink()

        # 2) module directories not declared in course.yml
        if slug not in expected_slugs:
            unused_count += 1
            print(f"  WARNING: modules/{slug} is not declared in {COURSE_YML.relative_to(ROOT)}")
            if clean:
                print(f"    removing (--clean): modules/{slug}")
                shutil.rmtree(module_dir)

    print("\n== Audit summary ==")
    print(f"stray .md files outside _posts/: {stray_count}{' (removed)' if clean and stray_count else ''}")
    print(f"module dirs not in course.yml:   {unused_count}{' (removed)' if clean and unused_count else ''}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--clean",
        action="store_true",
        help="delete stray *.md files outside _posts/ and module dirs not in course.yml",
    )
    args = parser.parse_args()

    print(f"init.py starting (clean={args.clean})")
    print(f"root:       {ROOT}")
    print(f"course.yml: {COURSE_YML}")
    print(f"modules:    {MODULES_DIR}")

    if not COURSE_YML.exists():
        sys.exit(f"error: {COURSE_YML} not found")

    modules = load_modules(COURSE_YML)
    print(f"loaded {len(modules)} module(s) from course.yml: {modules}")

    expected_slugs = scaffold_missing_modules(modules)
    audit_modules(expected_slugs, clean=args.clean)

    print("\ndone.")


if __name__ == "__main__":
    main()
