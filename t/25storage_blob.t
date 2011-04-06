#!/usr/bin/perl

use Test::More qw(no_plan);

use File::Spec;
use Digest::SHA qw(sha512_hex);

use lib qw(./lib ../lib);
use Bespoke::TestUtil;
use Bespoke::Storage::Ingest;
use Bespoke::Storage::Metadata;

use_ok("Bespoke::Storage::Blob");

my @testblobs = Bespoke::TestUtil->generate_blobs(10);

foreach my $item (@testblobs) {
    diag($item->{digest});
    my $blob = $item->{blob};

    ok(-f $blob->path, "\$blob->path(): blob data file exists");

    ok(my $fh = $blob->open(), "\$blob->open()");
    ok(fileno($fh), "fileno()");
    is(-s $blob->path, $item->{size}, "Size matches data ingested");
    ok(my $gen = $blob->generate_digest, "generate_digest()");
    is($gen, $item->{digest}, "generated digest matches ingest digest");
    my @m = $blob->list_metadata();
    is(scalar @m, 0, "list_metadata() returns empty list [expected]");
    diag("Creating bogus metadata");
    my $meta = Bespoke::Storage::Metadata->create(digest => $item->{digest});
    $meta->set(filename => "/dev/urandom");
    $meta->write();
    ok(@m = $blob->list_metadata(), "list_metadata()");
    is(scalar @m, 1, "list_metadata() shows 1 instance");
}

