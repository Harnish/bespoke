use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Bespoke',
    AUTHOR              => q{Al Tobey <tobert@gmail.com>},
    VERSION_FROM        => 'lib/Bespoke/Base.pm',
    ABSTRACT            => 'infrastructure as code, all of it, forever',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Digest::SHA' => 5.61,
        'JSON::Any'   => 0,
        'Data::UUID'  => 0,
        'File::Copy'  => 0,
        'File::Spec'  => 0,
        'File::Path'  => 0,
        # testing only
        'Test::More'         => 0,
        'String::Random'     => 0,
        'Directory::Scratch' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Bespoke-*' },
);
