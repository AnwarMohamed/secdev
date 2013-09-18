#!/usr/bin/env perl
# coltr.pl -- tool for analysing columnar transposition ciphertext
# usage:
#   $ echo -n 'abcdefghi' | coltr.pl -c 3 -o 3,1,2
#   gad
#   hbe
#   icf

use warnings;
use strict;

use Getopt::Long;

my $columns = 1;
my $key;

GetOptions(
	'c|columns=s' => \$columns,
	'k|keys'      => \$key,
);

my $ciphertext = do { local $/; <STDIN> };
$ciphertext =~ s/[^a-zA-Z]//g;

my $y_max = (length($ciphertext) / $columns) - 1;

my @order = 0 .. $columns - 1;
if ($key) {
	@order = map { int($_) - 1 } split /,/, $key;
}

my @grid;
my ($x,$y) = (0,0);
foreach my $char (split //, $ciphertext) {
	$grid[$y][$x] = $char;

	if ($y >= $y_max) {
		$y = 0;
		$x += 1;
	}
	else {
		$y += 1;
	}
}

foreach my $row (@grid) {
	foreach my $col (@order) {
		print $row->[$col] if defined $row->[$col];
	}
	print "\n";
}
