#!/usr/bin/env perl
# quadgramcrack.pl -- attempts to crack simple text ciphers using quadgram
#                     analysis
#
# This is just an implementation of the algorithm described in practicalcryptography.com
# http://practicalcryptography.com/cryptanalysis/stochastic-searching/cryptanalysis-vigenere-cipher-part-2/
#
# usage:
#   $ perl quadgramcrack.pl -k 6 YVWTIJXCAFTVCHWUIJXCAFPIJHHZCFRACOTVCHWXOEISFJFZHOBDRRHYWUWZYVAZQLFRUSADHFODKVW
#   Using key: UOOBAR
#   Decrypted text: EHISISDOMETEITITISDOMEPRPTTYCOXMONTEITIWONOERIFINANCRANKITWIEHMYQULDGRAMNRACKEC
#
# If the key is close, but not quite there, you can seed the script with a key,
# and it'll try to improve upon it:
#
#   $ perl quadgramcrack.pl -s UOOBAR YVWTIJXCAFTVCHWUIJXCAFPIJHHZCFRACOTVCHWXOEISFJFZHOBDRRHYWUWZYVAZQLFRUSADHFODKVW
#   Using key: FOOBAR
#   Decrypted text: THISISSOMETEXTITISSOMEPRETTYCOMMONTEXTIWONDERIFICANCRACKITWITHMYQUADGRAMCRACKER
#
# Or, alternatively, you can tell the script to try and refine the key multiple times:
#
#   $ perl quadgramcrack.pl -k 6 YVWTIJXCAFTVCHWUIJXCAFPIJHHZCFRACOTVCHWXOEISFJFZHOBDRRHYWUWZYVAZQLFRUSADHFODKVW -t 10
#   Unable to find a better key after 3 iterations.
#   Using key: FOOBAR
#   Decrypted text: THISISSOMETEXTITISSOMEPRETTYCOMMONTEXTIWONDERIFICANCRACKITWITHMYQUADGRAMCRACKER
#
# Currently cracks Vigenere, Caesar and simple XOR ciphers, although simple XOR
# doesn't work so great if there's a lot of non A-Z in the plaintext.
#
# It started as a dive into cryptanalysis of simple, classical ciphers, and then
# I went a bit overboard... but hey, at least it's useful in ARGs and simple
# challenge websites!

package NGramScore;

# http://practicalcryptography.com/cryptanalysis/text-characterisation/quadgrams/
# This code is a direct translation of ngram_score.py

use Moo;

use File::Slurp qw/slurp/;
use List::Util qw/sum/;

has filename => (is => 'ro');
has ngrams => (
	is => 'rw',
	default => sub { {} }
);
has floor => (is => 'rw');

sub BUILD {
	my ($self) = @_;
	my @lines = slurp($self->filename);
	for my $line (@lines) {
		my ($key, $count) = split / /, $line;
		$self->ngrams->{$key} = int($count);
	}

	my $n = sum(values %{$self->ngrams});

	for my $key (keys %{$self->ngrams}) {
		$self->ngrams->{$key} = log($self->ngrams->{$key} / $n);
	}

	$self->floor(log(0.01 / $n));
}

sub quadgrams { pop =~ /(?=(.{4}))/g }
sub score {
	my ($self, $text) = @_;

	my $score = 0;

	$text =~ s/[[:punct:]]//g;

	for my $quad (quadgrams($text)) {
		if (exists $self->ngrams->{$quad}) {
			$score += $self->ngrams->{$quad};
		}
		else {
			$score += $self->floor;
		}
	}

	return $score
}

package Algorithm;

use Moo;

has alphabet => (is => 'ro');
sub as_string   { $_[1] }
sub from_string { $_[1] }
sub decrypt { }

package Algorithm::Vigenere;

use Moo;
extends 'Algorithm';

use constant {
	LEFT  => 0,
	RIGHT => 1,
};

has '+alphabet' => (
	default => sub { [ 'A' .. 'Z' ] }
);
has lookup => (
	is => 'ro',
	default => sub { [
		map {
			[ rol(ord($_) - 65, 'A' .. 'Z') ]
		} 'A' .. 'Z'
	] }
);

sub rotate {
	my ($d, $n, @data) = @_;
	my @a = splice @data, 0, ($d == LEFT? $n : 0 - $n);
	push @data => @a;
	@data
}
sub rol { rotate(LEFT,  @_) }
sub ror { rotate(RIGHT, @_) }
sub decrypt {
	my ($self, $key, $data) = @_;

	my @k = unpack "C*", $key;
	my @d = unpack "C*", $data;

	my $p = '';
	my $ki = 0;
	for my $x (0 .. $#d) {
		my $k = $k[$ki++ % @k];
		my $d = $d[$x];

		$p .= $self->lookup->[(26 - ($k - 65)) % 26]->[$d - 65];
	}
	$p
}

package Algorithm::XOR;

use Moo;
extends 'Algorithm';

has '+alphabet' => (
	default => sub { [ map { pack "C", $_ } 1 .. 255 ] }
);

# because we're dealing with binary data, accept and output hex strings
sub from_string { pack "H*",   $_[1] }
sub as_string   { unpack "H*", $_[1] }

