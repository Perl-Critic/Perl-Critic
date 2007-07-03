#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 18;
use Perl::Critic::Defaults;

#-----------------------------------------------------------------------------

{
    my $d = Perl::Critic::Defaults->new();
    is($d->force(),    0,           'native default force');
    is($d->only(),     0,           'native default only');
    is($d->severity(), 5,           'native default severity');
    is($d->theme(),    q{},         'native default theme');
    is($d->top(),      0,           'native default top');
    is($d->verbose(),  4,           'native default verbose');
    is_deeply($d->include(), [],    'native default include');
    is_deeply($d->exclude(), [],    'native default exclude');
}

#-----------------------------------------------------------------------------

{
    my %user_defaults = (
         force     => 1,
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
    is($d->only(),     1,           'user default only');
    is($d->severity(), 4,           'user default severity');
    is($d->theme(),    'pbp',       'user default theme');
    is($d->top(),      50,          'user default top');
    is($d->verbose(),  7,           'user default verbose');
    is_deeply($d->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($d->exclude(), [ qw(baz nuts)], 'user default exclude');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my %invalid_defaults = (
        foo => 1,
        bar => 2,
    );

    eval { Perl::Critic::Defaults->new( %invalid_defaults ) };
    like( $EVAL_ERROR, qr/^"foo" is not a supported option/m, 'First invalid default' );
    like( $EVAL_ERROR, qr/^"bar" is not a supported option/m, 'Second invalid default' );

}

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
