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
		$response = $company->get_queue( test_mode => 1 );
	},
	qr/Fatal error/,
	'Request queued items  - test failure.',
);

ok(
	defined(
		$response = $company->get_queue()
	),
	'Request queued items.',
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Retrieve queued items.',
) || diag( explain( $response ) );

