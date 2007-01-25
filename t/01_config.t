#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use File::Spec;
use English qw(-no_match_vars);
use List::MoreUtils qw(all any);
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Config qw();
use Perl::Critic::Utils;
use Test::More (tests => 67);

# common P::C testing tools
use Perl::Critic::TestUtils qw(bundled_policy_names);
Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

my $config       = Perl::Critic::Config->new( -severity => $SEVERITY_LOWEST );
my @native_policies  = bundled_policy_names();
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
# Same tests as above, but using a generated config

{
    my %profile = map { $_ => {} } @native_policies;
    my $last_policy_count = $total_policies + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my %pc_args = (-profile => \%profile, -severity => $severity);
        my $critic = Perl::Critic::Config->new( %pc_args );
        my $policy_count = scalar $critic->policies();
        my $test_name = "Count all policies, severity: $severity";
        cmp_ok($policy_count, '<', $last_policy_count, $test_name);
        $last_policy_count = $policy_count;
    }
}

#-----------------------------------------------------------------------------
# Test all-off config w/ various severity levels.  In this case, the
# severity level should not affect the number of polices because we've
# turned them all off in the profile.

{
    my %profile = map { '-' . $_ => {} } @native_policies;
    for my $severity (undef, $SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my %pc_args = (-profile => \%profile, -severity => $severity);
        my @policies = Perl::Critic::Config->new( %pc_args )->policies();
        my $test_name = 'no policies, severity ' . ($severity || 'undef');
        is_deeply( \@policies, [], $test_name);
    }
}

#-----------------------------------------------------------------------------
# Test config w/ multiple severity levels.  In this profile, we
# define an arbitrary severity for each Policy so that severity
# levels 5 through 2 each have 10 Policies.  All remaining Policies
# are in the 1st severity level.


{
    my %profile = ();
    my $last_policy_count = 0;
    my $severity = $SEVERITY_HIGHEST;
    for my $index ( 0 .. $#native_policies ){
        $severity-- if $index && $index % 10 == 0;
        $severity = $SEVERITY_LOWEST if $severity < $SEVERITY_LOWEST;
        $profile{$native_policies[$index]} = {severity => $severity};
    }

    for my $severity ( reverse $SEVERITY_LOWEST+1 .. $SEVERITY_HIGHEST ) {
        my %pc_args = (-profile => \%profile, -severity => $severity);
        my $critic = Perl::Critic::Config->new( %pc_args );
        my $policy_count = scalar $critic->policies();
        my $expected_count = ($SEVERITY_HIGHEST - $severity + 1) * 10;
        my $test_name = "user-defined severity level: $severity";
        is( $policy_count, $expected_count, $test_name );
    }

    # All remaining policies should be at the lowest severity
    my %pc_args = (-profile => \%profile, -severity => $SEVERITY_LOWEST);
    my $critic = Perl::Critic::Config->new( %pc_args );
    my $policy_count = scalar $critic->policies();
    my $expected_count = $SEVERITY_HIGHEST * 10;
    my $test_name = "user-defined severity, all remaining policies";
    cmp_ok( $policy_count, '>=', $expected_count, $test_name);
}

#-----------------------------------------------------------------------------
# Test config with defaults

{
    my $examples_dir = 'examples';
    my $profile = File::Spec->catfile( $examples_dir, 'perlcriticrc' );
    my $c = Perl::Critic::Config->new( -profile => $profile );

    is_deeply([$c->exclude()], [ qw(Documentation Naming) ],
              'user default exclude from file' );

    is_deeply([$c->include()], [ qw(CodeLayout Modules) ],
              'user default include from file' );

    is($c->force(),    1,  'user default force from file'     );
    is($c->only(),     1,  'user default only from file'      );
    is($c->severity(), 3,  'user default severity from file'  );
    is($c->theme()->rule(),    'danger || risky && ! pbp',  'user default theme from file');
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
# Test the switch behavior

{
    my @switches = qw(-top -verbose -theme -severity -only -force);
    my %undef_args = map { $_ => undef } @switches;
    my $c = Perl::Critic::Config->new( %undef_args );
    is( $c->force(),     0,     'Undefined -force');
    is( $c->only(),      0,     'Undefined -only');
    is( $c->severity(),  5,     'Undefined -severity');
    is( $c->theme()->rule(),   q{},   'Undefined -theme');
    is( $c->top(),       0,     'Undefined -top');
    is( $c->verbose(),   4,     'Undefined -verbose');

    my %zero_args = map { $_ => 0 } @switches;
    $c = Perl::Critic::Config->new( %zero_args );
    is( $c->force(),     0,       'zero -force');
    is( $c->only(),      0,       'zero -only');
    is( $c->severity(),  1,       'zero -severity');
    is( $c->theme()->rule(),     q{},     'zero -theme');
    is( $c->top(),       0,       'zero -top');
    is( $c->verbose(),   4,       'zero -verbose');

    my %empty_args = map { $_ => q{} } @switches;
    $c = Perl::Critic::Config->new( %empty_args );
    is( $c->force(),     0,       'empty -force');
    is( $c->only(),      0,       'empty -only');
    is( $c->severity(),  1,       'empty -severity');
    is( $c->theme->rule(),     q{},     'empty -theme');
    is( $c->top(),       0,       'empty -top');
    is( $c->verbose(),   4,       'empty -verbose');
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
# Test the -singlepolicy switch

{
    my %pc_config = (-singlepolicy => 'ProhibitEvilModules');
    my @pols = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @pols, 1, '-singlepolicy switch');
}

#-----------------------------------------------------------------------------
# Test interaction between switches and defaults

{
    my %true_defaults = ( force => 1, only  => 1, top => 10 );
    my %profile  = ( '_' => \%true_defaults );

    my %pc_config = (-force => 0, -only => 0, -top => 0, -profile => \%profile);
    my $config = Perl::Critic::Config->new( %pc_config );
    is( $config->force, 0, '-force: default is true, arg is false');
    is( $config->only,  0, '-only: default is true, arg is false');
    is( $config->top,   0, '-top: default is true, arg is false');
}

#-----------------------------------------------------------------------------
# Test named severity levels

{
    my %severity_levels = (gentle=>5, stern=>4, harsh=>3, cruel=>2, brutal=>1);
    while (my ($name, $number) = each %severity_levels) {
        my $config = Perl::Critic::Config->new( -severity => $name );
        is( $config->severity(), $number, qq{Severity "$name" is "$number"});
    }
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

    # Try using bogus named severity level
    eval{ Perl::Critic::Config->new( -severity => 'bogus' ) };
    like( $EVAL_ERROR, qr/Invalid severity: "bogus"/, 'invalid severity' );

    # Try using vague -singlepolicy option
    eval{ Perl::Critic::Config->new( -singlepolicy => '.*' ) };
    like( $EVAL_ERROR, qr/Multiple policies matched/, 'vague -singlepolicy' );

    # Try using invalid -singlepolicy option
    eval{ Perl::Critic::Config->new( -singlepolicy => 'bogus' ) };
    like( $EVAL_ERROR, qr/No policies matched/, 'invalid -singlepolicy' );
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
