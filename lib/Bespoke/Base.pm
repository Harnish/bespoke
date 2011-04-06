package Bespoke::Base;

###########################################################################
#                                                                         #
# Bespoke::Base                                                           #
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
use Scalar::Util qw(blessed);

use version 0.77; our $VERSION = version->declare("v0.0.1");
require Bespoke::Config;

our $config_singleton;

=head1 NAME

Bespoke::Base - base class for Bespoke objects

=head1 DESCRIPTION

Basic object boilerplate code for Bespoke. Classes that subclass this
get an init() method that handles named parameters robustly along with
some accessors for Bespoke::Config.

=head1 SYNOPSIS

 use base 'Bespoke::Base';

=head1 METHODS

=over 4

=item init() [CLASS/OBJECT METHOD]

Takes care of all the boilerplate method initialization.

 sub foo {
     my($self, $config, %args) = shift->init(@_);
     ...
 }

 # supports a few different ways to call methods with named params
 $object->foo(asdf => 'bar', fdsa => 'foo', config => $c);
 $object->foo({asdf => 'bar', fdsa => 'foo', config => $c});
 $object->foo(asdf => 'bar', fdsa => 'foo');

Minimal argument presence checking is supported.

 sub bar {
     my($self, $config, %args) = shift->init(@_, required => ['asdf']);
     ...
 }

=cut

# partially derived from DBIx::Snug, since it worked pretty well there
sub init {
    my $self = shift; # could be a classname, that's fine

    # flatten lists, arrayrefs, and hashes into a list
    my @args;
    if (@_ % 2 == 0) {
        @args = @_;
    }
    elsif (ref $_[0] eq 'HASH') {
        @args = %{$_[0]};
    }
    elsif (ref $_[0] eq 'ARRAY') {
        confess "Arrayrefs are not supported as named parameter input.";
    }
    else {
        confess "$self: Invalid arguments.";
    }

    my %args_out;
    for (my $idx=0; $idx<=$#args; $idx+=2) {
        my($key, $value) = ($args[$idx], $args[$idx+1]);

        if (!exists $args_out{$key}) {
            $args_out{$key} = $value;
        }
        else {
            confess "BUG in Bespoke::Base! duplicate argument.";
        }
    }

    # support minimal arg presence checking
    # ->init(@_, required => [qw(abcd efg)])
    if ($args_out{required}) {
        if (ref($args_out{required}) eq 'ARRAY') {
            foreach my $arg (@{$args_out{required}}) {
                confess "'$arg' parameter is required." unless (exists $args_out{$arg});
            }
        }
        else {
            confess "BUG in subclass init() usage.";
        }
    }

    my $config = $self->get_config(%args_out);

    return($self, $config, %args_out);
}

=item init_positional()

Like init() but for positional (usually 1) arguments. For most functions with > 1 parameter,
arguments should be forced to be named.

 my($self, $config, @args) = shift->init_positional(@_);

=cut

sub init_positional {
    my $self = shift;
    my $config = $self->get_config(@_);
    return($self, $config, @_);
}

=item set_config()

=cut

sub set_config {
    my($self, $config, %args) = shift->init(@_);
    $self->{config} = $config;
}

=item get_config()

Returns the config handle passed to new().

 my $config = $object->get_config;

=cut

sub get_config {
    my $self = shift;

    # look for a Bespoke::Config object anywhere in the arglist
    # will work for positional & hash args, but not hashref unless
    # already expanded like init() does
    my($config) = grep { ref($_) eq 'Bespoke::Config' } @_;

    # most to least specific
    if ($config) {
        return $config;
    }
    elsif (blessed($self) and ref($self->{config}) eq 'Bespoke::Config') {
        return $self->{config};
    }
    else {
        return Bespoke::Config->new();
    }
}

=back

=head1 BUGS

See AUTHOR.

=head1 SEE ALSO

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
