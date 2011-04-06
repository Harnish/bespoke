#!/usr/bin/perl

use JSON;
use Data::Dumper;

my $x = {
    foo => 'bar',
    a => rand(),
    b => rand(),
    c => $$,
    d => time(),
    e => "lorem ipsum",
    f => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
};

my $json = JSON::to_json($x);

print Dumper(JSON::from_json($json));

my $json .= JSON::to_json($x);

print Dumper(JSON::from_json($json));
