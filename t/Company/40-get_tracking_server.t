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
	: plan( tests => 9 );

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
		$response = $company->get_tracking_server( report_suite_id => '' );
	},
	qr/Argument 'report_suite_id' is required/,
	'Request tracking server - empty "report_suite_id"'
);

ok(
	open( FILE, 'business-sitecatalyst-report-report_suite_id.tmp'),
	'Open temp file to read report suite id'
);

my $report_suite_id;

ok(
	$report_suite_id = do { local $/; <FILE> },
	'Read in report suite id'
);

ok(
	close FILE,
	'Close temp file'
);

throws_ok(
	sub
	{
		$response = $company->get_tracking_server( 
			test_mode       => 1,
			report_suite_id => $report_suite_id,
		);
	},
	qr/Fatal error/,
	'Request tracking server - test failure.',
);

ok(
	defined(
		$response = $company->get_tracking_server( report_suite_id => $report_suite_id )
	),
	'Request tracking server - report_suite_id specified.',
);

ok(
	Data::Validate::Type::is_string( $response, allow_empty => 0 ),
	'Retrieve tracking server - report_suite_id specified.',
) || diag( explain( $response ) );

