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
	: plan( tests => 6 );

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
ok(
	defined(
		$response = $company->get_report_suites()
	),
	'Request report suites.',
);

ok(
	Data::Validate::Type::is_arrayref( $response ),
	'Retrieve response.',
) || diag( explain( $response ) );


if ( scalar( $response ) > 0 )
{
	
	# Store first item, if anything was returned, into file for use in other tests
	ok(
		open( FILE, '>', 'business-sitecatalyst-report-report_suite_id.tmp'),
		'Open temp file to store first report suite id for use in other tests'
	);
	
	print FILE $response->[0]->{'rsid'};
	
	ok(
		close FILE,
		'Close temp file'
	);
	
}
