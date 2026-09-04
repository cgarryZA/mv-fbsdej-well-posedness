#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

MAXLEN=1920

gen () {
  local src="$1" out="$2"
  [ -f "$src" ] || { echo "ERROR: source not found: $src" >&2; exit 1; }

  local text
  text="$(perl -0777 -e '
    my $s = do { local $/; <STDIN> };

    $s =~ /\\begin\{abstract\}(.*?)\\end\{abstract\}/s
      or die "no abstract environment found\n";
    $s = $1;

    $s =~ s/(?<!\\)%.*$//mg;

    $s =~ s/\\Lnorm\{([^{}]*)\}/\\lVert $1\\rVert_{L^2(\\nu)}/g;
    my %m = (
      "Lnu"   => "L^2(\\nu)",
      "Gstar" => "G^{\\top}",
      "Law"   => "\\mathrm{Law}",
      "R"     => "\\mathbb{R}",
      "E"     => "\\mathbb{E}",
    );
    for my $k (sort { length($b) <=> length($a) } keys %m) {
      my $v = $m{$k};
      $s =~ s/\\\Q$k\E(?![A-Za-z])/{$v}/g;
    }

    $s =~ s/---/\x{2014}/g;
    $s =~ s/--/\x{2013}/g;
    $s =~ s/~/ /g;

    $s =~ s/\s+/ /g;
    $s =~ s/^\s+|\s+$//g;

    binmode(STDOUT, ":encoding(UTF-8)");
    print $s;
  ' < "$src")"

  local leaked
  leaked="$(printf '%s' "$text" | perl -0777 -e '
    my $body = do { local $/; <STDIN> };
    open my $fh, "<", $ARGV[0] or die;
    my $tex = do { local $/; <$fh> };
    my %local;
    while ($tex =~ /\\(?:re)?newcommand\*?\{\\([A-Za-z]+)\}/g) { $local{$1}=1 }
    while ($tex =~ /\\DeclareMathOperator\*?\{\\([A-Za-z]+)\}/g) { $local{$1}=1 }
    my %hit;
    while ($body =~ /\\([A-Za-z]+)/g) { $hit{$1}=1 if $local{$1} }
    print join(",", sort keys %hit);
  ' "$src")"
  if [ -n "$leaked" ]; then
    echo "ERROR: unexpanded local macro(s) in $out: \\${leaked//,/ \\}" >&2
    echo "       add a MathJax mapping for them in scripts/make_arxiv_abstracts.sh" >&2
    exit 1
  fi

  local n
  n="$(printf '%s' "$text" | perl -CS -ne 'print length($_)')"
  if [ "$n" -gt "$MAXLEN" ]; then
    echo "ERROR: $out is $n chars, over the $MAXLEN arXiv budget by $((n-MAXLEN))" >&2
    exit 1
  fi

  printf '%s\n' "$text" > "$out"
  echo "wrote $out ($n / $MAXLEN chars)"
}

gen paper/wellposedness.tex paper/wellposedness-arxiv-abstract.txt
