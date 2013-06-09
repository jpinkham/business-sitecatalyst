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
	: plan( tests => 12 );

my $config = SiteCatalystConfig->new();

# Create an object to communicate with Adobe SiteCatalyst
my $site_catalyst = Business::SiteCatalyst->new( %$config );
ok(
	defined( $site_catalyst ),
	'Create a new Business::SiteCatalyst object.',
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



ok(
	defined(
		my $report = $site_catalyst->instantiate_report(
			type            => 'Ranked',
			report_suite_id => $report_suite_id
		)
	),
	'Instantiate a new Business::SiteCatalyst::Report.',
);

my $response;
throws_ok(
	sub
	{
		$response = $report->queue(
			dateFrom      => "2012-04-01",
			dateTo        => "2012-04-15",
			metrics       => [{"id" => "instances"}],
			elements      => [{"id" => "referrer","top" => "5"}],
			test_mode     => 1,
		);
	},
	qr/Fatal error/,
	'Queue report - test failure.',
);

lives_ok(
	sub
	{
		$response = $report->queue(
			dateFrom      => "2012-04-01",
			dateTo        => "2012-04-15",
			metrics       => [{"id" => "instances"}],
			elements      => [{"id" => "referrer","top" => "5"}]
		);
	},
	'Queue report.',
);

ok(
	Data::Validate::Type::is_hashref( $response ),
	'Retrieve response.',
) || diag( explain( $response ) );

like(
	$response->{'reportID'},
	qr/^\d+$/,
	'reportID is a number.',
);

is(
	$response->{'status'},
	'queued',
	'Report is queued.',
);


ok(
	open( FILE, '>', 'business-sitecatalyst-report-reportid.tmp'),
	'Open temp file to store report id'
);
	
print FILE "$response->{'reportID'}";

ok(
	close FILE,
	'Close temp file'
);
