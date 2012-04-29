package Business::SiteCatalyst::Company;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use Data::Validate::Type;


=head1 NAME

Business::SiteCatalyst::Company - Interface to Adobe Omniture SiteCatalyst's REST 'Company' API.


=head1 VERSION

Version 1.0.1

=cut

our $VERSION = '1.0.1';


=head1 SYNOPSIS

This module allows you to interact with Adobe SiteCatalyst, an analytics Service
Provider. It encapsulates all the communications with the API provided by Adobe
SiteCatalyst to offer a Perl interface for managing reports.

Please note that you will need to have purchased the Adobe SiteCatalyst product, and have web services enabled
first in order to obtain a web services shared secret, as well as agree with the Terms and Conditions for using the API.

	use Business::SiteCatalyst;
	
	# Create an object to communicate with Adobe SiteCatalyst
	my $site_catalyst = Business::SiteCatalyst->new(
		username        => 'dummyusername',
		shared_secret   => 'dummysecret',
	);
	
	# See SiteCatalyst API Explorer at https://developer.omniture.com/en_US/get-started/api-explorer
	# for Company documentation
	
	my $company = $site_catalyst->instantiate_company();
	
	my $token_data = $company->get_token_usage();
	
	my $tokens_left = $company->get_token_count();
	
	
=head1 METHODS

=head2 new()

Create a new Business::SiteCatalyst::Company object, which
will allow retrieval of SiteCatalyst company-specific info.

NOTE: This should not be called directly. Instead, use C<Business::SiteCatalyst->instantiate_company()>.

	my $company = Business::SiteCatalyst::Company->new(
		$site_catalyst,
	);

Parameters: none

=cut

sub new
{
	my ( $class, $site_catalyst, %args ) = @_;
	
	# Check for mandatory parameters
	Data::Validate::Type::is_instance( $site_catalyst, class => 'Business::SiteCatalyst')
		|| croak "First argument must be a Business::SiteCatalyst object";

	# Create the object
	my $self = bless(
		{
			site_catalyst   => $site_catalyst,
		},
		$class,
	);
	
	return $self;
}


=head2 get_token_count()

Determine the number of tokens left for your company. You are alloted 10,000 per month.

	my $tokens_left = $company->get_token_count();


=cut

sub get_token_count
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetTokenCount',
		data   => {'' => []}
	);
	
	return $response;
}



=head2 get_token_usage()

Information about the company's token usage for the current calendar month.

	my $token_data = $company->get_token_usage();


=cut

sub get_token_usage
{
	my ( $self, %args ) = @_;
	
	my $site_catalyst = $self->get_site_catalyst();
	
	my $response = $site_catalyst->send_request(
		method => 'Company.GetTokenUsage',
		data   => {'' => []}
	);
	
	return $response;
}


=head2 get_site_catalyst()

Get Business::SiteCatalyst object used when creating the current object.

	$report->get_site_catalyst();

=cut

sub get_site_catalyst
{
	my ( $self ) = @_;
	
	return $self->{'site_catalyst'};
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

	perldoc Business::SiteCatalyst::Company


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

Copyright 2012 Jennifer Pinkham.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
