##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 18;
use List::MoreUtils qw(all none);
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw();

my $c = undef;
my $samples_dir      = "t/samples";
my $config_none      = "$samples_dir/perlcriticrc.none";
my $config_all       = "$samples_dir/perlcriticrc.all";
my $config_levels    = "$samples_dir/perlcriticrc.levels";
my @all_policies     = Perl::Critic::Config::native_policies();
my $total_policies   = scalar @all_policies;

#--------------------------------------------------------------
# Test all-on config
$c = Perl::Critic->new( -profile => $config_all);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
# Test all-on config w/ severity
$c = Perl::Critic->new( -profile => $config_all);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
# Test all-off config
$c = Perl::Critic->new( -profile => $config_none);
is(scalar @{$c->policies}, 0);

#--------------------------------------------------------------
# Test all-off config w/ severity
$c = Perl::Critic->new( -profile => $config_none, -severity => 2);
is(scalar @{$c->policies}, 0);

#--------------------------------------------------------------
# Test config w/ multiple severity levels
$c = Perl::Critic->new( -profile => $config_levels, -severity => 1);
is(scalar @{$c->policies}, $total_policies);

$c = Perl::Critic->new( -profile => $config_levels, -severity => 2);
is(scalar @{$c->policies}, 40);

$c = Perl::Critic->new( -profile => $config_levels, -severity => 3);
is(scalar @{$c->policies}, 30);

$c = Perl::Critic->new( -profile => $config_levels, -severity => 4);
is(scalar @{$c->policies}, 20);

$c = Perl::Critic->new( -profile => $config_levels, -sverity => 5);
is(scalar @{$c->policies}, 10);

#--------------------------------------------------------------
# Test config as hash
my %config_hash = (
  '-NamingConventions::ProhibitMixedCaseVars' => {},
  '-NamingConventions::ProhibitMixedCaseSubs' => {},
  'Miscellanea::RequireRcsKeywords' => {keywords => 'Revision'},
);

$c = Perl::Critic->new( -profile => \%config_hash );
is(scalar @{$c->policies}, $total_policies - 2);

#--------------------------------------------------------------
# Test config as hash
my @config_array = (
  q{ [-NamingConventions::ProhibitMixedCaseVars] },
  q{ [-NamingConventions::ProhibitMixedCaseSubs] },
  q{ [Miscellanea::RequireRcsKeywords]           },
  q{ keywords = Revision                         },
);

$c = Perl::Critic->new( -profile => \@config_array );
is(scalar @{$c->policies}, $total_policies - 2);

#--------------------------------------------------------------
# Test config as string
my $config_string = <<'END_CONFIG';

[-NamingConventions::ProhibitMixedCaseVars]
[-NamingConventions::ProhibitMixedCaseSubs]
[Miscellanea::RequireRcsKeywords]
keywords = Revision

END_CONFIG

$c = Perl::Critic->new( -profile => \$config_string );
is(scalar @{$c->policies}, $total_policies - 2);

#--------------------------------------------------------------
# Test default config.  If the user already has an existing
# perlcriticrc file, it will get in the way of this test.
# This little tweak to Perl::Critic::Config ensures that we
# don't find the perlcriticrc file.

PerlCriticTestUtils::block_perlcriticrc();


$c = Perl::Critic->new();
is(scalar @{$c->policies}, $total_policies);

$c = Perl::Critic->new( -severity => 1);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
#Test pattern matching

my (@in, @ex) = ();
my $pols      = [];
my $matches   = 0;

@in = qw(modules vars Regular); #Some assorted pattterns
$pols = Perl::Critic->new( -include => \@in )->policies();
$matches = grep { my $pol = ref $_; grep { $pol =~ /$_/imx} @in } @{ $pols };
is(scalar @{$pols}, $matches);

@ex = qw(quote mixed VALUES); #Some assorted pattterns
$pols = Perl::Critic->new( -exclude => \@ex )->policies();
$matches = grep { my $pol = ref $_; grep { $pol !~ /$_/imx} @ex } @{ $pols };
is(scalar @{$pols}, $matches);

@in = qw(builtin); #Include BuiltinFunctions::*
@ex = qw(block);   #Exclude RequireBlockGrep, RequireBlockMap
$pols = Perl::Critic->new( -include => \@in, -exclude => \@ex )->policies();
ok( none {ref $_ =~ /block/imx} @{$pols} && all {ref $_ =~ /builtin/imx} @{$pols} );











