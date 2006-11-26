#!perl

use strict;
use warnings;
use Test::More;
use File::Find;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

=head1 How t/run.t works

Testing a policy follows a very simple pattern:

    * Policy name
        * Subtest name
        * Optional parameters
        * Number of failures expected

Each of the subtests for a policy is collected in a single F<.pl>
file, with POD in front of each code block that describes how we
expect P::C to react to the code.  For example, say you have a
policy called Variables::ProhibitVowels:

    (In file t/Variables/ProhibitVowels.pl)

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
of the multiple-subtests-in-a-file method is that because the F<.pl>
is itself a valid Perl file, and not hidden in a heredoc, your
editor's color-coding still works, and it is much easier to work
with the code and the POD.

# TODO: Abstract this out into a module so other Perl::Critic::* modules
# can use it.

# TODO: test that we have a t/*/*.pl for each lib/*/*.pm

# TODO: Allow us to specify the nature of the failures, and which one.

=cut

my %subtests;
my $nsubtests;
find( sub {
    if ( -f && ( $File::Find::name =~ m{t/(.+)\.pl$} ) ) {
        my $policy = $1;
        $policy =~ s{/}{::}gmsx;

        my @subtests = subtests( $_ );
        $nsubtests += @subtests;
        $subtests{ $policy } = [ @subtests ];
    }
}, 't/' );

my $npolicies = scalar keys %subtests;

plan tests => $nsubtests + $npolicies;

for my $policy ( sort keys %subtests ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{$subtests{ $policy }} ) {
        run_subtest( $policy, $subtest );
    }
}

sub run_subtest {
    my $policy = shift;
    my $subtest = shift;

    my $name = $subtest->{name};

    my $code = join( "\n", @{$subtest->{code}} );
    my $nfailures = $subtest->{failures};
    defined $nfailures or die "$policy, $name does not specify failures\n";

    my $parms = $subtest->{parms} ? eval $subtest->{parms} : {};

    is( pcritique($policy, \$code, $parms), $nfailures, "$policy: $name" );
}

=for notes

The internal representation of a subtest is just a hash with some
named keys.  It could be an object with accessors for safety's sake,
but at this point I don't see why.

=cut

sub subtests {
    my $test_file = shift;

    my %valid_keys = map {($_,1)} qw( name failures parms );

    open( my $fh, '<', $test_file ) or die "Couldn't open $test_file: $!";

    my @subtests = ();

    my $incode = 0;
    my $subtest;
    while ( <$fh> ) {
        chomp;
        my $inpod = /^=name/ .. /^=cut/;

        my $line = $_;

        if ( $inpod ) {
            $line =~ /^=(\S+)\s+(.+)/ or next;
            my ($key,$value) = ($1,$2);
            die "Unknown key $key" unless $valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push( @subtests, $subtest );
                    undef $subtest;
                }
                $incode = 0;
            }
            $incode && die "POD found while I'm still in code";
            $subtest->{$key} = $value;
        }
        else {
            $incode = 1;
            push @{$subtest->{code}}, $line if $subtest; # Don't start a subtest if we're not in one
        }
    }
    close $fh;
    if ( $subtest ) {
        if ( $incode ) {
            push( @subtests, $subtest );
        }
        else {
            die "Incomplete subtest in $test_file";
        }
    }

    return @subtests;
}

#----------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab ft=perl:
