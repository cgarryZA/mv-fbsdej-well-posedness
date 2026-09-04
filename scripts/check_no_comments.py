#!/usr/bin/env python3
"""Fail if a TeX file still contains a comment.

A percent sign starts a comment when the run of backslashes immediately
before it has even length: "%" and "\\\\%" are comments, "\\%" is a literal
percent sign.

Usage: check_no_comments.py <file> [<file> ...]
"""
import sys
from pathlib import Path


def comments(path):
    found = []
    for n, line in enumerate(Path(path).read_text(encoding="utf-8",
                                                  errors="replace").splitlines(), 1):
        slashes = 0
        for col, ch in enumerate(line):
            if ch == "\\":
                slashes += 1
            elif ch == "%":
                if slashes % 2 == 0:
                    found.append((n, col + 1, line.strip()[:80]))
                    break
                slashes = 0
            else:
                slashes = 0
    return found


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    bad = False
    for path in sys.argv[1:]:
        found = comments(path)
        if found:
            bad = True
            print(f"FAIL {path}: {len(found)} comment(s)")
            for n, col, text in found[:5]:
                print(f"     line {n} col {col}: {text}")
        else:
            print(f"OK   {path}: no comments")
    if bad:
        sys.exit("FATAL: comments must not reach a submission archive.")


if __name__ == "__main__":
    main()
