#!/usr/bin/env python3
"""Assert every format numbers the paper's own statements identically.

Compares the label-to-number mappings recorded in each format's .aux file, for
labels naming a numbered statement (ass:, def:, thm:, prop:, lem:, cor:, rem:,
ex:). Reading the .aux rather than the rendered text means citations to other
works cannot be mistaken for the paper's own statements.

Usage: check_paper_formats.py <aux> [<aux> ...]
"""
import re
import sys
from pathlib import Path

PREFIXES = ("ass", "def", "thm", "prop", "lem", "cor", "rem", "ex")
NEWLABEL = re.compile(r"\\newlabel\{([^}]+)\}\{\{([^{}]*)\}")


def numbering(path):
    text = Path(path).read_text(encoding="utf-8", errors="replace")
    found = {}
    for label, number in NEWLABEL.findall(text):
        if label.endswith("@cref") or ":" not in label:
            continue
        if label.split(":", 1)[0] in PREFIXES:
            found[label] = number
    return found


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    reference = ref_path = None
    ok = True
    for path in sys.argv[1:]:
        found = numbering(path)
        if not found:
            sys.exit(f"FATAL: no statement labels in {path}")
        if reference is None:
            reference, ref_path = found, path
            print(f"OK   {path}: {len(found)} numbered statements (reference)")
            continue
        if found == reference:
            print(f"OK   {path}: {len(found)} numbered statements, identical to {ref_path}")
            continue
        ok = False
        print(f"FAIL {path}: numbering differs from {ref_path}")
        for label in sorted(set(reference) | set(found)):
            a, b = reference.get(label), found.get(label)
            if a != b:
                print(f"     {label}: {ref_path} has {a!r}, {path} has {b!r}")
    if not ok:
        sys.exit("FATAL: statement numbering differs between formats.")


if __name__ == "__main__":
    main()
