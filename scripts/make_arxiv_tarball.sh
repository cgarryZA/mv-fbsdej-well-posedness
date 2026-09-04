#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PY=""
for candidate in python3 python; do
  if "$candidate" -c "pass" >/dev/null 2>&1; then PY="$candidate"; break; fi
done
[ -n "$PY" ] || { echo "ABORT: no working python interpreter found" >&2; exit 1; }

bash scripts/make_arxiv_abstracts.sh

mkdir -p submissions
OUT_A="submissions/arxiv-mvfbsdej-wellposedness-v1-source.tar.gz"
STAGE_A="$(mktemp -d)"
trap 'rm -rf "$STAGE_A"' EXIT
( cd paper && latexpand wellposedness.tex > "$STAGE_A/wellposedness.tex" )
"$PY" scripts/check_no_comments.py "$STAGE_A/wellposedness.tex" >/dev/null \
  || { echo "ABORT: comments survive in the arXiv source" >&2; exit 1; }

sed -i 's/margin=2\.45cm/margin=1in/' "$STAGE_A/wellposedness.tex"
sed -i 's/\\usepackage{setspace}//g; s/\\setstretch{1\.15}//g' "$STAGE_A/wellposedness.tex"
grep -q 'margin=1in' "$STAGE_A/wellposedness.tex" \
  || { echo "ABORT: arXiv margin adjustment did not apply" >&2; exit 1; }
if grep -qE '\\setstretch|\\usepackage\{setspace\}' "$STAGE_A/wellposedness.tex"; then
  echo "ABORT: line-spacing adjustment did not apply to the arXiv source" >&2; exit 1
fi

VERIFY="$(mktemp -d)"
cp "$STAGE_A/wellposedness.tex" "$VERIFY/"
if ! ( cd "$VERIFY" && pdflatex -interaction=nonstopmode -halt-on-error \
        wellposedness.tex >/dev/null 2>&1 ); then
  echo "ABORT: the staged arXiv source does not compile standalone" >&2
  ( cd "$VERIFY" && grep -m1 -A4 '^!' wellposedness.log >&2 )
  rm -rf "$VERIFY"; exit 1
fi
pages=$(pdfinfo "$VERIFY/wellposedness.pdf" | awk '/^Pages/{print $2}')
rm -rf "$VERIFY"

tar --owner=0 --group=0 --numeric-owner --mtime='@0' \
    -czf "$OUT_A" -C "$STAGE_A" wellposedness.tex
echo "wrote $OUT_A ($(tar tzf "$OUT_A" | wc -l) files; compiles standalone, ${pages} pages)"
