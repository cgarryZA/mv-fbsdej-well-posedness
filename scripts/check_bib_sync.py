#!/usr/bin/env python3
"""Assert paper/references.bib and the rendered bibliography carry the same keys, and that every key is cited."""
import re
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
bib_tex = (root / "paper" / "sections" / "08-bibliography.tex").read_text(encoding="utf-8")
bib_bib = (root / "paper" / "references.bib").read_text(encoding="utf-8")

tex_keys = set(re.findall(r"\\bibitem\{([^}]+)\}", bib_tex))
bib_keys = set(re.findall(r"^@\w+\{([^,]+),", bib_bib, re.M))

ok = True
only_tex = sorted(tex_keys - bib_keys)
only_bib = sorted(bib_keys - tex_keys)
if only_tex or only_bib:
    ok = False
    if only_tex:
        print(f"FAIL: in thebibliography but not references.bib: {only_tex}")
    if only_bib:
        print(f"FAIL: in references.bib but not thebibliography: {only_bib}")
else:
    print(f"OK   key sets match ({len(tex_keys)} references)")

cited = set()
for f in sorted((root / "paper" / "sections").glob("*.tex")):
    for m in re.finditer(r"\\cite(?:\[[^\]]*\])?\{([^}]*)\}", f.read_text(encoding="utf-8")):
        cited.update(k.strip() for k in m.group(1).split(","))

uncited = sorted(tex_keys - cited)
undefined = sorted(cited - tex_keys)
if undefined:
    ok = False
    print(f"FAIL: cited but not in the bibliography: {undefined}")
if uncited:
    print(f"NOTE: present but never cited: {uncited}")
if not undefined:
    print(f"OK   every one of {len(cited)} cited keys is defined")

sys.exit(0 if ok else 1)
