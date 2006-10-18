#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

use strict;
use warnings;
use Test::More tests => 27;
use Perl::Critic::Defaults;

#-----------------------------------------------------------------------------

{
    my $d = Perl::Critic::Defaults->new();
    is($d->force(),    0,           'native default force');
    is($d->color(),    1,           'native default color');
    is($d->only(),     0,           'native default only');
    is($d->severity(), 5,           'native default severity');
    is($d->theme(),    undef,       'native default theme');
    is($d->top(),      undef,       'native default top');
    is($d->verbose(),  3,           'native default verbose');
    is_deeply($d->include(), [],    'native default include');
    is_deeply($d->exclude(), [],    'native default exclude');
}

#-----------------------------------------------------------------------------

{
    #Without leading dash...
    my %user_defaults = (
         force     => 1,
         color     => 0,
         only      => 1,
         severity  => 4,
         theme     => 'pbp',
         top       => 50,
         verbose   => 7,
         include   => 'foo bar',
         exclude   => 'baz nuts',
    );

    my $d = Perl::Critic::Defaults->new( %user_defaults );
    is($d->force(),    1,           'user default force');
    is($d->color(),    0,           'user default color');
    is($d->only(),     1,           'user default only');
    is($d->severity(), 4,           'user default severity');
    is($d->theme(),    'pbp',       'user default theme');
    is($d->top(),      50,          'user default top');
    is($d->verbose(),  7,           'user default verbose');
    is_deeply($d->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($d->exclude(), [ qw(baz nuts)], 'user default exclude');
}

#-----------------------------------------------------------------------------

{
    #With a leading dash...
    my %user_defaults = (
         -force     => 1,
         -color     => 0,
         -only      => 1,
         -severity  => 4,
         -theme     => 'pbp',
         -top       => 50,
         -verbose   => 7,
         -include   => 'foo bar',
         -exclude   => 'baz nuts',
    );

    my $d = Perl::Critic::Defaults->new( %user_defaults );
    is($d->force(),    1,           'user default force');
    is($d->color(),    0,           'user default color');
    is($d->only(),     1,           'user default only');
    is($d->severity(), 4,           'user default severity');
    is($d->theme(),    'pbp',       'user default theme');
    is($d->top(),      50,          'user default top');
    is($d->verbose(),  7,           'user default verbose');
    is_deeply($d->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($d->exclude(), [ qw(baz nuts)], 'user default exclude');
}

