use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Geo::Ov2::Grabber',
    AUTHOR              => 'hPa <hpa@suteren.net>',
    VERSION_FROM        => 'lib/Geo/Ov2/Grabber.pm',
    EXE_FILES           => ['ov2ss', 'grab.poi.cz.pl'],
    ABSTRACT_FROM       => 'lib/Geo/Ov2/Grabber.pm',
    PL_FILES            => {},
    PREREQ_FATAL        => 0,
    PREREQ_PRINT        => 1,
    NORECURS            => 0,
    PREREQ_PM => {
        'Test::More' => 0,
        'POSIX' => 0,
        'locale' => 0,
        'Getopt::Long' => 0,
        'Locale::TextDomain' => 0,
        'Pod::Usage' => 0,
        'Config::General' => 0,
        'File::Basename' => 0,
        'File::Copy' => 0,
        'Geo::Ov2' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-Ov2-Grabber-*' },
);
