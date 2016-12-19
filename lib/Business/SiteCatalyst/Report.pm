package Business::SiteCatalyst::Report;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Data::Validate::Type;


=head1 NAME

Business::SiteCatalyst::Report - Interface to Adobe Omniture SiteCatalyst's REST API 'Report' module.


=head1 VERSION

Version 1.2.2

=cut

our $VERSION = '1.4.0';


=head1 SYNOPSIS

This module allows you to interact with Adobe (formerly Omniture) SiteCatalyst,
a web analytics service. It encapsulates all the communications with the API 
provided by Adobe SiteCatalyst to offer a Perl interface for managing reports,
pulling company-specific SiteCatalyst data (ex: token usage), uploading SAINT 
data (feature not implemented yet), etc.

Please note that you will need to have purchased the Adobe SiteCatalyst product,
and have web services enabled within your account first in order to obtain a web
services shared secret, as well as agree with the Terms and Conditions for using
the API.

	use Business::SiteCatalyst;
	
	# Create an object to communicate with Adobe SiteCatalyst
	my $site_catalyst = Business::SiteCatalyst->new(
		username        => 'dummyusername',
		shared_secret   => 'dummysecret',
		api_subdomain   => 'api|api2|api3|api4|api5', #optional; default value='api'
	);
	
	my $report = $site_catalyst->instantiate_report(
		type            => 'report type',
		report_suite_id => 'report suite id',
	);
	
	# See SiteCatalyst API Explorer at
	# https://developer.omniture.com/en_US/get-started/api-explorer
	# for Report.Queue[Trended|Ranked|Overtime|Pathing|Fallout|Summary|Real-Time] documentation
	
	$report->queue(
		%report_arguments, #report-dependant
	);
	
	my $results;
	for ( my $tries = 0; $tries < 20; tries++ )
	{
		if ( $report->is_ready() )
		{
			$results = $report->retrieve();
			last;
		}
		else
		{
			sleep 5;
		}
	}
	
	unless ( defined $results )
	{
		$cancel_success = $report->cancel();
	}

=head1 METHODS

=head2 new()

Create a new Business::SiteCatalyst::Report object, which
will allow retrieval of SiteCatalyst reports.

NOTE: This should not be called directly. Instead, use C<Business::SiteCatalyst->instantiate_report()>.

	my $report = Business::SiteCatalyst::Report->new(
		$site_catalyst,
		report_suite_id => 'report suite id',
	);

Parameters:

=over 4

=item * report_suite_id

The Report Suite ID you want to pull data from.

=back

=cut

sub new
{
	my ( $class, $site_catalyst, %args ) = @_;
	
	# Check for mandatory parameters
	Data::Validate::Type::is_instance( $site_catalyst, class => 'Business::SiteCatalyst')
		|| croak "First argument must be a Business::SiteCatalyst object";

	my $mode = defined $args{'report_id'} ? "existing" : "new";
		
	my %required_arguments = (
		'report_id'       => 'existing',
		'report_suite_id' => 'new',
	);
		
	foreach my $arg ( keys %required_arguments )
	{
		if ( $required_arguments{ $arg } eq $mode )
		{
			croak "Argument '$arg' is needed to create the Business::SiteCatalyst::Report object"
				if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
		}
		else
		{
			croak "Argument '$arg' is not valid when loading '$mode' report"
				if defined( $args{$arg} );
		}
	}

	# Create the object
	my $self = bless(
		{
			site_catalyst   => $site_catalyst,
			report_suite_id => $args{'report_suite_id'},
			id              => $args{'report_id'},
		},
		$class,
	);
	
	return $self;
}


=head2 queue()

Queue a Business::SiteCatalyst report.

	$report->queue( %report_arguments );

	# Example: Top 5 referrers report
	$report->queue(
		dateFrom      => "2012-04-01",
		dateTo        => "2012-04-15",
		metrics       => [{"id" => "instances"}],
		elements      => [{"id" => "referrer","top" => "5"}]
	);

=cut

sub queue
{
	my ( $self, %args ) = @_;
	
	$self->{report_response} = undef;
	
	my $site_catalyst = $self->get_site_catalyst();
	my $verbose = $site_catalyst->verbose();

	my $response = $site_catalyst->send_request(
		method    => 'Report.Queue',
		data      =>
		{
			reportDescription =>
				{
					reportSuiteID => $self->{'report_suite_id'},
					%args,
				}
		},
		test_mode => defined $args{'test_mode'} ? $args{'test_mode'} : 0,
	);
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	elsif ( !defined($response->{'reportID'}) )
	{
		carp "Full response: " . Dumper($response) if $verbose;
		croak "Fatal error. Missing reportID in response.";
	}

	# Store report id; we'll need it to check the status
	$self->{'id'} = $response->{'reportID'};
	
	return $response;
}


