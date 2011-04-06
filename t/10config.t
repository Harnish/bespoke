#!/usr/bin/perl

use Test::More qw(no_plan);
use lib qw(./lib ../lib);

push @ARGV, "-Cfoo=bar";

use_ok("Bespoke::Config");

ok(my $c = Bespoke::Config->new, "new()");
ok($c->get('foo'), "get() [OBJECT]");
ok(Bespoke::Config->get('foo'), "get() [CLASS]");

