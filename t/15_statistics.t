#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Statistics;
use Perl::Critic::TestUtils;

use Test::More tests => 24;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

my $package = 'Perl::Critic::Statistics';

my @methods = qw(
    average_sub_mccabe
    lines
    modules
    new
    statements
    subs
    total_violations
    violations_by_policy
    violations_by_severity
    statements_other_than_subs
    violations_per_file
    violations_per_statement
    violations_per_line_of_code
);

for my $method ( @methods ) {
    can_ok( $package, $method );
}

#-----------------------------------------------------------------------------

my $code = <<'END_PERL';
package Foo;

use My::Module;
$this = $that if $condition;
sub foo { return @list unless $condition };
END_PERL

#-----------------------------------------------------------------------------

# Just don't get involved with Perl::Tidy.
my $profile = { '-CodeLayout::RequireTidyCode' => {} };
my $critic =
    Perl::Critic->new(
        -severity => 1,
        -profile => $profile,
        -theme => 'core',
    );
my @violations = $critic->critique( \$code );

#print @violations;
#exit;

my %expected_stats = (
    average_sub_mccabe            => 2,
    lines                         => 5,
    modules                       => 1,
    statements                    => 6,
    statements_other_than_subs    => 5,
    subs                          => 1,
    total_violations              => 7,
    violations_per_file           => 7,
    violations_per_line_of_code   => 1.4, # 7 violations / 5 lines
    violations_per_statement      => 1.4, # 7 violations / 5 lines
);

my $stats = $critic->statistics();
isa_ok($stats, $package);

while ( my($method, $expected) = each %expected_stats) {
    is( $stats->$method, $expected, "Statistics: $method");
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/15_statistics.t_without_optional_dependencies.t
1;

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
