#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::OptionsProcessor;

use Test::More tests => 24;

#-----------------------------------------------------------------------------

our $VERSION = '1.089';

#-----------------------------------------------------------------------------

{
    my $processor = Perl::Critic::OptionsProcessor->new();
    is($processor->force(),    0,           'native default force');
    is($processor->only(),     0,           'native default only');
    is($processor->severity(), 5,           'native default severity');
    is($processor->theme(),    q{},         'native default theme');
    is($processor->top(),      0,           'native default top');
    is($processor->color(),    1,           'native default color');
    is($processor->verbose(),  4,           'native default verbose');
    is($processor->criticism_fatal,   0,    'native default criticism-fatal');
    is_deeply($processor->include(), [],    'native default include');
    is_deeply($processor->exclude(), [],    'native default exclude');
}

#-----------------------------------------------------------------------------

{
    my %user_defaults = (
         force     => 1,
         only      => 1,
         severity  => 4,
         theme     => 'pbp',
         top       => 50,
         color     => 0,
         verbose   => 7,
         'criticism-fatal'   => 1,
         include   => 'foo bar',
         exclude   => 'baz nuts',
    );

    my $processor = Perl::Critic::OptionsProcessor->new( %user_defaults );
    is($processor->force(),    1,           'user default force');
    is($processor->only(),     1,           'user default only');
    is($processor->severity(), 4,           'user default severity');
    is($processor->theme(),    'pbp',       'user default theme');
    is($processor->top(),      50,          'user default top');
    is($processor->color(),    0,           'user default color');
    is($processor->verbose(),  7,           'user default verbose');
    is($processor->criticism_fatal(),  1,   'user default criticism_fatal');
    is_deeply($processor->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($processor->exclude(), [ qw(baz nuts)], 'user default exclude');
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 1 );
    is($processor->color(), 1, 'user default colour true');

    $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 0 );
    is($processor->color(), 0, 'user default colour false');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my %invalid_defaults = (
        foo => 1,
        bar => 2,
    );

    eval { Perl::Critic::OptionsProcessor->new( %invalid_defaults ) };
    like(
        $EVAL_ERROR,
        qr/"foo" [ ] is [ ] not [ ] a [ ] supported [ ] option/xms,
        'First invalid default',
    );
    like(
        $EVAL_ERROR,
        qr/"bar" [ ] is [ ] not [ ] a [ ] supported [ ] option/xms,
        'Second invalid default',
    );

}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/04_defaults.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
