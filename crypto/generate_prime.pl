#!/usr/bin/env perl

# TODO use Math::BigInt/Float for >32-bit prime generation

use warnings;
use strict;

use List::MoreUtils qw/any/;

my $bits = shift || 32;

# Generate p such that it isn't divisible by low primes
my @low_primes = sieve(2000);
my $p;
do {
	$p = genp($bits);
} while (any { $p % $_ == 0 } @low_primes);

print "p = $p\n";
for (1 .. 5) {
	my $a = int(rand($p));
	unless (rabin_miller($p, $a)) {
		print " ... did not pass... probably not prime\n";
		exit;
	}
}

print " ... may be prime... passed 5 tests.\n";

# Generate an n-bit pseudo-random number
sub genp {
	my ($n) = @_;
	my $p = int(rand((2 ** $n) - 1));
	$p |= 0x01 << ($n - 1);  # Set highest bit to guarantee n-bit length
	$p |= 0x01;  # Set lowest bit to guarantee an odd-number
	return $p;
}

# Rabin-Miller prime test
sub rabin_miller {
	my ($p, $a) = @_;

	my $b = ($p - 1) / 2;
	my $m = ($p - 1) / (2 ** $b);

	my $j = 0;
	my $z = ($a ** $m) % $p;

	if (($z == 1) or ($z == $p - 1)) {
		# may be prime
		return 1;
	}

	STEPFOUR:
	if(($j > 0) and ($z == 1)) {
		# not prime
		return 0;
	}

	$j += 1;
	if (($j < $b) and ($z != $p - 1)) {
		$z = ($z ** 2) % $p;
		goto STEPFOUR;
	}

	if ($z == $p - 1) {
		# may be prime
		return 1;
	}

	if (($j == $b) and ($z == $p - 1)) {
		# not prime
		return 0;
	}

	# TODO is this the right thing to do?
	return 1;
}

# Sieve of Eratosthenes
sub sieve {
    my $n = shift;

    my @primes;
    my @st = (0) x $n;
    for my $x ( 2 .. int sqrt $n ) {
        next if $st[$x];

        push @primes, $x;

        my $y = $x;
        while ( $y <= $n ) {
            $st[$y] = 1;
            $y += $x;
        }
    }

    for my $x ( 2 .. $n ) {
        push @primes, $x unless $st[$x];
    }

    @primes;
}

