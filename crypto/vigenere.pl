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
	my ($d, $n, @data) = @_;
	my @a = splice @data, 0, $d == LEFT ? $n : (0 - $n);
	push @data, @a;
	@data
}
sub rol { rotate(LEFT, @_) }
sub ror { rotate(RIGHT, @_) }

my $lookup = [
	map {
		[ rol(ord($_) - 65, 'A' .. 'Z') ]
	} 'A' .. 'Z'
];

sub encrypt {
	my ($k, $d) = @_;
	$lookup->[ord($k) - 65]->[ord($d) - 65];
}

sub decrypt {
	my ($k, $d) = @_;
	$lookup->[(26 - (ord($k) - 65)) % 26]->[ord($d) - 65]
}

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
		print encrypt($k,$d);
	}
	elsif ($decrypt) {
		print decrypt($k,$d);
	}
}
print "\n";
