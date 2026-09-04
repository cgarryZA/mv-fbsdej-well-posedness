#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PY=""
for candidate in python3 python; do
  if "$candidate" -c "pass" >/dev/null 2>&1; then PY="$candidate"; break; fi
done
[ -n "$PY" ] || { echo "ABORT: no working python interpreter found" >&2; exit 1; }

OUT="submissions/spa-mvfbsdej-wellposedness-v1-source.zip"
FLAT="submissions/MVFBSDEJ_Wellposedness.tex"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

( cd paper && latexpand wellposedness_spa.tex > "$STAGE/wellposedness_spa.tex" )

"$PY" scripts/check_no_comments.py "$STAGE/wellposedness_spa.tex" >/dev/null \
  || { echo "ABORT: comments survive in the SPA source" >&2; exit 1; }

VERIFY="$(mktemp -d)"
cp "$STAGE/wellposedness_spa.tex" "$VERIFY/"
if ! ( cd "$VERIFY" && pdflatex -interaction=nonstopmode -halt-on-error \
        wellposedness_spa.tex >/dev/null 2>&1 \
     && pdflatex -interaction=nonstopmode -halt-on-error \
        wellposedness_spa.tex >/dev/null 2>&1 ); then
  echo "ABORT: $OUT does not compile standalone" >&2
  ( cd "$VERIFY" && grep -m1 -A4 '^!' wellposedness_spa.log >&2 )
  rm -rf "$VERIFY"; exit 1
fi

pdftotext -q "$VERIFY/wellposedness_spa.pdf" "$VERIFY/render.txt"
for bad in "Appendix Appendix" "Lemma Appendix" "Solution space.."; do
  if grep -qF "$bad" "$VERIFY/render.txt"; then
    echo "ABORT: '$bad' present in the SPA render" >&2
    rm -rf "$VERIFY"; exit 1
  fi
done

pages=$(pdfinfo "$VERIFY/wellposedness_spa.pdf" | awk '/^Pages/{print $2}')
rm -rf "$VERIFY"

mkdir -p submissions
rm -f "$OUT"
( cd "$STAGE" && zip -qX "$OLDPWD/$OUT" wellposedness_spa.tex )
echo "wrote $OUT ($(unzip -l "$OUT" | tail -1 | awk '{print $2}') files; compiles standalone, ${pages} pages)"

# The loose flat TeX is the same staged source the archive carries. Writing it
# here is what keeps it from drifting behind paper/ and the zip.
cp "$STAGE/wellposedness_spa.tex" "$FLAT"
echo "wrote $FLAT (same source as $OUT)"
