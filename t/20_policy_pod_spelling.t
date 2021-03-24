#!perl

=for stopwords arglbargl

=cut

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);
use Readonly;

use Test::More;

Readonly::Scalar my $NUMBER_OF_TESTS => 5;
plan( tests => $NUMBER_OF_TESTS );

our $VERSION = '1.140';

Perl::Critic::TestUtils::assert_version( $VERSION );
Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy = 'Documentation::PodSpelling';
my $can_podspell = can_determine_spell_command() && can_run_spell_command();

sub can_determine_spell_command {
    my $pol = Perl::Critic::Policy::Documentation::PodSpelling->new();
    $pol->initialize_if_enabled();

    return $pol->_get_spell_command_line();
}

sub can_run_spell_command {
    my $pol = Perl::Critic::Policy::Documentation::PodSpelling->new();
    $pol->initialize_if_enabled();

    return $pol->_run_spell_command( <<'END_TEST_CODE' );
=pod

=head1 Test The Spell Command

=cut
END_TEST_CODE
}

sub can_podspell {
    return $can_podspell && ! Perl::Critic::Policy::Documentation::PodSpelling->got_sigpipe();
}

#-----------------------------------------------------------------------------
SKIP: {

$code = <<'END_PERL';
=head1 Silly

=cut
END_PERL

# Sorry about the double negative. The idea is that if hunspell fails (say,
# because it can not find the right dictionary) or pcritique returns a
# non-zero number we want to skip. We have to negate the eval to catch the
# hunspell failure, and then negate pcritique because we negated the eval.
# Clearer code welcome.
if ( ! eval { ! pcritique($policy, \$code) } ) {
   skip 'Test environment is not English', $NUMBER_OF_TESTS;
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 arglbargl

=cut
END_PERL

is(
    eval { pcritique($policy, \$code) },
    can_podspell() ? 1 : undef,
    'Mispelled header',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 Test

arglbargl

=cut
END_PERL

is(
    eval { pcritique($policy, \$code) },
    can_podspell() ? 1 : undef,
    'Mispelled body',
);

#-----------------------------------------------------------------------------


$code = <<'END_PERL';
=for stopwords arglbargl

=head1 Test

arglbargl

=cut
END_PERL

is(
    eval { pcritique($policy, \$code) },
    can_podspell() ? 0 : undef,
    'local stopwords',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 Test

arglbargl

=cut
END_PERL

{
    my %config = (stop_words => 'foo arglbargl bar');
    is(
        eval { pcritique($policy, \$code, \%config) },
        can_podspell() ? 0 : undef ,
        'global stopwords',
    );
}

{
    my %config = (stop_words_file => 't/20_policy_pod_spelling.d/stop-words.txt');
    is(
        eval { pcritique($policy, \$code, \%config) },
        can_podspell() ? 0 : undef ,
        'global stopwords from file',
    );
}

} # end skip

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
