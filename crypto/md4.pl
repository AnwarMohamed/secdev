#!/usr/bin/env perl
# md4.pl

use warnings;
use strict;

my @m = unpack "C*", $ARGV[0];
my $bl = @m * 8;

# add padding
my $padding_bytes = (@m % 64) > 56 ? 120 - @m : 56 - (@m % 64);
push @m, (1 << 7);
push @m, (0) x ($padding_bytes - 1);

# add 64-bit representation of the length (in bits) of the message
push @m,  $bl        & 0xff;
push @m, ($bl >>  8) & 0xff;
push @m, ($bl >> 16) & 0xff;
push @m, ($bl >> 24) & 0xff;
push @m, ($bl >> 32) & 0xff;
push @m, ($bl >> 40) & 0xff;
push @m, ($bl >> 48) & 0xff;
push @m, ($bl >> 56) & 0xff;

sub F { my ($x,$y,$z) = @_; ($x & $y) | (~$x & $z) }
sub G { my ($x,$y,$z) = @_; ($x & $y) | ($x & $z) | ($y & $z) }
sub H { my ($x,$y,$z) = @_; $x ^ $y ^ $z }
sub ROL { my ($x,$n) = @_; (($x << $n) | ($x >> (32 - $n))) & 0xffffffff }

sub FF {
	my ($a, $b, $c, $d, $x, $s) = @_;
	$a += F($b, $c, $d) + $x;
	$a &= 0xffffffff;
	ROL($a, $s);
}
sub GG {
	my ($a, $b, $c, $d, $x, $s) = @_;
	$a += G($b, $c, $d) + $x;
	$a &= 0xffffffff;
	$a += 0x5a827999;
	$a &= 0xffffffff;
	ROL($a, $s);
}
sub HH {
	my ($a, $b, $c, $d, $x, $s) = @_;
	$a += H($b, $c, $d) + $x;
	$a &= 0xffffffff;
	$a += 0x6ed9eba1;
	$a &= 0xffffffff;
	ROL($a, $s);
}

# registers
my $a = 0x67452301;
my $b = 0xefcdab89;
my $c = 0x98badcfe;
my $d = 0x10325476;

# pack the mesage into dwords
my @s;
for my $i (0 .. @m / 4 - 1) {
	push @s => unpack "V", pack "C4", @m[$i * 4 .. $i * 4 + 3];
}

# operate on 16 dwords at a time
for my $i (0 .. @s / 16 - 1) {
	my @x = @s[$i * 16 .. $i * 16 + 15];

	my $aa = $a;
	my $bb = $b;
	my $cc = $c;
	my $dd = $d;

	# round 1
	$a = FF($a, $b, $c, $d, $x[0], 3);
	$d = FF($d, $a, $b, $c, $x[1], 7);
	$c = FF($c, $d, $a, $b, $x[2], 11);
	$b = FF($b, $c, $d, $a, $x[3], 19);

	$a = FF($a, $b, $c, $d, $x[4], 3);
	$d = FF($d, $a, $b, $c, $x[5], 7);
	$c = FF($c, $d, $a, $b, $x[6], 11);
	$b = FF($b, $c, $d, $a, $x[7], 19);

	$a = FF($a, $b, $c, $d, $x[8], 3);
	$d = FF($d, $a, $b, $c, $x[9], 7);
	$c = FF($c, $d, $a, $b, $x[10], 11);
	$b = FF($b, $c, $d, $a, $x[11], 19);

	$a = FF($a, $b, $c, $d, $x[12], 3);
	$d = FF($d, $a, $b, $c, $x[13], 7);
	$c = FF($c, $d, $a, $b, $x[14], 11);
	$b = FF($b, $c, $d, $a, $x[15], 19);

	# round 2
	$a = GG($a, $b, $c, $d, $x[0], 3);
	$d = GG($d, $a, $b, $c, $x[4], 5);
	$c = GG($c, $d, $a, $b, $x[8], 9);
	$b = GG($b, $c, $d, $a, $x[12], 13);

	$a = GG($a, $b, $c, $d, $x[1], 3);
	$d = GG($d, $a, $b, $c, $x[5], 5);
	$c = GG($c, $d, $a, $b, $x[9], 9);
	$b = GG($b, $c, $d, $a, $x[13], 13);

	$a = GG($a, $b, $c, $d, $x[2], 3);
	$d = GG($d, $a, $b, $c, $x[6], 5);
	$c = GG($c, $d, $a, $b, $x[10], 9);
	$b = GG($b, $c, $d, $a, $x[14], 13);

	$a = GG($a, $b, $c, $d, $x[3], 3);
	$d = GG($d, $a, $b, $c, $x[7], 5);
	$c = GG($c, $d, $a, $b, $x[11], 9);
	$b = GG($b, $c, $d, $a, $x[15], 13);

	# round 3
	$a = HH($a, $b, $c, $d, $x[0], 3);
	$d = HH($d, $a, $b, $c, $x[8], 9);
	$c = HH($c, $d, $a, $b, $x[4], 11);
	$b = HH($b, $c, $d, $a, $x[12], 15);

	$a = HH($a, $b, $c, $d, $x[2], 3);
	$d = HH($d, $a, $b, $c, $x[10], 9);
	$c = HH($c, $d, $a, $b, $x[6], 11);
	$b = HH($b, $c, $d, $a, $x[14], 15);

	$a = HH($a, $b, $c, $d, $x[1], 3);
	$d = HH($d, $a, $b, $c, $x[9], 9);
	$c = HH($c, $d, $a, $b, $x[5], 11);
	$b = HH($b, $c, $d, $a, $x[13], 15);

	$a = HH($a, $b, $c, $d, $x[3], 3);
	$d = HH($d, $a, $b, $c, $x[11], 9);
	$c = HH($c, $d, $a, $b, $x[7], 11);
	$b = HH($b, $c, $d, $a, $x[15], 15);

	$a += $aa;
	$b += $bb;
	$c += $cc;
	$d += $dd;
}

printf "MD4('%s') = ", $ARGV[0];
print unpack "H*", pack "V4", $a, $b, $c, $d;
print "\n";
