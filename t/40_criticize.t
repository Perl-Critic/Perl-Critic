#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

# Self-compliance tests

use strict;
use warnings;

use lib 't/tlib';

use English qw( -no_match_vars );

use File::Spec qw();
use Test::More;

use Perl::Critic::Utils qw{ :characters };
use Perl::Critic::TestUtilitiesWithMinimalDependencies qw{
    should_skip_author_tests
    get_author_test_skip_message
};
use Perl::Critic::TestUtils qw{ starting_points_including_examples };

# Note: "use PolicyFactory" *must* appear after "use TestUtils" for the
# -extra-test-policies option to work.
use Perl::Critic::PolicyFactory (
    '-test' => 1,
    '-extra-test-policies' => [ qw{ ErrorHandling::RequireUseOfExceptions } ],
);

#-----------------------------------------------------------------------------

if (should_skip_author_tests()) {
    plan skip_all => get_author_test_skip_message();
}

#-----------------------------------------------------------------------------

eval { require Test::Perl::Critic; };
plan skip_all => 'Test::Perl::Critic required to criticise code' if $EVAL_ERROR;

#-----------------------------------------------------------------------------

eval { require Perl::Critic::Policy::ErrorHandling::RequireUseOfExceptions; };
plan skip_all =>
    'ErrorHandling::RequireUseOfExceptions policy required to criticise code.'
        . ' This policy is part of the Perl::Critic::More distribution.'
    if $EVAL_ERROR;

#-----------------------------------------------------------------------------
# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require File::Spec;
    require PPI::Cache;
    my $cache_path
        = File::Spec->catdir( File::Spec->tmpdir,
                              'test-perl-critic-cache-'.$ENV{USER} );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Strict object testing -- prevent direct hash key access

eval { require Devel::EnforceEncapsulation; };
if ( !$EVAL_ERROR ) {
    for my $pkg ( $EMPTY, '::Config', '::Policy', '::Violation' ) {
        Devel::EnforceEncapsulation->apply_to('Perl::Critic'.$pkg);
    }
}
else {
    diag($EMPTY);
    diag(
        'You should install Devel::EnforceEncapsulation, but other tests '
            . 'will still run.'
    );
}

#-----------------------------------------------------------------------------
# Run critic against all of our own files

my $rcfile = File::Spec->catfile( 't', '40_perlcriticrc' );
Test::Perl::Critic->import( -profile => $rcfile );

all_critic_ok( starting_points_including_examples() );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
