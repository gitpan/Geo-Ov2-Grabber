package Geo::Ov2::Grabber;

use warnings;
use strict;
use Carp;
use Module::Util qw( :all );
use Module::Runtime qw(is_valid_module_name require_module use_module use_package_optimistically is_valid_module_spec compose_module_name);


=head1 NAME

Geo::Ov2::Grabber - The great new Geo::Ov2::Grabber!

=head1 VERSION

Version 0.01_01

=cut

our $VERSION = '0.01_01';

our %grabber_modules;
our $OVG = undef;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Geo::Ov2::Grabber;

    my $foo = Geo::Ov2::Grabber->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 new

=cut

sub new {
	return $OVG if $OVG;
	my $class = shift;
	my $params = shift;
	my $self = {};
	bless $self, $class;
	my $packagebase = __PACKAGE__;
	my $packagegrabber = "${packagebase}";
	my @denied_grabbers = ( );
	push @denied_grabbers, @{$$params{denied_grabbers}} if @{$$params{denied_grabbers}};
	foreach my $module ( find_in_namespace( $packagegrabber ) ) {
		next if grep( /^$module$/, ( @denied_grabbers ) );
		use_module( $module );
		my $m = new $module;
		carp( sprintf "Duplicate grabber alias: %s!", $m->alias ) if exists $grabber_modules{$m->alias};
		$grabber_modules{$m->alias} = $m;
	}
	$OVG=$self;
	return $self;
}


sub grab_all() {
	my $self = shift;
	my $error = 0;
	foreach my $i ( values %grabber_modules ) {
		$error = ( $error or $i->grab );
	}
	return $error;
}

sub grab($) {
	my $self = shift;
	my $grabber = shift;
	return $grabber_modules{$grabber}->grab;
}

sub list_grabbers {
	return keys %grabber_modules;
}

=head1 AUTHOR

hPa, C<< <hpa at suteren.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-geo-ov2-grabber at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Ov2-Grabber>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Ov2::Grabber

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Ov2-Grabber>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Ov2-Grabber>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Ov2-Grabber>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Ov2-Grabber>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 hPa, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Geo::Ov2::Grabber
