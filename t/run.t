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

If you need to pass special parms for your subtest, do so like this:

    =parms { allow_y => 0 }

If it's a TODO subtest (probably because of some weird corner of
PPI that we exercised that Adam is getting around to fixing, right?),
then make a C<=TODO> POD entry.

    =TODO Should pass when PPI 1.xxx comes out

The value of I<parms> will get C<eval>ed and passed to C<pcritique>,
so be careful.

Note that nowhere within the F<.pl> file itself do you specify the
policy that you're testing.  That's implicit within the filename.

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

        my @subtests = subtests( $_, $File::Find::name );
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

    TODO: {
        local $TODO = $subtest->{TODO}; # Is NOT a TODO if it's not set
        is( pcritique($policy, \$code, $parms), $nfailures, "$policy: $name" );
    }
}

=for notes

The internal representation of a subtest is just a hash with some
named keys.  It could be an object with accessors for safety's sake,
but at this point I don't see why.

=cut

sub subtests {
    my $test_file = shift;
    my $full_path = shift;

    my %valid_keys = map {($_,1)} qw( name failures parms TODO );

    return () unless -s $test_file; # XXX Remove me once all subtest files are populated

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
            die "Unknown key $key in $full_path" unless $valid_keys{$key};

            if ( $key eq 'name' ) {
                if ( $subtest ) { # Stash any current subtest
                    push( @subtests, $subtest );
                    undef $subtest;
                }
                $incode = 0;
            }
            $incode && die "POD found while I'm still in code: $full_path";
            $subtest->{$key} = $value;
        }
        else {
            if ( $subtest ) {
                $incode = 1;
                push @{$subtest->{code}}, $line if $subtest; # Don't start a subtest if we're not in one
            }
            else {
                die "Got some code but I'm not in a subtest: $full_path";
            }
        }
    }
    close $fh;
    if ( $subtest ) {
        if ( $incode ) {
            push( @subtests, $subtest );
        }
        else {
            die "Incomplete subtest in $full_path";
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
