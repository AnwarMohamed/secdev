#!/usr/bin/env perl
# vigenere.pl -- Vigenere and Autokey ciphers
# usage:
#   $ perl vigenere.pl --key foo 'bar baz quux'
#   GOF GON VIIC
#   $ perl vigenere.pl -d --key foo 'GOF GON VIIC'
#   BAR BAZ QUUX
#   $ perl vigenere.pl --autokey foo 'bar baz quux'
#   GOF CAQ RUTN
#   $ perl vigenere.pl -d --autokey foo 'GOF CAQ RUTN'
#   BAR BAZ QUUX

use warnings;
use strict;

use File::Slurp qw/slurp/;
use Getopt::Long;

use constant {
	LEFT  => 0,
	RIGHT => 1,
};

GetOptions(
	'e|encrypt!'  => \my $encrypt,
	'd|decrypt!'  => \my $decrypt,
	'k|key=s'     => \my $key,
	'a|autokey=s' => \my $autokey,
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

my $tab_recta = [
	map {
		[ rol(ord($_) - 65, 'A' .. 'Z') ]
	} 'A' .. 'Z'
];

sub encrypt {
	my ($k, $d) = @_;
	$tab_recta->[ord($k) - 65]->[ord($d) - 65];
}

sub decrypt {
	my ($k, $d) = @_;
	$tab_recta->[(26 - (ord($k) - 65)) % 26]->[ord($d) - 65]
}

die "no key" unless $key or $autokey;

my $data = @ARGV ? shift : slurp(\*STDIN);

if ($autokey) {
	if ($encrypt) {
		$key = $autokey . $data;
	}
	elsif ($decrypt) {
		$key = $autokey;
	}
}

$key = uc $key;
$key =~ s/[^A-Z]//g;

my $ki = 0;
for my $x (0 .. length($data) - 1) {
	my $d = uc substr $data, $x, 1;

	unless ($d =~ /[A-Z]/) {
		print $d;
		next;
	}

	my $k = substr $key, $ki++ % length($key), 1;

	if ($encrypt) {
		print encrypt($k,$d);
	}
	elsif ($decrypt) {
		# feed decrypted text back into the key if we're doing Autokey cipher
		# stuff.
		my $c = decrypt($k,$d);
		$key .= $c if $autokey;

		print $c;
	}
}
print "\n";
