#!/usr/bin/perl

use Test::More qw(no_plan);

use File::Spec;
use Digest::SHA qw(sha512_hex);
use Directory::Scratch;

use lib qw(./lib ../lib);
use Bespoke::TestUtil; # sets up config, has functions

use_ok('Bespoke::Storage::Ingest');

# first set: write an in-memory bit of (lorem ipsum) text to a blob
diag();
diag("\nLorem Ipsum short, memory -> blob\n\n");

my $data = Bespoke::TestUtil->lorem_ipsum_short;
my $data_digest = sha512_hex($data);

ok(my $in = Bespoke::Storage::Ingest->new(), "new()");
ok($in->write(data => $data), "write()");
ok(my $blob = $in->finish, "finish()");
diag("Blob Digest: ".$blob->digest);
diag("Data Digest: $data_digest");
is($blob->digest, $data_digest, "Check new blob's digest matches original data's");

# second set: write lorem ipsum long to a file, then stream that file into a blob
diag();
diag("\nLorem Ipsum long, file -> blob\n\n");

ok(my $in2 = Bespoke::Storage::Ingest->new(), "new()");
my($txtfile, $digest2) = Bespoke::TestUtil->text_test_file();
ok(open(my $fh, "< $txtfile"), "open test text file, $txtfile");
while (my $line = <$fh>) {
    $in2->write(data => $line);
}
close $fh;
ok(my $blob2 = $in2->finish, "finish()");
diag("Blob2 Digest: ".$blob2->digest);
diag("Data2 Digest: $digest2");
is($blob2->digest, $digest2, "Compare hard-coded digest to blob's digest");

# third set: write random binary data from /dev/urandom to a blob
diag("\n/dev/urandom -> memory -> blob\n\n");

open($fh, "</dev/urandom")
    or die "Could not open /dev/urandom for reading: $!";
binmode($fh);
ok(read($fh, my $bindata, 8192) == 8192, "read some binary data from /dev/urandom");
close $fh;
my $d3_digest = sha512_hex($bindata);
ok(my $in3 = Bespoke::Storage::Ingest->new(), "new()");
ok($in3->write(data => $bindata), "write()");
ok(my $blob3 = $in3->finish, "finish()");
diag("Bin   Digest: $d3_digest");
diag("Blob3 Digest: ".$blob3->digest);
is($d3_digest, $blob3->digest, "Compare in-memory digest to blob digest");

