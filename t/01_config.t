#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 51;
use List::MoreUtils qw(all any none);
use English qw(-no_match_vars);
use Perl::Critic::Utils;
use Perl::Critic::Config (-test => 1);
use Perl::Critic;

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

my $critic = undef;
my $samples_dir       = 't/samples';
my @native_policies   = Perl::Critic::Config::native_policies();
my @all_policies      = map {ref $_} Perl::Critic->new(-severity => $SEVERITY_LOWEST)->policies();

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
    my $critic = Perl::Critic->new( -severity => $severity);
    my $policy_count = scalar $critic->policies();
    my $test_name = "Count native policies, severity: $severity";
    cmp_ok($policy_count, '<', $last_policy_count, $test_name);
    $last_policy_count = $policy_count;
}


#--------------------------------------------------------------
# Same tests as above, but using a config file

$profile = "$samples_dir/perlcriticrc.all";
$last_policy_count = $total_policies + 1;
for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
    my $critic = Perl::Critic->new( -profile => $profile, -severity => $severity);
    my $policy_count = scalar $critic->policies();
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

$last_policy_count = 0;
$profile = "$samples_dir/perlcriticrc.levels";
SKIP:
{
    #skip('Third-party policies break these tests', 4) if ($have_third_party_policies);
    for my $severity ( reverse $SEVERITY_LOWEST+1 .. $SEVERITY_HIGHEST ) {
        my $critic = Perl::Critic->new( -profile => $profile, -severity => $severity);
        my $policy_count = scalar $critic->policies();
        is( $policy_count, ($SEVERITY_HIGHEST - $severity + 1) * 10, 'severity levels' );
    }
}

#-------

SKIP:
{
    #skip('Third-party policies break these tests', 1) if ($have_third_party_policies);
    my $critic = Perl::Critic->new( -profile => $profile, -severity => $SEVERITY_LOWEST);
    my $policy_count = scalar $critic->policies();
    cmp_ok( $policy_count, '>=', ($SEVERITY_HIGHEST * 10), 'count highest severity');
}

#--------------------------------------------------------------
# Test config as hash

my %config_hash = (
  '-NamingConventions::ProhibitMixedCaseVars' => {},
  '-NamingConventions::ProhibitMixedCaseSubs' => {},
  'Miscellanea::RequireRcsKeywords' => {keywords => 'Revision'},
);

$critic = Perl::Critic->new( -profile => \%config_hash, -severity => $SEVERITY_LOWEST );
is(scalar $critic->policies(), $total_policies - 2, 'config as hash');

#--------------------------------------------------------------
# Test config as array

my @config_array = (
  q{ [-NamingConventions::ProhibitMixedCaseVars] },
  q{ [-NamingConventions::ProhibitMixedCaseSubs] },
  q{ [Miscellanea::RequireRcsKeywords]           },
  q{ keywords = Revision                         },
);

$critic = Perl::Critic->new( -profile => \@config_array, -severity => $SEVERITY_LOWEST );
is(scalar $critic->policies(), $total_policies - 2, 'config as array');

#--------------------------------------------------------------
# Test config as string

my $config_string = <<'END_CONFIG';
[-NamingConventions::ProhibitMixedCaseVars]
[-NamingConventions::ProhibitMixedCaseSubs]
[Miscellanea::RequireRcsKeywords]
keywords = Revision
END_CONFIG

$critic = Perl::Critic->new( -profile => \$config_string, -severity => $SEVERITY_LOWEST );
is(scalar $critic->policies(), $total_policies - 2, 'config as string');

#--------------------------------------------------------------
# Test long policy names

my $long_config_string = <<'END_CONFIG';
[-Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars]
[-Perl::Critic::Policy::References::ProhibitDoubleSigils]
[Perl::Critic::Policy::Miscellanea::RequireRcsKeywords]
keywords = Revision
[-Perl::Critic::Policy::Modules::RequireEndWithOne]
END_CONFIG

$critic = Perl::Critic->new( -profile => \$long_config_string, -severity => $SEVERITY_LOWEST );
is(scalar $critic->policies(), $total_policies - 3, 'long policy names');

