#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use Test::More (tests => 18);
use English qw(-no_match_vars);
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::TestUtils;

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

my $pkg = 'Perl::Critic::Statistics';
use_ok( $pkg );

my @methods = qw(
    average_sub_mccabe
    lines_of_code
    modules
    new
    policy_violations
    severity_violations
    statements
    subs
    total_violations
    violations_per_line_of_code
);

for my $method ( @methods ) {
    can_ok( $pkg, $method );
}

#-----------------------------------------------------------------------------

my $code = <<'END_PERL';
package Foo;

use My::Module;
$this = $that if $condition;
sub foo { return @list if $condition };
END_PERL

#-----------------------------------------------------------------------------

my $critic = Perl::Critic->new( -severity => 1 );
my $stats  = Perl::Critic::Statistics->new( $critic );
$stats->critique( \$code );

my %expected_stats = (
    average_sub_mccabe            => 2,
    lines_of_code                 => 5,
    modules                       => 1,
    statements                    => 6,
    subs                          => 1,
    total_violations              => 10,
    violations_per_line_of_code   => 2,
);

while ( my($method, $expected) = each %expected_stats) {
    is( $stats->$method, $expected, "Statistics: $method");
}

#-----------------------------------------------------------------------------

