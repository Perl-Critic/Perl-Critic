#!perl

# Extra self-compliance tests for Policy classes.  This just checks for
# additional POD sections that we want in every Policy module.  See the
# 41_perlcriticrc-policies file for the precise configuration.

use strict;
use warnings;

use File::Spec qw<>;

use Perl::Critic::PolicyFactory ( '-test' => 1 );

use Test::More;

our $VERSION = '1.150';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

#-----------------------------------------------------------------------------

eval 'use Test::Perl::Critic; 1;'
    or plan skip_all => 'Test::Perl::Critic required to test Perl::Critic itself';

#-----------------------------------------------------------------------------

# Set up PPI caching for speed (used primarily during development)

if ( $ENV{PERL_CRITIC_CACHE} ) {
    require PPI::Cache;
    my $cache_path =
        File::Spec->catdir(
            File::Spec->tmpdir(),
            "test-perl-critic-cache-$ENV{USER}"
        );
    if ( ! -d $cache_path) {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import( path => $cache_path );
}

#-----------------------------------------------------------------------------
# Run critic against all of our own files

my $rcfile = File::Spec->catfile( qw< xt 41_perlcriticrc-policies > );
Test::Perl::Critic->import( -profile => $rcfile );

my $path =
    File::Spec->catfile(
        -e 'blib' ? 'blib/lib' : 'lib',
        qw< Perl Critic Policy >,
    );
all_critic_ok( $path );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