sub decrypt {
	my ($self, $key, $data) = @_;

	my @k = unpack "C*", $key;
	my @d = unpack "C*", $data;

	my @p;
	my $ki = 0;
	for my $x (0 .. $#d) {
		my $k = $k[$ki++ % @k];
		my $c = $d[$x];

		push @p => $k ^ $c;
	}
	pack "C*", @p;
}

package App::QuadGramCrack;

use Moo;

use List::Util qw/max/;
use Scalar::Util qw/blessed/;
use Term::ANSIColor qw/color/;

has debug => (is => 'ro');
has algorithm => (is => 'rw');
has key_length => (
	is => 'rw',
	default => sub { 1 },
);
has quadgrams => (
	is => 'rw',
	isa => sub {
		die "$_[0] is not a NGramScore object or a readable file"
			unless blessed($_[0]) and (blessed($_[0]) eq 'NGramScore')
	},
	coerce => sub {
		  (blessed($_[0]) and blessed($_[0]) eq 'NGramScore')
		? $_[0]
		: NGramScore->new(filename => $_[0])
	}
);

sub fitness {
	my ($self, $key, $data) = @_;

	my $data_to_check = '';
	if (length($key) == $self->key_length) {
		$data_to_check = $data;
	} else {
		# we've only generated length($key) characters of the total key, so we
		# need to only select the text that is decrypted by this section of the
		# key
		for my $i (0 .. length($data) - 1) {
			if ($i % $self->key_length < length($key)) {
				$data_to_check .= substr($data, $i, 1);
			}
		}
	}

	# decrypt what we have so far
	my $decrypted = $self->algorithm->decrypt($key, $data_to_check);

	$self->quadgrams->score($decrypted);
}

# generates candidates by changing column $i with 'A' .. 'Z'
sub get_candidates {
	my ($self, $i, $data) = @_;

	my @candidates;
	for (@{ $self->algorithm->alphabet }) {
		substr($data, $i, 1) = $_;
		push @candidates => $data;
	}
	@candidates
}

before run => sub {
	my ($self, $opts) = @_;

	if (exists $opts->{algorithm}) {
		$self->algorithm($opts->{algorithm});
	}

	# convert key (if specified) and ciphertext into bytes
	$opts->{seed_key} = $self->algorithm->from_string($opts->{seed_key} || '');
	$opts->{data}     = $self->algorithm->from_string($opts->{data});

	if ((exists $opts->{key_length}) and (defined $opts->{key_length})) {
		$self->key_length($opts->{key_length});
	}

	# if a seed key was passed in, set the key length from that
	if ($opts->{seed_key}) {
		$self->key_length(length $opts->{seed_key});
	}

	$opts->{seed_key} ||= '';
	$opts->{times}    ||= 1;

	# TODO have the algorithm perform transformations, like removing non A-Z
	# chars, uppercasing, etc... for simple text ciphers
};

sub run {
	my ($self, $opts) = @_;

	my $running_key = $opts->{seed_key};
	my $last_key    = $running_key;

	for my $t (1 .. $opts->{times}) {
		for my $i (0 .. $self->key_length - 1) {
			# 1. generate candidates
			my @candidates = $self->get_candidates($i, $running_key);

			# 2. calculate the fitness of all candidates
			my %fitness = map {
				$_ => $self->fitness(
					$_,
					$opts->{data}
				)
			} @candidates;

			# 3. pick the fittest candidate
			($running_key) = sort { $fitness{$b} <=> $fitness{$a} } @candidates;
			# TODO multiple candidates with highest fitness, wat do?

			if ($self->debug) {
				for my $c (@candidates) {
					print color('green') if $c eq $running_key;
					printf "candidate: %s, fitness: %f\n",
						$self->algorithm->as_string($c),
						$fitness{$c};
					print color('reset') if $c eq $running_key;
				}
			}

		}

		if ($running_key eq $last_key) {
			printf "Unable to find a better key after $t iterations.\n";
			last;
		}

		$last_key = $running_key;
	}

	printf "Finished!\nFinal key: %s\nDecrypted text: %s\n",
		$self->algorithm->as_string($running_key),
		$self->algorithm->decrypt($running_key, $opts->{data});
}

package main;

use warnings;
use strict;

use File::Slurp qw/slurp/;
use Getopt::Long;

GetOptions(
	'k|key_length=s' => \my $key_length,
	's|seed_key=s'   => \my $seed_key,
	'a|algorithm=s'  => \my $algo,
	't|times=s'      => \my $times,
	'd|debug!'       => \my $debug,
);

die "key length or seed key not provided" unless $key_length or $seed_key;

my %algos = (
	vigenere => Algorithm::Vigenere->new,
	xor      => Algorithm::XOR->new,
);

$algo  ||= 'vigenere';
$times ||= 1;

my $data = @ARGV ? shift : slurp(\*STDIN);

App::QuadGramCrack->new(
	quadgrams  => 'english_quadgrams.txt',  # get this from practicalcryptography.com
	debug      => $debug,
)->run({
	times      => $times,
	algorithm  => $algos{$algo},
	key_length => $key_length,
	seed_key   => $seed_key,
	data       => $data,
});