=head2 is_ready()

Check if a queued report is completed yet.

	my $boolean = $report->is_ready();

=cut

sub is_ready
{
	my ( $self, %args ) = @_;
	
	return $self->get( %args );
	
}


=head2 retrieve()

Return report results from previously fetched by calling
is_ready().

	my $results = $report->retrieve();

=cut

sub retrieve
{
	my ( $self, %args ) = @_;
	
	if ( ! $self->{report_response} ) {
		croak "Please call is_ready() before attempting retrieval. Report is not done.";
	}
	return $self->{report_response};
}

=head2 get()

Calls Report.Get to get report results from Adobe SiteCatalyst,
OR the 'error': report_not_valid. If the report is ready, it is stored
in memory so retrieve() can return it.

	my $results = $report->get();

=cut

sub get
{
	my ( $self, %args ) = @_;
		
	my $site_catalyst = $self->get_site_catalyst();
	my $verbose = $site_catalyst->verbose();
	
	my $response = $site_catalyst->send_request(
		method    => 'Report.Get',
		data      =>
		{
			reportID => $self->get_id(),
		},
		test_mode => defined $args{'test_mode'} ? $args{'test_mode'} : 0,
		content_on_error => 1,       # adobe send a 400 error if the report is not ready
	);
	
	if (
		  !defined($response)
	 || ( !defined($response->{'runSeconds'}) && !defined($response->{'error'}) )
	) {
		croak "Fatal error. No response, or missing [ runSeconds and error ] in response";
	}
	elsif ( $response->{'status'} eq 'error' || $response->{'status'} eq 'failed' ) # are these still valid in 1.4?
	{
		carp "Full response: " . Dumper($response) if $verbose;
		croak "Something went wrong with this report!";
	}
	elsif ( defined($response->{'error'}) && $response->{'error'} eq 'report_not_ready' )
	{
		carp "Report not ready";
		return 0
	}
	elsif ( !defined($response->{'report'}) )
	{
		croak "Unhandled response in get():\n" . to_json( $response, { pretty => 1 } );
	}
	
	$self->{report_response} = $response->{'report'};
	
	return 1;
}


=head2 cancel()

Cancel previously submitted report request, and removes it from processing queue.
Returns 1 if successful, otherwise 0.

	my $cancel_success = $report->cancel();

=cut

sub cancel
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	my $verbose = $site_catalyst->verbose();
	
	my $response;
	if ( defined $args{'test_mode'} && $args{'test_mode'} == 1 )
	{
		$response = undef;
	}
	else
	{
		$response = $site_catalyst->send_request(
			method    => 'Report.CancelReport',
			data      =>
			{
				reportID => $self->get_id(),
			},
		);
	}
	
	if ( !defined($response) )
	{
		croak "Fatal error. No response.";
	}
	
	return $response;
}


=head2 get_site_catalyst()

Get Business::SiteCatalyst object used when creating the current object.

	my $site_catalyst = $report->get_site_catalyst();

=cut

sub get_site_catalyst
{
	my ( $self ) = @_;
	
	return $self->{'site_catalyst'};
}


=head2 get_id()

Get the report ID returned by Adobe SiteCatalyst when we queued the report.

	my $report_id = $report->get_id();

=cut

sub get_id
{
	my ( $self ) = @_;
	
	return $self->{'id'};
}


=head1 AUTHOR

Jennifer Pinkham, C<< <jpinkham at cpan.org> >>.


=head1 BUGS

Please report any bugs or feature requests to C<bug-Business-SiteCatalyst at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-SiteCatalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Business::SiteCatalyst::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-SiteCatalyst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-SiteCatalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-SiteCatalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-SiteCatalyst/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to ThinkGeek (L<http://www.thinkgeek.com/>) and its corporate overlords
at Geeknet (L<http://www.geek.net/>), for footing the bill while I write code for them!
Special thanks for technical help from fellow ThinkGeek CPAN author Guillaume Aubert L<http://search.cpan.org/~aubertg/>


=head1 COPYRIGHT & LICENSE

Copyright 2013 Jennifer Pinkham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
