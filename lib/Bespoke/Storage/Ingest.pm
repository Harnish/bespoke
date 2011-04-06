package Bespoke::Storage::Ingest;

###########################################################################
#                                                                         #
# Bespoke - Bespoke::Storage::Ingest                                      #
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
use File::Path ();
use File::Spec ();
use File::Copy ();
use Fcntl qw(:mode);
use Data::Dumper;
use Digest::SHA;

use base 'Bespoke::Base';
use version 0.77; our $VERSION = version->declare("v0.0.1");
require Bespoke::Storage::Blob;

=head1 NAME

Bespoke::Storage::Ingest - ingest data into blobs

=head1 DESCRIPTION

Use this to ingest data into storage as blobs.

A temporary file is managed in the staging area, ideally on the same host
filesystem to allow the final move operation to be atomic and copy-less.

=head1 SYNOPSIS

 use Bespoke::Storage::Ingest;

 my $in = Bespoke::Storage::Ingest->new();
 $in->write($data);
 my $blob = $in->finish;

=head1 METHODS

=over 4

=item new()

 my $blob = Bespoke::Storage::Ingest->new();

=cut

sub new {
    my($class, %args) = shift->init(@_);

    my $filename = $class->_tmpfile();
    my $stortemp = $class->get_config(@_)->get('storage_temp');
    my $filepath = File::Spec->catdir($stortemp, $filename);

    # IO::Handle/IO::File could be used here but are totally pointless
    # abstractions, especially if you look at the code. Just use the
    # perl builtins. They're idiomatic and more precise.
    open(my $fh, "> $filepath")
        or confess "Could not open '$filepath' for write: $!";

    # always run in binmode, we never look at the data
    binmode($fh);

    my $digest = Digest::SHA->new(512);
 
    return bless {
        filename => $filename,
        filepath => $filepath,
        handle   => $fh,
        digest   => $digest,
        bytes    => 0
    }, $class;
}

=item filepath(), filename(), handle(), digest()

Simple accessors.

 my $filepath = $in->filepath; # full file path from root
 my $filename = $in->filename; # just the filename
 my $handle   = $in->handle;   # backing fd
 my $digest   = $in->digest;   # Digest::SHA(512) object

=cut

sub filepath { shift->{filepath} }
sub filename { shift->{filename} }
sub handle   { shift->{handle}   }
sub digest   { shift->{digest}   }

=item write()

This is the primary way to write data into the staging file.

If manually using handle() to write, be sure to add the exact
same data to the digest object or your store will be corrupt.

 my $wrote_bytes = $in->write(data => $data);

 # this is the manual way, not guaranteed in the future
 print $in->handle $data;
 $in->digest->add($data);

=cut

sub write {
    my($self, %args) = shift->init(@_);

    # update SHA digest
    $self->{digest}->add($args{data});

    my $len = length($args{data});

    $self->{bytes} += $len;

    # I looked at the code to IO::Handle->write and it just calls print with
    # substr garbage so skip that mess - or switch to syswrite?
    print {$self->{handle}} $args{data};

    return $len;
}

=item finish()

Install the file into storage and clean up. A blob object is returned.

If the data already exists (deduplication), the original file is not modified
and a blob object is returned.  Bespoke::Storage::Metadata->create() will
automatically create a new metadata instance when you call that.

 my $blob = $in->finish;

=cut

sub finish {
    my $self = shift;

    # compute final digest
    my $digest = $self->{digest}->hexdigest;

    # object instantiation does not check the physical storage at all
    my $blob = Bespoke::Storage::Blob->new(digest => $digest); 

    my $dir = Bespoke::Storage->digest_to_path(digest => $digest);

    # if the directory exists, this content has already been ingested once
    # so don't mess with it
    if (-d $dir) {
        return $blob;
    }
    # create the directory mkdir -p style
    else {
        File::Path::make_path($dir, {mode => 0755});
    }

    # move the tempfile into place
    my $ok = File::Copy::move($self->filepath, $blob->path);
    confess "Failed to move/rename $self->{filepath} to ".$blob->path.": $!"
        unless $ok;

    return $blob;
}

=back

=head1 PRIVATE METHODS

The following are private methods and SHOULD not be used outside
of this class.

=over 4

=item _tmpfile()

Generates a unique-enough filename for the ingest staging area. The
returned string is sha160 hex digest of time . $$ . rand().

 my $fname = $in->_tmpfile();

=cut

sub _tmpfile {
    my $sha = Digest::SHA->new(1);

    # time + pid + random number
    # good enough, made opaue with SHA160
    $sha->add(time() . $$ . rand());

    return $sha->hexdigest . '.tmp';
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
