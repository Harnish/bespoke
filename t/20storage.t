#!/usr/bin/perl

use Test::More qw(no_plan);
use lib qw(./lib ../lib);
use File::Spec;

# must BEGIN or the import on Bespoke::Config will fail
our $tempdir;
BEGIN { $tempdir = "/tmp/b"; }

use Digest::SHA qw(sha512_hex);
use Bespoke::Config ('storage_root' => $tempdir);

# use PID so it changes every run
my $hex_digest = sha512_hex($$);
diag("Digest: $hex_digest");

use_ok("Bespoke::Storage");

my $c = Bespoke::Config->new();

is($c->get('storage_root'), $tempdir, "Check config of storage_root matches overriden value for testing");

ok(my $path = Bespoke::Storage->digest_to_path(digest => $hex_digest), "digest_to_path()");
diag("Path: $path");

is(
    substr($path, 0, length($tempdir)),
    $tempdir,
    "Check that the path starts with $tempdir"
);

my $offset = length($tempdir);
is(
    substr($path, $offset, 4),
    '/'.substr($hex_digest, 0, 2).'/',
    "Check first component of object path - first two hex digits"
);

is(
    substr($path, $offset + 3, 4),
    '/'.substr($hex_digest, 2, 2).'/',
    "Check second component of object path - next two hex digits"
);

is(
    substr($path, $offset + 7),
    substr($hex_digest, 4),
    "Check final component of object path - remainder of the digest"
);

ok(my @path = Bespoke::Storage->digest_to_path(
     digest  => $hex_digest,
     as_list => 1 # return the path as a list of its parts
   ), "digest_to_path( as_list => 1 )"
);

# remove the storage_root via regex, split, then re-append the storage root
# to match the output of as_list form
my $temppath = $path;
   $temppath =~ s#^$tempdir/?##;
my @splitpath = ($tempdir, File::Spec->splitdir($temppath));
ok(eq_array(\@path, \@splitpath), "Check as_list path values");

ok(my $fpath = Bespoke::Storage->digest_to_path(
     digest   => $hex_digest,
     filename => "metadata.json"
   ), "digest_to_path( filename => 'metadata.json' )"
);

ok($fpath =~ /metadata\.json$/, "check last element of path");
ok($fpath =~ m#^$tempdir#, "check first part of path");

