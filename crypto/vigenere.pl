#!/usr/bin/env perl
# vigenere.pl
# usage:
#   $ perl vigenere.pl foo 'foo bar baz quux'
#   KCC GOF GON VIIC
#   $ perl vigenere.pl -d foo 'KCC GOF GON VIIC'
#   FOO BAR BAZ QUUX

use warnings;
use strict;

use File::Slurp qw/slurp/;
use Getopt::Long;

use constant {
	LEFT  => 0,
	RIGHT => 1,
};

my $encrypt = 0;
my $decrypt = 0;

GetOptions(
	'e|encrypt!' => \$encrypt,
	'd|decrypt!' => \$decrypt,
);

# default to encryption
$encrypt = 1 unless $decrypt;

sub rotate {
	my ($n, $d, @data) = @_;
	my @a = splice @data, 0, $d == LEFT ? $n : (0 - $n);
	push @data, @a;
	@data
}

my $lookup = [
	map {
		[ rotate(ord($_) - 65, LEFT, 'A' .. 'Z') ]
	} 'A' .. 'Z'
];

my $rev_lookup = [
	map {
		[ rotate(ord($_) - 65, RIGHT, 'A' .. 'Z') ]
	} 'A' .. 'Z'
];

my $key = shift || die "no key";
my $data = @ARGV ? shift : slurp(\*STDIN);

$key =~ s/[^a-zA-Z]//g;

my $ki = 0;
for my $x (0 .. length($data) - 1) {
	my $d = uc substr $data, $x, 1;

	unless ($d =~ /[A-Z]/) {
		print $d;
		next;
	}

	my $k = uc substr $key, $ki++ % length($key), 1;

	if ($encrypt) {
		print $lookup->[ord($k) - 65]->[ord($d) - 65];
	}
	elsif ($decrypt) {
		print $rev_lookup->[ord($k) - 65]->[ord($d) - 65];
	}
}
print "\n";
