#!perl

use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique_with_violations);
use Readonly;

use Test::More;

Readonly::Scalar my $NUMBER_OF_TESTS => 6;

plan( tests => $NUMBER_OF_TESTS );

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

sub has_policy {
    return eval {
        require Perl::Critic::Policy::CodeLayout::ProhibitHashBarewords;
        1;
    };
}

my $policy = 'CodeLayout::ProhibitHashBarewords';
my $code;

#-----------------------------------------------------------------------------
SKIP: {

has_policy()
    or skip 'You need CodeLayout::ProhibitHashBarewords policy for this test',
    $NUMBER_OF_TESTS;

$code = <<'END_PERL';
my %hash = (
    foo => 1,
    bar => 2,



    baz => 3,

    quux => 4,


);
END_PERL

my @violations_re = (
    qr{^ \s* foo \s  =>}xms,
    qr{^ \s* bar \s  =>}xms,
    qr{^ \s* baz \s  =>}xms,
    qr{^ \s* quux \s =>}xms,
);

my @violations;
my $rc = eval { @violations = pcritique_with_violations( $policy, \$code ); 2112; };
is( $rc, 2112, 'Eval ran OK' );
is( scalar @violations, 4, 'Found 4 violations' );

foreach my $violation (@violations) {
    my $violation_re = shift @violations_re || qr/^NOPE$/xms;
    like( $violation->source, $violation_re, 'Correct line for violation' );
}

} # end skip

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/20_policy_pod_spelling.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
