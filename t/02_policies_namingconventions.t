##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 6;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
my $fooBAR;
my ($fooBAR) = 'nuts';
local $FooBar;
our ($FooBAR);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foobar, $fooBAR);
my (%foobar, @fooBAR, $foo);
local ($foobar, $fooBAR);
local (%foobar, @fooBAR, $foo);
our ($foobar, $fooBAR);
our (%foobar, @fooBAR, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo_BAR;
my $FOO_BAR;
my $foo_bar;
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foo_BAR, $BAR_FOO);
my ($foo_BAR, $BAR_FOO) = q(this, that);
our (%FOO_BAR, @BAR_FOO);
local ($FOO_BAR, %BAR_foo) = @_;
my ($foo_bar, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub fooBAR {}
sub FooBar {}
sub Foo_Bar {}
sub FOObar {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo_BAR {}
sub foo_bar {}
sub FOO_bar {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 0, $policy);
