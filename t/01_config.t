#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 28;
use List::MoreUtils qw(all any);
use English qw(-no_match_vars);
use Perl::Critic::Utils;
use Perl::Critic::Config (-test => 1);
use Perl::Critic;

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

my $samples_dir       = 't/samples';
my $critic = Perl::Critic->new(-severity => $SEVERITY_LOWEST);
my @native_policies   = Perl::Critic::Config::native_policies();
my @all_policies      = map {ref $_} $critic->policies();

# Note that the user may have third-party policies installed, so the
# reported number of policies may be higher than native_policies()
my $have_third_party_policies = @all_policies > @native_policies;
my $total_policies    = scalar $have_third_party_policies ?
                               @all_policies : @native_policies;

my $last_policy_count = 0;
my $profile           = undef;

#--------------------------------------------------------------
# Test default config.  Increasing the severity should yield
# fewer and fewer policies.  The exact number will fluctuate
# as we introduce new polices and/or change their severity.

$last_policy_count = $total_policies + 1;
for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
    my $c = Perl::Critic->new( -severity => $severity);
    my $policy_count = scalar $c->policies();
    my $test_name = "Count native policies, severity: $severity";
    cmp_ok($policy_count, '<', $last_policy_count, $test_name);
    $last_policy_count = $policy_count;
}


#--------------------------------------------------------------
# Same tests as above, but using a config file

$profile = "$samples_dir/perlcriticrc.all";
$last_policy_count = $total_policies + 1;
for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
    my $c = Perl::Critic->new( -profile => $profile, -severity => $severity);
    my $policy_count = scalar $c->policies();
    my $test_name = "Count all policies, severity: $severity";
    cmp_ok($policy_count, '<', $last_policy_count, $test_name);
    $last_policy_count = $policy_count;
}

#--------------------------------------------------------------
# Test all-off config w/ various severity levels.  In this case, the
# severity level should not affect the number of polices because we've
# turned them all off in the config file.

SKIP:
{
    $profile = "$samples_dir/perlcriticrc.none";
    for my $severity (undef, $SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $c = Perl::Critic->new( -profile => $profile, -severity => $severity);
        is_deeply( [$c->policies], [], 'no policies, severity '.($severity||'undef'));
    }
}

#--------------------------------------------------------------
# Test config w/ multiple severity levels.  In this config, we've
# defined an arbitrary severity for each Policy so that severity
# levels 5 through 2 each have 10 Policies.  All remaining Policies
# are in the 1st severity level.


{
    my $last_policy_count = 0;
    my $profile = "$samples_dir/perlcriticrc.levels";

    for my $severity ( reverse $SEVERITY_LOWEST+1 .. $SEVERITY_HIGHEST ) {
        my $c = Perl::Critic->new( -profile => $profile, -severity => $severity);
        my $policy_count = scalar $c->policies();
        is( $policy_count, ($SEVERITY_HIGHEST - $severity + 1) * 10, 'severity levels' );
    }

    my $c = Perl::Critic->new( -profile => $profile, -severity => $SEVERITY_LOWEST);
    my $policy_count = scalar $c->policies();
    cmp_ok( $policy_count, '>=', ($SEVERITY_HIGHEST * 10), 'count highest severity');
}

#--------------------------------------------------------------
#Test pattern matching

my (@in, @ex) = ();
my @pols      = ();
my $pc        = undef;
my $matches   = 0;

# In this test, we'll use a cusotm profile to deactivate some
# policies, and then use the -include option to re-activate them.  So
# the net result is that we should still end up with the all the
# policies.

my %profile = (
  '-NamingConventions::ProhibitMixedCaseVars' => {},
  '-NamingConventions::ProhibitMixedCaseSubs' => {},
  '-Miscellanea::RequireRcsKeywords' => {},
);

@in = qw(mixedcase RCS);
my %pc_config = (-severity => 1, -profile => \%profile, -include => \@in);
@pols = Perl::Critic->new( %pc_config )->policies();
is(scalar @pols, $total_policies, 'pattern matching');

#--------------------------------------------------------------

# For this test, we'll load the default config, but deactivate some of
# the policies using the -exclude option.  Then we make sure that none
# of the remaining policies match the -exclude patterns.

@ex = qw(quote mixed VALUES); #Some assorted pattterns
@pols = Perl::Critic->new( -severity => 1, -exclude => \@ex )->policies();
$matches = grep { my $pol = ref $_; grep { $pol !~ /$_/imx} @ex } @pols;
is(scalar @pols, $matches, 'pattern matching');

# In this test, we set -include and -exclude patterns to both match
# some of the same policies.  The -exclude option should have
# precendece.

@in = qw(builtinfunc); #Include BuiltinFunctions::*
@ex = qw(block);   #Exclude RequireBlockGrep, RequireBlockMap
@pols = Perl::Critic->new( -severity => 1, -include => \@in, -exclude => \@ex )->policies();
my @pol_names = map {ref $_} @pols;
is_deeply( [grep {/block/imx} @pol_names], [], 'pattern match' );
# This odd construct arises because "any" can't be used with parens without syntax error(!)
ok( @{[any {/builtinfunc/imx} @pol_names]}, 'pattern match' );

#--------------------------------------------------------------
# Test exception handling

{
    #Trap warnings here.
    my $caught_warning = q{};
    local $SIG{__WARN__} = sub { $caught_warning = shift };
    my $config = Perl::Critic::Config->new();

    # Try loading a bogus policy
    my $returned = $config->add_policy( -policy => 'Bogus::Policy');
    ok( !defined $returned );
    ok( $caught_warning );
    $caught_warning = q{}; #Reset

    # Try loading from bogus namespace
    Perl::Critic::Config->import( -namespace => 'Bogus::Namespace' );
    ok( $caught_warning );
    $caught_warning = q{}; #Reset
}

