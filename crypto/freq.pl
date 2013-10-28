#!/usr/bin/env perl
# freq.pl -- dump character frequencies
# usage:
#   $ echo -n 'abcdbafg' | freq.pl

use warnings;
use strict;

my $d = @ARGV ? shift : do { local $/; <STDIN> };

$d = uc $d;
$d =~ s/[^A-Z]//g;

my %mg;
for my $c (monograms($d)) {
	$mg{$c} ||= 0;
	$mg{$c} += 1;
}
print "Monograms:\n";
for my $c (sort { $mg{$b} <=> $mg{$a} } keys %mg) {
	printf "%s -> %d\n", $c, $mg{$c};
}

my %bg;
for my $c (bigrams($d)) {
	$bg{$c} ||= 0;
	$bg{$c} += 1;
}
print "Bigrams:\n";
for my $c (sort { $bg{$b} <=> $bg{$a} } keys %bg) {
	printf "%s -> %d\n", $c, $bg{$c};
}

my %tg;
for my $c (trigrams($d)) {
	$tg{$c} ||= 0;
	$tg{$c} += 1;
}
print "Trigrams:\n";
for my $c (sort { $tg{$b} <=> $tg{$a} } keys %tg) {
	printf "%s -> %d\n", $c, $tg{$c};
}

my %qg;
for my $c (quadgrams($d)) {
	$qg{$c} ||= 0;
	$qg{$c} += 1;
}
print "Quadgrams:\n";
for my $c (sort { $qg{$b} <=> $qg{$a} } keys %qg) {
	printf "%s -> %d\n", $c, $qg{$c};
}

sub monograms { split //, pop }
sub bigrams   { pop =~ /(?=([a-zA-Z0-9]{2}))/g }
sub trigrams  { pop =~ /(?=([a-zA-Z0-9]{3}))/g }
sub quadgrams { pop =~ /(?=([a-zA-Z0-9]{4}))/g }
