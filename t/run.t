#!perl

use strict;
use warnings;
use Test::More;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique subtests_in_tree);
Perl::Critic::TestUtils::block_perlcriticrc();

my ($subtests,$nsubtests) = subtests_in_tree( 't' );

my $npolicies = scalar keys %$subtests;

plan tests => $nsubtests + $npolicies;

for my $policy ( sort keys %$subtests ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{$subtests->{$policy}} ) {
        local $TODO = $subtest->{TODO}; # Is NOT a TODO if it's not set
        is(
            pcritique($policy, \$subtest->{code}, $subtest->{parms}),
            $subtest->{failures},
            "$policy: $subtest->{name}"
        );
    }
}

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab ft=perl:

