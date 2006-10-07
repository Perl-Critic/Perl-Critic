#!perl

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

# Self-compliance tests

use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More;
use Perl::Critic::Config ( -test => 1 );

eval { require Test::Perl::Critic; };
plan skip_all => 'Test::Perl::Critic required to criticise code' if $EVAL_ERROR;

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

# Strict object testing -- prevent direct hash key access
eval { require Class::Encapsulate::Runtime; };
if ( !$EVAL_ERROR ) {
    for my $pkg ( '', '::Config', '::Policy', '::Violation' ) {
        diag 'apply Class::Encapsulate to Perl::Critic'.$pkg;
        Class::Encapsulate::Runtime->apply_to('Perl::Critic'.$pkg);
    }
}

# Configure Test::Perl::Critic
my @exclude = qw( CodeLayout::RequireTidyCode );
my %profile = (
    'Documentation::RequirePodSections' => {
        lib_sections    => 'NAME|DESCRIPTION|AUTHOR|COPYRIGHT',
        script_sections => 'NAME|DESCRIPTION|AUTHOR|COPYRIGHT',
    },
    'Miscellanea::RequireRcsKeywords' => {
        keywords => 'URL Date Author Revision',
    },
    'CodeLayout::ProhibitHardTabs' => {
        allow_leading_tabs => 0,
    },
);

Test::Perl::Critic->import( -severity => 1,
                            -exclude => \@exclude,
                            -profile => \%profile );

# Run critic against all of our own files
all_critic_ok();
