package Bespoke::Storage;

###########################################################################
#                                                                         #
# Bespoke - Bespoke::Storage                                              #
# Copyright 2011-2011, Albert P. Tobey <tobert@gmail.com>                 #
# https://github.com/tobert/bespoke                                       #
#                                                                         #
# This is open source software.  Please see the LICENSE section at the    #
# end of this file or the README at the Github URL above.                 #
#                                                                         #
###########################################################################

use strict;
use warnings;
use Carp;
use IO::File;
use File::Path;
use Data::Dumper;
use Digest::SHA;

use base 'Bespoke::Base';
use version 0.77; our $VERSION = version->declare("v0.0.1");
use Bespoke::Config;

=head1 NAME

Bespoke::Storage - content addressible storage

=head1 DESCRIPTION

The goal of Bespoke is to generate all artifacts to be published to running systems
and store them permanently. This module provides a small & fairly simple storage
system for doing so. Alternatives could be using Git or Plan 9's Venti/Fossil
filesystems. One goal I have is to cram whole distros & packages in here, which is
something Git was never really good at. By using the CAS approach of storing things
according to the data's SHA512, some free things fall out like deduplicated binary
data.

=head1 SYNOPSIS

 use Bespoke::Storage;

=head1 METHODS

=over 4

=item digest_to_path() [CLASS METHOD]

Take a sha hex digest and return the directory for the content with the
given digest. An optional "filename" parameter can be passed in to have
it automatically appended the directory.

This method only generates the name and does absolutely no interaction with
the backend storage.

File::Spec->catdir is used internally to join paths.

 # "/srv/bespoke/storage/f7/fb/ba6e0636f89.../"
 my $path = Bespoke::Storage->digest_to_path(digest => $hex_digest);

 # note that the value of $config->storage_root is returned unsplit
 # ('/srv/bespoke/storage', 'f7', 'fb', 'ba6e0636f89...')
 my @path = Bespoke::Storage->digest_to_path(
     digest  => $hex_digest,
     as_list => 1 # return the path as a list of its parts
 );

 # "/srv/bespoke/storage/f7/fb/ba6e0636f89.../metadata.json"
 my @path = Bespoke::Storage->digest_to_path(
     digest   => $hex_digest,
     filename => "metadata.json"
 );

=cut

sub digest_to_path {
    my($self, %args) = shift->init(@_, required => ['digest']);
    my $config = $self->get_config(@_);

    my @path = (
        $config->get('storage_root'), # /root
        substr($args{digest}, 0, 2),  # /root/f7
        substr($args{digest}, 2, 2),  # /root/f7/fb
        substr($args{digest}, 4)      # /root/f7/fb/ba6e0636f89...
    );

    if ($args{filename}) {
        push @path, $args{filename}; # /root/f7/fb/ba6e0636f89.../$file
    }

    if ($args{as_list}) {
        return @path;
    }
    else {
        return File::Spec->catdir(@path);
    }
}

=item initialize()

Not necessary ... but won't hurt anything.  Note that on a quick test on ext3, this
consumed 258MB of disk space for just the empty directories. For small instances/tests
it's just not worth spending the disk space.

 perl -I./lib -e "use Bespoke::Config qw(storage_root /tmp/b); use Bespoke::Storage; Bespoke::Storage->initialize()"

=cut

sub initialize {
    my($self, %args) = shift->init(@_);
    my $config = $self->get_config(@_);

    my $base = $config->get('storage_root');

    # 2 levels of hex 00-FF directories (256^2 = 65536 directories)
    # far more than enough to keep any modern filesystem happy even with
    # billions of small files since the directory index is rarely accessed
    #
    # Git uses one level. This is sufficient for 1000's of files. Some of the early
    # tests of bespoke will easily go into millions.
    #
    # base/00
    # base/01
    # base/01/00
    # base/01/01
    # ...
    # base/FF/FF
    for (my $i=0; $i<256; $i++) {
        my $top = File::Spec->catdir($base, sprintf('%02x', $i));
        mkdir($top, 0755) or confess "Could not mkdir($top, 0755): $!";

        for (my $s=0; $s<256; $s++) {
            my $next = File::Spec->catdir($top, sprintf('%02x', $s));
            mkdir($next, 0755) or confess "Could not mkdir($next, 0755): $!";
        }
    }
}

