package Bespoke::Config;

###########################################################################
#                                                                         #
# Bespoke - Bespoke::Config                                               #
# Copyright 2011-2011, Albert P. Tobey <tobert@gmail.com>                 #
# https://github.com/tobert/bespoke                                       #
#                                                                         #
# This is open source software.  Please see the LICENSE section at the    #
# end of this file or the README at the Github URL above.                 #
#                                                                         #
###########################################################################

use strict;
use warnings;
use Getopt::Long;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;
use JSON;

use version 0.77; our $VERSION = version->declare("v0.0.1");

our @ARGV_COPY;
BEGIN {
    # grab a copy of @ARGV as early as possible for great justice
    @ARGV_COPY = @ARGV;
}

# no config file for now, just put stuff in here and adjust via -C on ARGV
our %config = (
    bespoke_root => '/srv/bespoke',
    storage_root => '/srv/bespoke/storage',
    storage_temp => '/srv/bespoke/tmp'
);

=head1 NAME

Bespoke::Config - configuration values for Bespoke

=head1 SYNOPSIS

 use Bespoke::Config;

 my $config = Bespoke::Config->new();
 my $value = $config->get("foo");

 my $value = Bespoke::Config->get("foo");

=head1 DESCRIPTION

This module takes care of parsing and storing configuration data.

Ironically, all the values are hard-coded in here and you are discouraged
from tinkering with them at this time. Configurability is nice at times,
but really hard to test & support, so I'll come back to that later if
it starts to make sense (e.g. many actual users asking for it).

This module snaps an early copy of @ARGV so it can grab -Cfoo=bar arguments
to modify configuration parameters on the fly. This is mainly for testing
purposes and is automatically enabled.

No functions are exported.

=head1 METHODS

=over 4

=item new()

=cut

sub new {
    my $class = shift;
    my $self = undef;
    return bless \$self, $class;
}

=item import()

Applies import and CLI overrides to the global configuration.

The import overrides are mostly used for testing. CLI overrides may
be handy elsewhere.

 use Bespoke::Config (storage_root => '/tmp');

=cut

sub import {
    my $class = shift;

    # allow setting/overriding values at import time
    if (@_ > 0 and @_ % 2 == 0) {
        for (my $i=0; $i<@_; $i+=2) {
            confess "$_[$i] is an invalid config parameter"
                unless exists $config{$_[$i]};
            $config{$_[$i]} = $_[$i+1];
        }
    }

    # allow CLI overrides with -Ckey=value
    for (my $i=0; $i<=$#ARGV_COPY; $i++) {
        if ($ARGV_COPY[$i] =~ /-C(\w+)=(.*)/) {
            $config{$1} = $2;
        }
    }
}

=item get()

Returns any value from the global configuration.  Throws an exception
if the key does not exist.   A second argument set to true will
prevent exceptions for non-existent keys.

 my $pfile = $config->get('pidfile');
 my $pfile = Bespoke::Config->get('pidfile');
 my $pfile = Bespoke::Config->get('pidfile', 1);

=cut

sub get {
    my($self, $key, $safe) = @_;

    if ( $ENV{BESPOKE_DEBUG} && !exists $config{$key} ) {
        warn Dumper(\%config);
    }

    if ($safe) {
        return undef unless exists $config{$key};
    }
    else {
        confess "Tried to fetch invalid key \"$key\"."
            unless exists $config{$key};
    }

    return $config{$key};
}

=item dump()

Return a Data::Dumper string of the config hash.

=cut

sub dump {
    return Dumper(\%config);
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
