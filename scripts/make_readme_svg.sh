#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PY=""
for candidate in python3 python; do
  if "$candidate" -c "pass" >/dev/null 2>&1; then PY="$candidate"; break; fi
done
[ -n "$PY" ] || { echo "ABORT: no working python interpreter found" >&2; exit 1; }
mkdir -p assets

ABSTRACT_SRC="paper/wellposedness.tex"
EQUATION_SRC="paper/sections/01-introduction.tex"

extract() {
  "$PY" - "$1" "$2" <<'PY'
import re, sys
path, what = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
if what == "abstract":
    m = re.search(r"\\begin\{abstract\}(.*?)\\end\{abstract\}", text, re.S)
    if not m:
        sys.exit("FATAL: no abstract in " + path)
    print(m.group(1).strip())
else:
    m = re.search(r"\\PaperSystemBox\{(.*?)\n\\end\{equation\}", text, re.S)
    if not m:
        sys.exit("FATAL: no system display in " + path)
    print(m.group(1).rsplit("}", 1)[0].strip())
PY
}

render() {
  local out="$1" colour="$2" mode="$3" body="$4" d
  d="$(mktemp -d)"
  {
    if [ "$mode" = "abstract" ]; then
      echo '\documentclass[12pt,varwidth=15.5cm,border=8pt]{standalone}'
    else
      echo '\documentclass[12pt,border=8pt,preview]{standalone}'
    fi
    echo '\usepackage{amsmath,amssymb}'
    echo '\usepackage[T1]{fontenc}'
    echo '\usepackage{lmodern}'
    echo '\usepackage{xcolor}'
    echo '\newcommand{\diff}{\mathrm{d}}'
    echo '\newcommand{\Nt}{\widetilde{N}}'
    echo '\newcommand{\Law}{\mathrm{Law}}'
    echo '\newcommand{\Lnu}{L^2(\nu)}'
    echo "\\color{$colour}"
    echo '\begin{document}'
    if [ "$mode" = "abstract" ]; then
      printf '%s\n' "$body"
    else
      echo '$\displaystyle'
      printf '%s\n' "$body"
      echo '$'
    fi
    echo '\end{document}'
  } > "$d/snippet.tex"
  if ! ( cd "$d" && latex -interaction=nonstopmode -halt-on-error snippet.tex >/dev/null 2>&1 ); then
    echo "ABORT: $mode snippet did not compile" >&2
    sed -n '/^!/,+5p' "$d/snippet.log" >&2
    rm -rf "$d"
    exit 1
  fi
  dvisvgm --no-fonts --exact --output="$out" "$d/snippet.dvi" >/dev/null 2>&1
  rm -rf "$d"
  echo "  $out ($(wc -c < "$out") bytes)"
}

ABSTRACT="$(extract "$ABSTRACT_SRC" abstract)"
EQUATION="$(extract "$EQUATION_SRC" equation)"

render assets/abstract-light.svg black abstract "$ABSTRACT"
render assets/abstract-dark.svg white abstract "$ABSTRACT"
render assets/system-light.svg black equation "$EQUATION"
render assets/system-dark.svg white equation "$EQUATION"
