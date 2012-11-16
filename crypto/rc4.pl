#!/usr/bin/env perl

# rc4.pl
#
# usage:
#   echo foobar | rc4.pl <key>

use warnings;
use strict;

my @key = map ord, split //, (shift or die "no key");
my @k = (@key) x (int(256 / @key) + 1);
@k = @k[0..255];

my @s = (0 .. 255);
my $j = 0;
for my $i (0 .. 255) {
	$j = ($j + $s[$i] + $k[$i]) & 0xff;
	@s[$i,$j] = @s[$j,$i];
}

$j = 0;
my $i = 0;
while (sysread STDIN, my $bytes, 1024) {
	my $buffer = '';
	for my $byte (split //, $bytes) {
		$i = ($i + 1) & 0xff;
		$j = ($j + $s[$i]) & 0xff;
		@s[$i,$j] = @s[$j,$i];
		my $t = ($s[$i] + $s[$j]) & 0xff;
		my $k = $s[$t];
		$buffer .= $byte ^ chr($k);
	}
	syswrite STDOUT, $buffer;
}

