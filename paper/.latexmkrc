use File::Copy ();
use File::Basename ();
use File::Path ();

my $manuscript = 'mvfbsdej-wellposedness';
my $spa_release = 'MVFBSDEJ_Wellposedness';

sub refresh_deliverable {
  my ($pdf) = @_;
  my $base = File::Basename::basename($pdf);

  if ($base eq 'wellposedness.pdf') {
    File::Copy::copy($pdf, "../$manuscript.pdf") or die "deliverable copy failed: $!\n";
    print "-> refreshed root deliverable\n";
    if (system('bash', '../scripts/make_arxiv_abstracts.sh') != 0) {
      die "latexmkrc: make_arxiv_abstracts.sh failed -- the tracked metadata abstract would be stale\n";
    }
  }
  elsif ($base eq 'wellposedness_spa.pdf') {
    my $out = "../submissions/$spa_release.pdf";
    if ($ENV{'PAPER_RELEASE'}) {
      File::Path::make_path('../submissions');
      File::Copy::copy($pdf, $out) or die "SPA copy failed: $!\n";
      print "-> refreshed $out (PAPER_RELEASE)\n";
    }
    else {
      print "latexmkrc: SPA build OK; tracked submissions/ copy NOT refreshed (set PAPER_RELEASE=1 to refresh)\n";
    }
  }
  else {
    print "latexmkrc: unrecognised master '$base' -- no tracked PDF updated\n";
  }
  return 0;
}

$success_cmd = 'internal refresh_deliverable %D';

