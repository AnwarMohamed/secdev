#!/usr/bin/env perl
# freq.pl -- dump character frequency
# usage:
#   $ echo -n 'abcdbafg' | freq.pl

use warnings;
use strict;

my $d = do { local $/; <STDIN> };
my %f;
$f{ord$_}++ for split //, $d;

for my $k (sort { $a <=> $b } keys %f) {
	if (chr($k) =~ /[[:print:]]/) {
		printf "%-4c -> %s\n", $k, $f{$k}
	} else {
		printf "0x%02x -> %s\n", $k, $f{$k}
	}
}
