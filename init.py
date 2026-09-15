#!/usr/bin/env python3
"""Scaffold missing module directories from _data/course.yml."""

import ast
import re
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


def main():
    if not COURSE_YML.exists():
        sys.exit(f"error: {COURSE_YML} not found")

    modules = load_modules(COURSE_YML)

    for name in modules:
        slug = slugify(name)
        module_dir = MODULES_DIR / slug

        if module_dir.is_dir():
            print(f"skip:   {slug} (already exists)")
            continue

        posts_dir = module_dir / "_posts"
        posts_dir.mkdir(parents=True)

        intro_file = posts_dir / "2000-01-01-intro.md"
        intro_file.write_text(POST_TEMPLATE.format(title=name.title(), name=name))
        print(f"create: {intro_file.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
