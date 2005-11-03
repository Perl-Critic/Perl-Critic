use blib;
use strict;
use warnings;
use Test::More tests => 18;
use List::MoreUtils qw(all none);
use Perl::Critic;

my $c = undef;
my $samples_dir      = "t/samples";
my $config_none      = "$samples_dir/perlcriticrc.none";
my $config_all       = "$samples_dir/perlcriticrc.all";
my $config_levels    = "$samples_dir/perlcriticrc.levels";
my @default_policies = Perl::Critic::Config::default_policies();
my $total_policies   = scalar @default_policies;

#--------------------------------------------------------------
# Test all-off config
$c = Perl::Critic->new( -profile => $config_none);
is(scalar @{$c->policies}, 0);

#--------------------------------------------------------------
# Test all-off config w/ priorities
$c = Perl::Critic->new( -profile => $config_none, -priority => 2);
is(scalar @{$c->policies}, 0);

#--------------------------------------------------------------
# Test all-on config
$c = Perl::Critic->new( -profile => $config_all);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
# Test all-on config w/ priorities
$c = Perl::Critic->new( -profile => $config_all, -priority => 2);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
# Test config w/ multiple priority levels
$c = Perl::Critic->new( -profile => $config_levels, -priority => 1);
is(scalar @{$c->policies}, 3);

$c = Perl::Critic->new( -profile => $config_levels, -priority => 2);
is(scalar @{$c->policies}, 4);

$c = Perl::Critic->new( -profile => $config_levels, -priority => 3);
is(scalar @{$c->policies}, 6);

$c = Perl::Critic->new( -profile => $config_levels, -priority => 4);
is(scalar @{$c->policies}, 7);

$c = Perl::Critic->new( -profile => $config_levels, -priority => 5);
is(scalar @{$c->policies}, 11);

$c = Perl::Critic->new( -profile => $config_levels, -priority => 99);
is(scalar @{$c->policies}, $total_policies);

#--------------------------------------------------------------
# Test config as hash
my %config_hash = (
  '-NamingConventions::ProhibitMixedCaseVars' => {},
  '-NamingConventions::ProhibitMixedCaseSubs' => {},
  'Miscellanea::RequireRcsKeywords' => {keywords => 'Revision'},
);

$c = Perl::Critic->new( -profile => \%config_hash );
is(scalar @{$c->policies}, $total_policies - 1);

#--------------------------------------------------------------
# Test config as hash
my @config_array = (
  q{ [-NamingConventions::ProhibitMixedCaseVars] },
  q{ [-NamingConventions::ProhibitMixedCaseSubs] },
  q{ [Miscellanea::RequireRcsKeywords]           },
  q{ keywords = Revision                         },
);

$c = Perl::Critic->new( -profile => \@config_array );
is(scalar @{$c->policies}, $total_policies - 1);

#--------------------------------------------------------------
# Test config as string
my $config_string = <<'END_CONFIG';

[-NamingConventions::ProhibitMixedCaseVars]
[-NamingConventions::ProhibitMixedCaseSubs]
[Miscellanea::RequireRcsKeywords]
keywords = Revision

END_CONFIG

$c = Perl::Critic->new( -profile => \$config_string );
is(scalar @{$c->policies}, $total_policies - 1);

#--------------------------------------------------------------
# Test default config.  If the user already has an existing
# perlcriticrc file, it will get in the way of this test.
# This little tweak to Perl::Critic::Config ensures that we
# don't find the perlcriticrc file.

{
    no warnings 'redefine';
    *Perl::Critic::Config::find_profile_path = sub { return };
}

$c = Perl::Critic->new();
is(scalar @{$c->policies}, $total_policies);

$c = Perl::Critic->new( -priority => 2);
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











