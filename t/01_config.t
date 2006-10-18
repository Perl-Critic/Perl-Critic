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
use English qw(-no_match_vars);
use List::MoreUtils qw(all any);
use Perl::Critic::Config qw();
use Perl::Critic::Utils;
use Test::More (tests => 38);

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

my $samples_dir      = 't/samples';
my $config           = Perl::Critic::Config->new(-severity => $SEVERITY_LOWEST);
my @native_policies  = Perl::Critic::Config::native_policy_names();
my @site_policies    = Perl::Critic::Config::site_policy_names();
my $total_policies   = scalar @site_policies;

#-----------------------------------------------------------------------------
# Test default config.  Increasing the severity should yield
# fewer and fewer policies.  The exact number will fluctuate
# as we introduce new polices and/or change their severity.

{
    my $last_policy_count = $total_policies + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $c = Perl::Critic::Config->new( -severity => $severity);
        my $policy_count = scalar $c->policies();
        my $test_name = "Count native policies, severity: $severity";
        cmp_ok($policy_count, '<', $last_policy_count, $test_name);
        $last_policy_count = $policy_count;
    }
}


#-----------------------------------------------------------------------------
# Same tests as above, but using a config file

{
    my $profile = "$samples_dir/perlcriticrc.all";
    my $last_policy_count = $total_policies + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $c = Perl::Critic::Config->new( -profile => $profile, -severity => $severity);
        my $policy_count = scalar $c->policies();
        my $test_name = "Count all policies, severity: $severity";
        cmp_ok($policy_count, '<', $last_policy_count, $test_name);
        $last_policy_count = $policy_count;
    }
}

#-----------------------------------------------------------------------------
# Test all-off config w/ various severity levels.  In this case, the
# severity level should not affect the number of polices because we've
# turned them all off in the config file.

{
    my $profile = "$samples_dir/perlcriticrc.none";
    for my $severity (undef, $SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $c = Perl::Critic::Config->new( -profile => $profile, -severity => $severity);
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
        my $c = Perl::Critic::Config->new( -profile => $profile, -severity => $severity);
        my $policy_count = scalar $c->policies();
        is( $policy_count, ($SEVERITY_HIGHEST - $severity + 1) * 10, 'severity levels' );
    }

    my $c = Perl::Critic::Config->new( -profile => $profile, -severity => $SEVERITY_LOWEST);
    my $policy_count = scalar $c->policies();
    cmp_ok( $policy_count, '>=', ($SEVERITY_HIGHEST * 10), 'count highest severity');
}

#-----------------------------------------------------------------------------
# Test config with defaults

{
    my $profile = "$samples_dir/perlcriticrc.defaults";
    my $c = Perl::Critic::Config->new( -profile => $profile );
    is_deeply([$c->exclude()], [ qw(Documentation Naming) ], 'user default exclude from file' );
    is_deeply([$c->include()], [ qw(CodeLayout Modules) ],  'user default include from file' );
    is($c->force(),    1,  'user default force from file'     );
    is($c->color(),    0,  'user default color from file'   );
    is($c->only(),     1,  'user default only from file'      );
    is($c->severity(), 3,  'user default severity from file'  );
    is($c->theme(),    'danger + risky - pbp',  'user default theme from file');
    is($c->top(),      50, 'user default top from file'       );
    is($c->verbose(),  5,  'user default verbose from file'   );
}

#-----------------------------------------------------------------------------
#Test pattern matching


{
    # In this test, we'll use a cusotm profile to deactivate some
    # policies, and then use the -include option to re-activate them.  So
    # the net result is that we should still end up with the all the
    # policies.

    my %profile = (
        '-NamingConventions::ProhibitMixedCaseVars' => {},
        '-NamingConventions::ProhibitMixedCaseSubs' => {},
        '-Miscellanea::RequireRcsKeywords' => {},
    );

    my @in = qw(mixedcase RCS);
    my %pc_config = (-severity => 1, -profile => \%profile, -include => \@in);
    my @pols = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @pols, $total_policies, 'pattern matching');
}

#-----------------------------------------------------------------------------

{
    # For this test, we'll load the default config, but deactivate some of
    # the policies using the -exclude option.  Then we make sure that none
    # of the remaining policies match the -exclude patterns.

    my @ex = qw(quote mixed VALUES); #Some assorted pattterns
    my @pols = Perl::Critic::Config->new( -severity => 1, -exclude => \@ex )->policies();
    my $matches = grep { my $pol = ref $_; grep { $pol !~ /$_/imx} @ex } @pols;
    is(scalar @pols, $matches, 'pattern matching');
}

#-----------------------------------------------------------------------------

{
    # In this test, we set -include and -exclude patterns to both match
    # some of the same policies.  The -exclude option should have
    # precendece.

    my @in = qw(builtinfunc); #Include BuiltinFunctions::*
    my @ex = qw(block);       #Exclude RequireBlockGrep, RequireBlockMap
    my %pc_config = ( -severity => 1, -include => \@in, -exclude => \@ex );
    my @pols = Perl::Critic::Config->new( %pc_config )->policies();
    my @pol_names = map {ref $_} @pols;
    is_deeply( [grep {/block/imx} @pol_names], [], 'pattern match' );
    # This odd construct arises because "any" can't be used with parens without syntax error(!)
    ok( @{[any {/builtinfunc/imx} @pol_names]}, 'pattern match' );
}

#-----------------------------------------------------------------------------
# Test the -only switch

{

    my %profile = (
        '-NamingConventions::ProhibitMixedCaseVars' => {},
        'NamingConventions::ProhibitMixedCaseSubs' => {},
        'Miscellanea::RequireRcsKeywords' => {},
    );

    my %pc_config = (-severity => 1, -only => 1, -profile => \%profile);
    my @pols = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @pols, 2, '-only switch');

    %pc_config = ( -severity => 1, -only => 1, -profile => {} );
    @pols = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @pols, 0, '-only switch, empty profile');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    # Try adding a bogus policy
    eval{ $config->add_policy( -policy => 'Bogus::Policy') };
    like( $EVAL_ERROR, qr/Unable to create policy/, 'add_policy w/ bad args' );

    # Try adding w/o policy
    eval { $config->add_policy() };
    like( $EVAL_ERROR, qr/The -policy argument is required/, 'add_policy w/o args' );
}

