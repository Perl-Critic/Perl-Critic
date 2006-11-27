#!perl

use strict;
use warnings;
use Test::More;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique subtests_in_tree run_subtest);
Perl::Critic::TestUtils::block_perlcriticrc();

my ($subtests,$nsubtests) = subtests_in_tree( 't/' );

my $npolicies = scalar keys %$subtests;

plan tests => $nsubtests + $npolicies;

for my $policy ( sort keys %$subtests ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{$subtests->{ $policy }} ) {
        run_subtest( $policy, $subtest );
    }
}

=head1 How t/run.t works

Testing a policy follows a very simple pattern:

    * Policy name
        * Subtest name
        * Optional parameters
        * Number of failures expected

Each of the subtests for a policy is collected in a single F<.run>
file, with POD in front of each code block that describes how we
expect P::C to react to the code.  For example, say you have a
policy called Variables::ProhibitVowels:

    (In file t/Variables/ProhibitVowels.run)

    =name Basics

    =failures 1

    =cut

    my $vrbl_nm = 'foo';    # Good, vowel-free name
    my $wango = 12;         # Bad, pronouncable name


    =name Sometimes Y

    =failures 1

    =cut

    my $yllw = 0;       # "y" not a vowel here
    my $rhythm = 12;    # But here it is

These are called "subtests", and two are shown above.  The beauty
of the multiple-subtests-in-a-file method is that because the F<.run>
is itself a valid Perl file, and not hidden in a heredoc, your
editor's color-coding still works, and it is much easier to work
with the code and the POD.

If you need to pass special parms for your subtest, do so like this:

    =parms { allow_y => 0 }

If it's a TODO subtest (probably because of some weird corner of
PPI that we exercised that Adam is getting around to fixing, right?),
then make a C<=TODO> POD entry.

    =TODO Should pass when PPI 1.xxx comes out

The value of I<parms> will get C<eval>ed and passed to C<pcritique>,
so be careful.

Note that nowhere within the F<.run> file itself do you specify the
policy that you're testing.  That's implicit within the filename.

# TODO: Abstract this out into a module so other Perl::Critic::* modules
# can use it.  Name suggestion: Perl::Critic::TestHarness

# TODO: test that we have a t/*/*.run for each lib/*/*.pm

# TODO: Allow us to specify the nature of the failures, and which one.
# thaljef: I'm not sure what this means?

# TODO: Allow test runner to take arguments, so you can specify
# which subtests to run.

# TODO: Make the File::Find callback portable (e.g. use catfile or some such).

=cut

#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab ft=perl:

