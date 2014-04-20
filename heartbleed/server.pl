#!/usr/bin/env perl
# server.pl -- simple HTTPS server

# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server.key -out server.cert

# $ wget --no-check-certificate -q -O - https://localhost/
# Hack the planet!

use warnings;
use strict;

use POE qw/Component::Server::HTTP Filter::SSL/;
use HTTP::Status;

my $aliases = POE::Component::Server::HTTP->new(
	Port => 443,
	ContentHandler => {
		'/' => sub {
			my ($req, $resp) = @_;
			$resp->code(RC_OK);
			$resp->content("Hack the planet!\r\n");
			return RC_OK;
		},
	},
	PreFilter => POE::Filter::SSL->new(
		crt => 'server.crt',
		key => 'server.key',
	)
);

POE::Kernel->run;
POE::Kernel->call($aliases->{httpd}, 'shutdown');
