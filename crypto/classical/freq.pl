#!/usr/bin/env perl
# freq.pl -- dump character frequencies
# usage:
#   $ echo -n 'abcdbafg' | freq.pl

use warnings;
use strict;

use List::Util qw/sum/;

my $d = @ARGV ? shift : do { local $/; <STDIN> };

$d = uc $d;
$d =~ s/[^A-Z]//g;

my @grams = (
	[ Monograms => \&monograms ],
	[ Bigrams   => \&bigrams   ],
	[ Trigrams  => \&trigrams  ],
	[ Quadgrams => \&quadgrams ],
);

for my $gram (@grams) {
	my ($mbtq, $f) = @$gram;
	my %g;
	for my $c ($f->($d)) {
		$g{$c} ||= 0;
		$g{$c} += 1;
	}
	my $t = sum(values %g);
	print "$mbtq:\n";
	for my $c (sort { $g{$b} <=> $g{$a} } keys %g) {
		printf "%s -> %d [%.2f%%]\n", $c, $g{$c}, ($g{$c} / $t) * 100;
	}
}

sub monograms { split //, pop }
sub bigrams   { pop =~ /(?=([a-zA-Z0-9]{2}))/g }
sub trigrams  { pop =~ /(?=([a-zA-Z0-9]{3}))/g }
sub quadgrams { pop =~ /(?=([a-zA-Z0-9]{4}))/g }
