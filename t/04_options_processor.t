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
use Perl::Critic::Utils qw< :booleans >;

use Test::More tests => 27;

#-----------------------------------------------------------------------------

our $VERSION = '1.095_001';

#-----------------------------------------------------------------------------

{
    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $color = -t *STDOUT ? $TRUE : $FALSE; ## no critic (ProhibitInteractiveTest)

    my $processor = Perl::Critic::OptionsProcessor->new();
    is($processor->force(),    0,           'native default force');
    is($processor->only(),     0,           'native default only');
    is($processor->severity(), 5,           'native default severity');
    is($processor->theme(),    q{},         'native default theme');
    is($processor->top(),      0,           'native default top');
    is($processor->color(),    $color,      'native default color');
    is($processor->pager(),    q{},         'native default pager');
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
         color     => $FALSE,
         pager     => 'less',
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
    is($processor->color(),    $FALSE,      'user default color');
    is($processor->pager(),    'less',      'user default pager');
    is($processor->verbose(),  7,           'user default verbose');
    is($processor->criticism_fatal(),  1,   'user default criticism_fatal');
    is_deeply($processor->include(), [ qw(foo bar) ], 'user default include');
    is_deeply($processor->exclude(), [ qw(baz nuts)], 'user default exclude');
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 1 );
    is($processor->color(), $TRUE, 'user default colour true');

    $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 0 );
    is($processor->color(), $FALSE, 'user default colour false');
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::Critic::OptionsProcessor->new( pager => 'foo' );
    is($processor->color(), $FALSE, 'pager set turns off color');
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
