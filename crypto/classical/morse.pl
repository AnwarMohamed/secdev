#!/usr/bin/env perl
# morse.pl -- what do you think it's for?

use warnings;
use strict;

my %m2a = qw(
	.-    A
	-...  B
	-.-.  C
	-..   D
	.     E
	..-.  F
	--.   G
	....  H
	..    I
	.---  J
	-.-   K
	.-..  L
	--    M
	-.    N
	---   O
	.--.  P
	--.-  Q
	.-.   R
	...   S
	-     T
	..-   U
	...-  V
	.--   W
	-..-  X
	-.--  Y
	--..  Z
	.---- 1
	..--- 2
	...-- 3
	....- 4
	..... 5
	-.... 6
	--... 7
	---.. 8
	----. 9
	----- 0
);
my %a2m = map { $m2a{$_} => $_ } keys %m2a;

sub from_morse { join '', map { $m2a{$_} } split / +/, shift }
sub to_morse { join ' ', map { $a2m{uc $_} } grep { /[a-zA-Z0-9]/ } split //, shift }

die "no args\n" unless @ARGV;

my ($t) = @ARGV;
print $t =~ m/^[\.\-\s]+$/ ? from_morse($t) : to_morse($t); print "\n";
