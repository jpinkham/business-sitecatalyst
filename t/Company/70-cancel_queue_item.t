#!perl -T

use strict;
use warnings;

use Data::Validate::Type;
use Test::Exception;
use Test::More;

use Business::SiteCatalyst;


eval 'use SiteCatalystConfig';
$@
	? plan( skip_all => 'Local connection information for Adobe SiteCatalyst required to run tests.' )
	: plan( tests => 5 );

my $config = SiteCatalystConfig->new();

# Create an object to communicate with Adobe SiteCatalyst
my $site_catalyst = Business::SiteCatalyst->new( %$config );
ok(
	defined( $site_catalyst ),
	'Create a new Business::SiteCatalyst object.',
);

ok(
	defined( 
		my $company = $site_catalyst->instantiate_company()
	),
	'Instantiate a new Business::SiteCatalyst::Company.',
);

my $response;

throws_ok(
	sub
	{
		$response = $company->cancel_queue_item(
			queue_id  => '12345',
			test_mode => 1,
		);
	},
	qr/Fatal error/,
	'Request to cancel queued item - test failure.',
);

ok(
	defined(
		$response = $company->cancel_queue_item( queue_id => '12345' )
	),
	'Request to cancel queue item.',
);

like (
	$response,
	qr/^[01]$/,
	'Check if cancel_queue_item() returns a boolean.',
);
