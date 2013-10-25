#!/usr/bin/env perl
# ic.pl -- index of coincidence analysis
# https://en.wikipedia.org/wiki/Index_of_coincidence
#
# Example usage:
#  $ ic.pl QPWKALVRXCQZIKGRBPFAEOMFLJMSDZVDHXCXJYEBIMTRQWNMEAIZRVKCVKVLXNEICFZPZCZZHKMLVZVZIZRRQWDKECHOSNYXXLSPMYKVQXJTDCIOMEEXDQVSRXLRLKZHOV -k 10
#  k = 1, i.c. = 0.043
#  k = 2, i.c. = 0.046
#  k = 3, i.c. = 0.040
#  k = 4, i.c. = 0.045
#  k = 5, i.c. = 0.070
#  k = 6, i.c. = 0.038
#  k = 7, i.c. = 0.039
#  k = 8, i.c. = 0.040
#  k = 9, i.c. = 0.045
#  k = 10, i.c. = 0.079
#
# `k' represents the key length for a substitution cipher. Generally, any values
# near to 0.067 (the index of coincidence for the English language) represent
# significant data, as this probably indicates the key length for the
# ciphertext, and cracking can begin. Lower values (around 1/26 = 0.0385 for
# English) have no correlation.
#
# So, in the above example, the key length is probably 5 letters.
#
# This currently only works for English language ciphertext.

use warnings;
use strict;

use File::Slurp qw/slurp/;
use Getopt::Long;
use List::Util qw/sum/;

use constant ALPHABET => 'A' .. 'Z';

sub ic {
	my ($data) = @_;
	my $n = length($data);

	my %counts = map { $_ => 0 } ALPHABET;
	$counts{$_} += 1 for split //, $data;
	my $sum = sum( map { $_ * ($_ - 1) } values %counts );
	$sum / ($n * ($n - 1));
}

# split text into `n' columns and return each column
# e.g. n_columns(3, 'abcdefghi') = ('adg', 'beh', 'cfi')
sub columns {
	my ($n, $data) = @_;
	my @columns = ('') x $n;
	for my $i (0 .. length($data) - 1) {
		$columns[$i%$n] .= substr($data, $i, 1);
	}
	@columns
}

GetOptions('k=s' => \my $k);

$k ||= 1;

my $data = @ARGV ? shift : slurp(\*STDIN);

$data = uc($data);
$data =~ s/[^A-Z]//g;

for my $i (1 .. $k) {
	my $agg_ic = sum(map { ic($_) } columns($i, $data)) / $i;
	printf "k = %d, i.c. = %.3f\n", $i, $agg_ic;
}
