#!/usr/bin/env perl

# md2.pl
#
# usage:
#   From stdin:
#     cat foo | md2.pl
#
#   Run tests:
#     md2.pl -t

use warnings;
use strict;

use Getopt::Long;

# S-box
my @s = (
	0x29, 0x2e, 0x43, 0xc9, 0xa2, 0xd8, 0x7c, 0x01, 0x3d, 0x36, 0x54, 0xa1, 0xec, 0xf0, 0x06, 0x13, 
	0x62, 0xa7, 0x05, 0xf3, 0xc0, 0xc7, 0x73, 0x8c, 0x98, 0x93, 0x2b, 0xd9, 0xbc, 0x4c, 0x82, 0xca, 
	0x1e, 0x9b, 0x57, 0x3c, 0xfd, 0xd4, 0xe0, 0x16, 0x67, 0x42, 0x6f, 0x18, 0x8a, 0x17, 0xe5, 0x12, 
	0xbe, 0x4e, 0xc4, 0xd6, 0xda, 0x9e, 0xde, 0x49, 0xa0, 0xfb, 0xf5, 0x8e, 0xbb, 0x2f, 0xee, 0x7a, 
	0xa9, 0x68, 0x79, 0x91, 0x15, 0xb2, 0x07, 0x3f, 0x94, 0xc2, 0x10, 0x89, 0x0b, 0x22, 0x5f, 0x21,
	0x80, 0x7f, 0x5d, 0x9a, 0x5a, 0x90, 0x32, 0x27, 0x35, 0x3e, 0xcc, 0xe7, 0xbf, 0xf7, 0x97, 0x03, 
	0xff, 0x19, 0x30, 0xb3, 0x48, 0xa5, 0xb5, 0xd1, 0xd7, 0x5e, 0x92, 0x2a, 0xac, 0x56, 0xaa, 0xc6, 
	0x4f, 0xb8, 0x38, 0xd2, 0x96, 0xa4, 0x7d, 0xb6, 0x76, 0xfc, 0x6b, 0xe2, 0x9c, 0x74, 0x04, 0xf1, 
	0x45, 0x9d, 0x70, 0x59, 0x64, 0x71, 0x87, 0x20, 0x86, 0x5b, 0xcf, 0x65, 0xe6, 0x2d, 0xa8, 0x02, 
	0x1b, 0x60, 0x25, 0xad, 0xae, 0xb0, 0xb9, 0xf6, 0x1c, 0x46, 0x61, 0x69, 0x34, 0x40, 0x7e, 0x0f, 
	0x55, 0x47, 0xa3, 0x23, 0xdd, 0x51, 0xaf, 0x3a, 0xc3, 0x5c, 0xf9, 0xce, 0xba, 0xc5, 0xea, 0x26, 
	0x2c, 0x53, 0x0d, 0x6e, 0x85, 0x28, 0x84, 0x09, 0xd3, 0xdf, 0xcd, 0xf4, 0x41, 0x81, 0x4d, 0x52, 
	0x6a, 0xdc, 0x37, 0xc8, 0x6c, 0xc1, 0xab, 0xfa, 0x24, 0xe1, 0x7b, 0x08, 0x0c, 0xbd, 0xb1, 0x4a, 
	0x78, 0x88, 0x95, 0x8b, 0xe3, 0x63, 0xe8, 0x6d, 0xe9, 0xcb, 0xd5, 0xfe, 0x3b, 0x00, 0x1d, 0x39, 
	0xf2, 0xef, 0xb7, 0x0e, 0x66, 0x58, 0xd0, 0xe4, 0xa6, 0x77, 0x72, 0xf8, 0xeb, 0x75, 0x4b, 0x0a, 
	0x31, 0x44, 0x50, 0xb4, 0x8f, 0xed, 0x1f, 0x1a, 0xdb, 0x99, 0x8d, 0x33, 0x9f, 0x11, 0x83, 0x14,
);

my @padding = (
	undef,
	[ (0x01) ],
	[ (0x02) x 2 ],
	[ (0x03) x 3 ],
	[ (0x04) x 4 ],
	[ (0x05) x 5 ],
	[ (0x06) x 6 ],
	[ (0x07) x 7 ],
	[ (0x08) x 8 ],
	[ (0x09) x 9 ],
	[ (0x0a) x 10 ],
	[ (0x0b) x 11 ],
	[ (0x0c) x 12 ],
	[ (0x0d) x 13 ],
	[ (0x0e) x 14 ],
	[ (0x0f) x 15 ],
	[ (0x10) x 16 ],
);

sub md2 {
	my ($m) = @_;

	my @m = map ord, split //, $m;

	# Pad the message so that it's a multiple of 16 bytes long. Padding must happen,
	# even if the message is already a multiple of 16 bytes.
	my $pad_length = 16;
	if (scalar(@m) % 16 != 0) {
		my $message_length = scalar @m;
		while ($message_length & 0x0f) {
			$message_length += 1;
		}
		$pad_length = $message_length - scalar(@m);
	}

	push @m, @{ $padding[$pad_length] };

	# Calculate 16-byte checksum and append to the message
	my @c = (0) x 16;
	my $l = 0;

	for my $i (0 .. scalar(@m) / 16 - 1) {
		for my $j (0 .. 15) {
			my $c = $m[$i * 16 + $j];

			# The RFC says:
			#   Set C[j] to S[c xor L]
			# What it should say:
			#   Set C[j] to C[j] xor S[c xor L]
			$c[$j] ^= $s[$c ^ $l];
			$l = $c[$j];
		}
	}

	push @m, @c;

	# Calculate the message digest
	my @x = (0) x 48;

	for my $i (0 .. scalar(@m) / 16 - 1) {
		for my $j (0 .. 15) {
			$x[16 + $j] = $m[$i * 16 + $j];
			$x[32 + $j] = $x[16 + $j] ^ $x[$j];
		}

		my $t = 0;

		for my $j (0 .. 17) {
			for my $k (0 .. 47) {
				$t = $x[$k] ^= $s[$t];
			}

			$t = ($t + $j) & 0xff;
		}
	}

	# The digest is the first 128 bits (16 bytes) only
	@x[0 .. 15];
}

sub md2_bytes { join '', map chr, md2 shift }
sub md2_hex   { scalar unpack 'H32', md2_bytes shift }

GetOptions(
	't|test!' => \my $test_mode,
);

if ($test_mode) {
	eval { use Test::More };

	my %tests = (
		'' => '8350e5a3e24c153df2275c9f80692773',
		'a' => '32ec01ec4a6dac72c0ab96fb34c0b5d1',
		'abc' => 'da853b0d3f88d99b30283a69e6ded6bb',
		'message digest' => 'ab4f496bfb2a530b219ff33031fe06b0',
		'abcdefghijklmnopqrstuvwxyz' => '4e8ddff3650292ab5a4108c3aa47940b',
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789' => 'da33def2a42df13975352846c30338cd',
		'12345678901234567890123456789012345678901234567890123456789012345678901234567890' => 'd5976f79d83d3a0dc9806c3c66f3efd8',
		'The quick brown fox jumps over the lazy dog' => '03d85a0d629d2c442e987525319fc471',
		'The quick brown fox jumps over the lazy cog' => '6b890c9292668cdbbfda00a4ebf31f05',
	);

	plan tests => scalar keys %tests;

	while (my ($test, $desired_result) = each %tests) {
		my $md2 = md2_hex($test);
		diag("MD2('$test') = $md2");
		is($md2, $desired_result);
	}
}
else {
	# Yeah, yeah, yeah. Should be buffered input, etc...
	local $/;
	print md2_hex(<STDIN>), "\n";
}

