#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 4;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy = 'Documentation::PodSpelling';
my %config;
my $can_podspell = eval {require Pod::Spell} && can_determine_spell_command();

sub can_determine_spell_command {
    my $policy = Perl::Critic::Policy::Documentation::PodSpelling->new();
    $policy->initialize_if_enabled();

    return $policy->_get_spell_command_line();
}

#-----------------------------------------------------------------------------
SKIP: {

$code = <<'END_PERL';
=head1 Test

=cut
END_PERL

if (pcritique($policy, \$code, \%config)) {
   skip 'Test environment is not English', 4
}

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 arglbargl

=cut
END_PERL

is( pcritique($policy, \$code, \%config), $can_podspell ? 1 : 0, 'Mispelled header' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 Test

arglbargl

=cut
END_PERL

is( pcritique($policy, \$code, \%config), $can_podspell ? 1 : 0, 'Mispelled body' );

#-----------------------------------------------------------------------------


$code = <<'END_PERL';
=for stopwords arglbargl

=head1 Test

arglbargl

=cut
END_PERL

is( pcritique($policy, \$code, \%config), 0, 'local stopwords' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
=head1 Test

arglbargl

=cut
END_PERL

{
    local $config{stop_words} = 'foo arglbargl bar';
    is( pcritique($policy, \$code, \%config), 0, 'global stopwords' );
}

} # end skip

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/20_policy_podspelling.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
