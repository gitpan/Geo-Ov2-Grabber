#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Geo::Ov2::Grabber' );
}

diag( "Testing Geo::Ov2::Grabber $Geo::Ov2::Grabber::VERSION, Perl $], $^X" );
