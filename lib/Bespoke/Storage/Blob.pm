package Bespoke::Storage::Blob;

###########################################################################
#                                                                         #
# Bespoke - Bespoke::Storage::Blob                                        #
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
use File::Path;
use File::Spec;
use Data::Dumper;
use Digest::SHA;

use base 'Bespoke::Base';
use version 0.77; our $VERSION = version->declare("v0.0.1");
require Bespoke::Storage;

=head1 NAME

Bespoke::Storage::Blob - stored data

=head1 DESCRIPTION

Methods for dealing with storage blobs. To create them, see Bespoke::Storage::Ingest.

=head1 SYNOPSIS

 use Bespoke::Storage::Blob;

=head1 METHODS

=over 4

=item new()

Create an object for working with blobs.

 my $blob = Bespoke::Storage::Blob->new(digest => $hex_digest);

=cut

sub new {
    my($self, %args) = shift->init(@_, required => ['digest']);

    my $blob_path = Bespoke::Storage->digest_to_path(
        digest   => $args{digest},
        filename => 'DATA'
    );

    return bless {
        digest    => $args{digest},
        blob_path => $blob_path
    }, $self;
}

=item path()

Returns the physical filesystem path to the blob.

 my $path = $blob->path;

=cut

sub path {
    my $self = shift;
    return $self->{blob_path};
}

=item digest()

Simple accessor to the file digest.

=cut

sub digest {
    my $self = shift;
    return $self->{digest};
}

=item open()

Opens the blob for reading. A regular scalar filehandle is returned.
Multiple opens can be made in the same runtime without issue.
binmode is enabled by default.

 my $fh = $blob->open();

=cut

sub open {
    my $self = shift;

    open(my $fh, "< $self->{blob_path}")
        or confess "Could not open blob $self->{blob_path} for reading: $!";

    binmode($fh);

    return $fh;
}

=item generate_digest()

Regenerate the SHA512 digest and return it.

Mostly meant for internal use by Bespoke::Storage, but possibly
useful elsewhere if you're paranoid.

 my $digest = $blob->generate_digest;

=cut

sub generate_digest {
    my $self = shift;

    my @stat = stat($self->{blob_path});
    my $fh = $self->open();
    my $sha = Digest::SHA->new(512);

    # read 4k chunks and add to Digest::SHA
    my $total = 0;
    while ($total < $stat[7]) {
        my $bytes = read($fh, my $buffer, 4096);
        $total += $bytes;

        confess "Failed read() around byte $total in $self->{blob_path}: $!"
            unless defined $bytes;

        $sha->add($buffer);

        last if ($bytes == 0); # eof
    }
    close $fh;

    my $digest = $sha->hexdigest;

    return $digest;
}

=item list_metadata()

Return a list of metadata associated with the blob.

 my @metadata = $blob->list_metadata; # list of Bespoke::Storage::Metadata

 my @metadata = Bespoke::Storage::Metadata->list(digest => $hex_digest);

=cut

#/tmp/IEmaF4a8Dg/storage/bc/fe/863be254386cdb8d3680470dbb93fbb7ae949e268f27e55c6391d1c1a14fdbe7bb444e85bf0b4be4d5bba5e71cb8f0c6cf7262b2d3bfa66db25837b33b1b/metadata-b0460734-5ff0-11e0-881b-9356e0da2529.json
sub list_metadata {
    my $self = shift;

    my @instances;
    my $dir = Bespoke::Storage->digest_to_path(digest => $self->{digest});

    opendir(my $dh, $dir)
        or confess "opendir(..., $dir) failed: $!";
    while (my $file = readdir($dh)) {
        if ($file =~ /^metadata-([-\w]{36}).json$/) {
            push @instances, $1; 
        }
    }
    closedir($dh);

    return map {
        Bespoke::Storage::Metadata->new(
            digest   => $self->{digest},
            instance => $_
        )
    } @instances;
}

=back

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
