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
use Perl::Critic::Utils::Constants qw< :color_severity >;

use Test::More tests => 54;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

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
    is($processor->color_severity_highest(),
                               $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT,
                               'native default color-severity-highest');
    is($processor->color_severity_high(),
                               $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT,
                               'native default color-severity-high');
    is($processor->color_severity_medium(),
                               $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT,
                               'native default color-severity-medium');
    is($processor->color_severity_low(),
                               $PROFILE_COLOR_SEVERITY_LOW_DEFAULT,
                               'native default color-severity-low');
    is($processor->color_severity_lowest(),
                               $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT,
                               'native default color-severity-lowest');
    is_deeply($processor->program_extensions(), [],
                               'native default program extensions');
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
         'color-severity-highest'   => 'chartreuse',
         'color-severity-high'      => 'fuschia',
         'color-severity-medium'    => 'blue',
         'color-severity-low'       => 'gray',
         'color-severity-lowest'    => 'scots tartan',
         'program-extensions'  => '.PL .pl .t',
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
    is($processor->color_severity_highest(),
                                'chartreuse', 'user default color_severity_highest');
    is($processor->color_severity_high(),
                                'fuschia',  'user default color_severity_high');
    is($processor->color_severity_medium(),
                                'blue',     'user default color_severity_medium');
    is($processor->color_severity_low(),
                                'gray',     'user default color_severity_low');
    is($processor->color_severity_lowest(),
                                'scots tartan', 'user default color_severity_lowest');
    is_deeply($processor->program_extensions(), [ qw(.PL .pl .t) ],
                                            'user default program-extensions');
}

#-----------------------------------------------------------------------------

{
    my $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 1 );
    is($processor->color(), $TRUE, 'user default colour true');

    $processor = Perl::Critic::OptionsProcessor->new( 'colour' => 0 );
    is($processor->color(), $FALSE, 'user default colour false');

    $processor = Perl::Critic::OptionsProcessor->new(
         'colour-severity-highest'   => 'chartreuse',
         'colour-severity-high'      => 'fuschia',
         'colour-severity-medium'    => 'blue',
         'colour-severity-low'       => 'gray',
         'colour-severity-lowest'    => 'scots tartan',
    );
    is( $processor->color_severity_highest(),
        'chartreuse',       'user default colour-severity-highest' );
    is( $processor->color_severity_high(),
        'fuschia',          'user default colour-severity-high' );
    is( $processor->color_severity_medium(),
        'blue',             'user default colour-severity-medium' );
    is( $processor->color_severity_low(),
        'gray',             'user default colour-severity-low' );
    is( $processor->color_severity_lowest(),
        'scots tartan',     'user default colour-severity-lowest' );

    $processor = Perl::Critic::OptionsProcessor->new(
         'color-severity-5'    => 'chartreuse',
         'color-severity-4'    => 'fuschia',
         'color-severity-3'    => 'blue',
         'color-severity-2'    => 'gray',
         'color-severity-1'    => 'scots tartan',
    );
    is( $processor->color_severity_highest(),
        'chartreuse',       'user default color-severity-5' );
    is( $processor->color_severity_high(),
        'fuschia',          'user default color-severity-4' );
    is( $processor->color_severity_medium(),
        'blue',             'user default color-severity-3' );
    is( $processor->color_severity_low(),
        'gray',             'user default color-severity-2' );
    is( $processor->color_severity_lowest(),
        'scots tartan',     'user default color-severity-1' );

    $processor = Perl::Critic::OptionsProcessor->new(
         'colour-severity-5'    => 'chartreuse',
         'colour-severity-4'    => 'fuschia',
         'colour-severity-3'    => 'blue',
         'colour-severity-2'    => 'gray',
         'colour-severity-1'    => 'scots tartan',
    );
    is( $processor->color_severity_highest(),
        'chartreuse',       'user default colour-severity-5' );
    is( $processor->color_severity_high(),
        'fuschia',          'user default colour-severity-4' );
    is( $processor->color_severity_medium(),
        'blue',             'user default colour-severity-3' );
    is( $processor->color_severity_low(),
        'gray',             'user default colour-severity-2' );
    is( $processor->color_severity_lowest(),
        'scots tartan',     'user default colour-severity-1' );
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

# ensure we return true if this test is loaded by
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
