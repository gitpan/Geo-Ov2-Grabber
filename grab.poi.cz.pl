#!/usr/bin/env perl

use LWP::UserAgent;
use HTML::TreeBuilder;
use Digest::Crc32;
use Data::Dumper;
use IO::Uncompress::Unzip;
use Text::Iconv;


my $timeout = 603;
my $timestep = 3;
my $count = 60;
my $type = ov2;
my $tocode = "ISO-8859-2";

my $directory = "";
$ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");

$oldh = select(STDOUT);
$| = 1;
select(STDERR);
$| = 1;
select($oldh);

Text::Iconv->raise_error(0);

printf "Grabbing types and list of categories... ";

my $req = HTTP::Request->new( GET => 'http://www.poi.cz/index.php?poi=sluco1');
#$req->content_type('application/x-www-form-urlencoded');
#$req->content('poi=sluco1');

my $res = $ua->request($req);

my $converter = Text::Iconv->new( "UTF-8", $tocode );

# Check the outcome of the response
if ($res->is_success) {

	printf "done\n";

	my ( @types, @ids );

	my $tree = HTML::TreeBuilder->new();
	$tree->parse( $res->content );

	for my $type ( $tree->look_down( "_tag", "input", "name", "r1" ) ) {
		push @typed, $type->attr_get_i("value");
		#printf "type: %s\n", $type->attr_get_i("value");
	}

	for my $id ( $tree->look_down( "_tag", "input", "name", "messageId[]" ) ) {
		push @ids, $id->attr_get_i("value");
		#printf "id: %s\n", $id->attr_get_i("value");;
	}

	$tree->delete;
	
	my $crc = new Digest::Crc32();
	my $offset = 0;
	my $errcount;
	while ( $offset <= $#ids ) {
		printf "getting from %d to %d...\n", $offset, $offset + $count;
		my $url = 'http://www.poi.cz/index.php?poi=sluco1&akce=tvor&r1=' . $type . '&' . toURLparams( $offset, $count, @ids ) .  '&nazev=CZ-&vse=vse&h1=Vytvo%C5%99it';
		printf "URL: %s\n", $url;
		$req = HTTP::Request->new( GET => $url );
		$req->referer("http://www.poi.cz/index.php?poi=sluco1");
		$res = $ua->request($req);
		my $time = time;
		#printf "time: %s\n", $time;
		my $data;
		$$data = $res->content;
		if ($res->is_success) {
			my $headers = $res->headers;
			printf "content: %s\n", $headers->header("content-type");
			if ( $headers->header("content-type") =~ m#application/x-zip# ) {
				my $z = new IO::Uncompress::Unzip $data, MultiStream => 0, Append => 1;
				my $c = 0;
				while ( not $z->eof ) {
					my $b = "";
					my $header = $z->getHeaderInfo();
					#printf "header: %s\n", Dumper($header);
					my $crc32 = $$header{CRC32};
					my $name = $converter->convert( $$header{Name} );
					$name = $$header{Name} unless $converter->retval;
					$name =~ s/^\s*//;
					$name =~ s/\s*$//;

					printf "%d: %s... ", $offset + $c++, $name;

					my $status;
					do { $status = $z->read($b) }  while ( $status > 0 );
					if ( $status != 0 ) {
						printf "Error reading %s from %s.\n", $name, $offset;
					}

					open ZIP, ">$directory$offset-$count.zip";
					print ZIP $$data;
					close ZIP;

					if ( not $name or not $crc32 ) {
						my $oldname = $name;
						$name = "scrap" unless $name;
						my $d = 0;
						while ( -e "$directory$name" ) {
							$name = $name . sprintf "%05d", $d++;
						}
						printf "bad header (crc: $crc32; name: $oldname) => saving to $directory$name.\n";
						open POI, ">$directory$name.zip";
						print POI $$data;
						close POI;
					}
					printf "saving to $directory$name... ";
					my $identical = 0;
					$identical = ( $crc->filecrc32( "$directory$name" ) == $crc32 ) if ( -e "$directory$name" and $crc32 );
					if ( not $identical and ( $crc->strcrc32( $b ) == $crc32 ) ) {
						open POI, ">$directory$name";
						print POI $b;
						close POI;
						printf "saved: %d bytes\n", length $b;
					} else {
						print "skipped\n";
					}
					printf STDERR "CRC does not match!!! Filename $name" if ( ( $crc->strcrc32( $b ) != $crc32 ) );
					$z->nextStream;
				}
				printf "offset: %d + %d\n", $offset, $count;
				$offset = $offset + $count;
			} else {
				$errcount++;
				if  ( $headers->header("content-type") =~ m#text# ) {
					if ( $$data =~ /Tento\s+limit\s+vypr\S+\s+za\s+(\d+)\s+s\./m ) {
						printf "Sta¾ení za %d sekund...\n", $1;
						$time = time + $1 - $timeout + 3;
					} else {
						printf "%s\n", $$data;
					}
				} else {
					printf "Bad content: %s\n", $headers->header("content-type");
				}
			}

			while ( $time + $timeout > time ) {
				printf "%d seconds left...\r", $time + $timeout - time if $ENV{TERM};
				sleep $timestep;
			}
			print "\n";

		} else {
			$errcount++;
			print $res->status_line, "\n";
		}
		if ( $errcount > $errtrigger ) {
			$offset = $offset + $count;
			$errcount=0;
		}
	}

} else {
	print $res->status_line, "\n";
}

sub toURLparams($$@) {
	my $offset = shift;
	my $count = shift;
	my @ids = @_;
	my $result = "";

	for ( my $i = $offset; $i < $offset + $count; $i++ ) {
		$result = $result . sprintf "&%s=%s", "messageId%5B%5D", $ids[$i] if $ids[$i];
	}
	return substr( $result, 1 );
}