#--------------------------------------------------------------
# Test manual configuraion

my $config = Perl::Critic::Config->new( -profile => \$config_string, -severity => $SEVERITY_LOWEST);
$critic = Perl::Critic->new( -config => $config );
is(scalar $critic->policies(), $total_policies - 2, 'manual config');

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

# For this test, we'll load the default config, but screen out the
# policies that don't match the requested theme.  Then we make sure
# that all remaining polices have the right theme.

{
    my @themes = qw(cosmetic);
    @pols = Perl::Critic->new( -severity => 1, -themes => \@themes )->policies();
    my $ok = all { _intersection( [$_->get_themes()], \@themes) }  @pols;
    ok($ok, 'themes matching');
}

# This test just verifies the behavior when the theme list is empty.
# I'm not sure what the right behavior should be, but this test lets
# us know when it has changed.

{
    @pols = Perl::Critic->new( -severity => 1, -themes => [] )->policies();
    is(scalar @pols, $total_policies, 'empty theme list, so all policies loaded' );
}

# This test just verifies the behavior when the theme list doesn't
# match any known themes.  I'm not sure what the right behavior should
# be, but this test lets us know when it has changed.

{
    @pols = Perl::Critic->new( -severity => 1, -themes => ['bogus'] )->policies();
    is_deeply( \@pols, [], 'bogus theme list, so no policies loaded' );
}


#--------------------------------------------------------------
#Testing other private subs

{
    my $s = undef;
    $s = Perl::Critic::Config::_normalize_severity( 0 );
    is($s, $SEVERITY_LOWEST, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( 10 );
    is($s, $SEVERITY_HIGHEST, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( -1 );
    is($s, 1, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( -10 );
    is($s, $SEVERITY_HIGHEST, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( 1 );
    is($s, 1, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( 5 );
    is($s, 5, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( 2.4 );
    is($s, 2, "Normalizing severity");

    $s = Perl::Critic::Config::_normalize_severity( -3.8 );
    is($s, 3, "Normalizing severity");
}

#--------------------------------------------------------------

{
    my $namespace = 'Perl::Critic::Policy';
    my $valid_policy = 'Variables::ProhibitLocalVars';
    ok( Perl::Critic::Config::_is_valid_policy( $valid_policy,    $namespace ) );
    ok( Perl::Critic::Config::_is_valid_policy( "-$valid_policy", $namespace ) );

    my $invalid_policy = 'Foo::Bar';
    ok( ! Perl::Critic::Config::_is_valid_policy( $invalid_policy,    $namespace ) );
    ok( ! Perl::Critic::Config::_is_valid_policy( "-$invalid_policy", $namespace ) );
}

#--------------------------------------------------------------

{
    my $namespace = 'Foo::Bar';
    my $module_name = 'Baz::Nuts';
    my $long_name = "${namespace}::$module_name";
    is( Perl::Critic::Config::_policy_long_name(  $module_name,  $namespace), $long_name   );
    is( Perl::Critic::Config::_policy_long_name(  $long_name,    $namespace), $long_name   );
    is( Perl::Critic::Config::_policy_short_name( $module_name,  $namespace), $module_name );
    is( Perl::Critic::Config::_policy_short_name( $long_name,    $namespace), $module_name );
}

#--------------------------------------------------------------

{
    #Trap death
    eval { $config->add_policy( -policy => 'Bogus::Policy') };
    ok( $EVAL_ERROR, 'Bogus policy is fatal' );
}

#--------------------------------------------------------------

{
    #Trap warning here.
    my $caught_warning = q{};
    local $SIG{__WARN__} = sub { $caught_warning = shift };

    Perl::Critic::Config->import( -namespace => 'Bogus::Namespace' );
    ok( $caught_warning );
}


sub _intersection {
    my ($arrayref_1, $arrayref_2) = @_;
    my %hashed = (); #Need a better name for this variable.
    @hashed{ @{$arrayref_1} } = @{$arrayref_1}; #e.g. (foo) ---> (foo => foo);
    return @hashed{ @{$arrayref_2} };
}
