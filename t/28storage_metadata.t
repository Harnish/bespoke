#!/usr/bin/perl

use Test::More qw(no_plan);

use File::Spec;
use Directory::Scratch;
use String::Random;

use lib qw(./lib ../lib);
use Bespoke::TestUtil;
use Bespoke::Storage::Ingest;
use Bespoke::Storage::Blob;

use_ok('Bespoke::Storage::Metadata');

my @testblobs = Bespoke::TestUtil->generate_blobs(1);

foreach my $item (@testblobs) {
    diag($item->{digest});
    my $blob = $item->{blob};

    ok(my $meta = Bespoke::Storage::Metadata->create(digest => $blob->digest), "create()");
    ok($meta->instance, "instance()");
    ok($meta->set(filename => "/dev/urandom"), "set()");
    ok($meta->write(), "write()");
    ok(!$meta->mutable, "data is immutable after write()");
    is($meta->get('filename'), "/dev/urandom", "get()");

    ok(my $m2 = Bespoke::Storage::Metadata->new(digest => $blob->digest, instance => $meta->instance), "new()");
    is($m2->digest, $meta->digest, "compare created & new object digests");
    is($m2->instance, $meta->instance, "compare created & new object instances");
    is($m2->get('filename'), "/dev/urandom", "get()");
}

