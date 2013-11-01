#!/usr/bin/env perl

# rc4.pl
#
# usage:
#   echo foobar | rc4.pl <key as hex string>

use warnings;
use strict;

my @k = unpack "C*", pack "H*", (shift or die "no key");

my @s = (0 .. 255);
my $j = 0;
for my $i (0 .. 255) {
	$j = ($j + $s[$i] + $k[$i%@k]) & 0xff;
	@s[$i,$j] = @s[$j,$i];
}

$j = 0;
my $i = 0;
while (sysread STDIN, my $bytes, 4096) {
	my @buf;
	for my $b (unpack "C*", $bytes) {
		$i = ($i + 1) & 0xff;
		$j = ($j + $s[$i]) & 0xff;
		@s[$i,$j] = @s[$j,$i];
		my $t = ($s[$i] + $s[$j]) & 0xff;
		my $k = $s[$t];
		push @buf => $b ^ $k;
	}
	syswrite STDOUT, pack("C*", @buf);
}

