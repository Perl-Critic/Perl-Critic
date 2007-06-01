#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use Test::More (tests => 19);
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
    statements
    subs
    total_violations
    violations_by_policy
    violations_by_severity
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
sub foo { return @list unless $condition };
END_PERL

#-----------------------------------------------------------------------------

my $critic = Perl::Critic->new( -severity => 1 );
my @violations = $critic->critique( \$code );

#print @violations;
#exit;

my %expected_stats = (
    average_sub_mccabe            => 2,
    lines_of_code                 => 5,
    modules                       => 1,
    statements                    => 6,
    subs                          => 1,
    total_violations              => 10,
    violations_per_line_of_code   => 2,
);

my $stats = $critic->statistics();
isa_ok($stats, $pkg);

while ( my($method, $expected) = each %expected_stats) {
    is( $stats->$method, $expected, "Statistics: $method");
}

#-----------------------------------------------------------------------------

