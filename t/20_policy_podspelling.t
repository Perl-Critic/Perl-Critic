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
my $can_podspell = eval {require Pod::Spell} &&
  Perl::Critic::Policy::Documentation::PodSpelling->new->_get_spell_command;

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
    local $config{stopwords} = 'foo arglbargl bar';
    is( pcritique($policy, \$code, \%config), 0, 'global stopwords' );
}

} # end skip

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
