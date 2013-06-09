#!perl -T

use strict;
use warnings;

use Test::More;

use Business::SiteCatalyst::Report;


eval 'use SiteCatalystConfig';
$@
	? plan( skip_all => 'Local connection information for Adobe SiteCatalyst required to run tests.' )
	: plan( tests => 2 );

my $config = SiteCatalystConfig->new();

like(
	$config->{'username'},
	qr/\w/,
	'The username is defined.',
);

like(
	$config->{'shared_secret'},
	qr/\w/,
	'The shared_secret is defined.',
);

