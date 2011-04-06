package Bespoke::Storage::Metadata;

###########################################################################
#                                                                         #
# Bespoke - Bespoke::Storage::Metadata                                    #
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
use Data::Dumper;
use Digest::SHA;
use Data::UUID;
use JSON::Any;

use base 'Bespoke::Base';
use version 0.77; our $VERSION = version->declare("v0.0.1");
require Bespoke::Storage;

=head1 NAME

Bespoke::Storage::Metadata - metadata access/manipulation

=head1 DESCRIPTION

Blobs are simply files with no weird headers/footers for metadata,
making them essentially anonymous. The metadata is tracked in the same directory
as a bunch of metadata-$UUID.json files. The UUID is the instance. They are not ordered
in any way and are totally independent of each other.

For deduplication purposes, metadata files contain dictionaries of attributes.  Each
additional metadata associated with a blob goes in its own file to avoid having to
do any kind of locking or transactions.

Once written, all data is immutable via this API.

=head1 SYNOPSIS

 my $meta = Bespoke::Storage::Metadata->new(
    digest   => $digest,
    instance => $instance
 );
 my $value = $meta->get($key);

 my $meta = Bespoke::Storage::Metadata->create(digest => $digest);
 $meta->set($key, $value);
 $meta->write;

=head1 METHODS

=over 4

=item new()

Return an object for accessing storage metadata.

 my $meta = Bespoke::Storage::Metadata->new(
    digest   => $digest,
    instance => $instance
 );

=cut

sub new {
    my($class, $config, %args) = shift->init(@_, required => ['digest', 'instance']);

    # each instance is in a metadata-$NUMBER.json file
    my $filename = Bespoke::Storage->digest_to_path(
        digest   => $args{digest},
        filename => sprintf('metadata-%s.json', $args{instance})
    );

    my $self = bless {
        digest    => $args{digest},
        instance  => $args{instance},
        filename  => $filename,
        data      => {}
    }, $class;

    $self->read() unless $args{defer_read};

    return $self;
}

=item create()

Create a new metadata instance associated with a blob's digest. A new UUID is
generated and the object is returned. No data is written to disk until ->write()
is called.

 my $meta = Bespoke::Storage::Metadata->create(digest => $digest);
 $meta->set(...);

=cut

sub create {
    my($class, $config, %args) = shift->init(@_, required => ['digest']);

    my $ug = Data::UUID->new();
    my $instance = lc($ug->create_str());

    my $self = $class->new(
        digest     => $args{digest},
        instance   => $instance,
        defer_read => 1
    );

    $self->{__writeable} = 1;

    return $self;
}

=item instance()

Return the instance UUID.

 my $inst = $meta->instance;

=cut

sub instance {
    my $self = shift;
    return $self->{instance};
}

=item digest()

Returns the digest the metadata belongs to.

 my $digest = $meta->digest;

=cut

sub digest {
    my $self = shift;
    return $self->{digest};
}

=item get()

Get a single key. This only takes the one argument, the key you want.

 my $val = $meta->get('filename');

=cut

sub get {
    my($self, $key) = @_;

    confess "No such key '$key'"
        unless (exists $self->{data}{$key});

    return $self->{data}{$key};
}

=item set()

Set a key/value. This only works between B::S::M->create and write().

 $meta->set(filename => '/bin/bash');
 $meta->set(filesize => -s '/bin/bash');

=cut

sub set {
    my($self, $key, $value) = @_;

    confess "set() called on metadata while it's immutable"
        unless ($self->{__writeable});

    $self->{data}{$key} = $value;
}

=item read()

Load metadata from storage. This is called automatically by new(), so there likely
isn't much use for this outside of the module unless you're hacking on metadata files
which you shouldn't be doing.

 $meta->read;

=cut

sub read {
    my($self, $config, %args) = shift->init(@_);

    open(my $fh, "< $self->{filename}")
        or confess "Could open read metadata file $self->{filename} for reading: $!";
    local $/ = undef;
    my $json = <$fh>;
    close $fh;

    my $jsa = JSON::Any->new();

    $self->{data} = $jsa->decode($json);

    return 1;
}

=item write()

Write the metadata out. The object is marked immutable after this. This is only
valid when create()'ing a new object.

 $meta->write;

=cut

sub write {
    my($self, $config, %args) = shift->init(@_);

    confess "write() is impossible on immutable metadata objects"
        unless ($self->{__writeable});

    open(my $fh, "> $self->{filename}")
        or confess "Could not open metadata file $self->{filename} for writing: $!";
    
    my $jsa = JSON::Any->new();
    print $fh $jsa->encode($self->{data});

    close $fh;

    delete $self->{__writeable};
}

=item mutable()

Check if the object is mutable.  true/false

 if ($meta->mutable) {
    $meta->set(...);
 }

=cut

sub mutable {
    my $self = shift;
    return $self->{__writeable};
}

=back

=head1 NOTE

This module uses JSON::Any to load a JSON serializer/deserializer. You probably want to
have JSON::XS installed, but regular JSON should be fine.

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