=item verify()

=cut

sub _verify_visitor {
    my $blob = shift;
    my $storage  = $blob->storage;
    my $metadata = $blob->metadata;

    # verify data checksum

    # questions:
    # care about metadata with no locations?
}

sub verify {
    my($self, %args) = shift->init(@_);

    $self->visit_all(
        visitor => &_verify_visitor
    );
}

=item visit_all()

Walks every item in the storage using a depth-first walk. The first two levels are programmatically
walked with counters (no opendir/stat). The last level is enumerated with opendir/readdir.

With the 'arguments' parameter, the extra parameters from the arrayref will be passed in after the blob object.

 my $visitor_fun = sub {
     my($blob, $myarg1, $myarg2, $myarg3) = @_;
     # $blob isa Bespoke::Storage::Blob instance

     my $digest = $blob->digest;
     my $path   = $blob->path;

     # return values are discarded
 };

 Bespoke::Storage->visit_all(
     visitor => $visitor_fun
 );

 Bespoke::Storage->visit_all(
     visitor   => $visitor_fun,
     arguments => [$one, $two, $three]
 );

=cut

sub visit_all {
    my($self, %args) = shift->init(@_, required => ['visitor']);
    my @vargs;

    confess "'visitor' value must be a subroutine reference"
        unless (ref($args{visitor}) eq 'CODE');

    if ($args{arguments}) {
        if (ref($args{arguments}) eq 'ARRAY') {
            push @vargs, @{$args{arguments}};
        }
        else {
            confess "Argument list for visitor subref must be an ARRAY reference.";
        }
    }

    my $base = $self->get_config(@_)->get('storage_root');

    for (my $i=0; $i<16; $i++) {
        my $top = File::Spec->catdir($base, sprintf('%02x', $i));
        for (my $s=0; $s<16; $s++) {
            my $dir = File::Spec->catdir($top, sprintf('%02x', $s));

            next unless (-d $dir);

            opendir(my $dirfh, $dir)
                or confess "Could not opendir(..., $dir): $!";

            while (my $entry = readdir($dirfh)) {
                next unless length($entry) eq 124;
                next unless $entry =~ /[0-9a-fA-F]{124}/;

                my $digest = sprintf('%02x%02x%x', $i, $s, $entry);

                my $blob = Bespoke::Storage::Blob->new(hex_digest => $digest);

                $args{visitor}->($blob, @vargs);
            }
            closedir($dirfh);
        }
    }
}

=item visit_parallel()

Automatically parallelized (via fork()) visitation to every node in the storage system.

 Bespoke::Storage->visit_parallel(
     visitor => $visitor_fun
 );

=cut

sub visit_parallel {
    my($self, %args) = shift->init(@_);
}

=back

=head1 SEE ALSO

Plan 9 Venti/Fossil, CAS

 http://en.wikipedia.org/wiki/Content-addressable_storage
 http://en.wikipedia.org/wiki/Venti
 http://en.wikipedia.org/wiki/Fossil_(file_system)

=head1 AUTHORS

 Al Tobey <tobert@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2011 by Al Tobey.

This is free software; you can redistribute it and/or modify it under the terms
of the Artistic License 2.0.  (Note that, unlike the Artistic License 1.0,
version 2.0 is GPL compatible by itself, hence there is no benefit to having an
Artistic 2.0 / GPL disjunction.)  See the file LICENSE for details.

=cut

1;

# vim: et ts=4 sw=4 ai smarttab
