#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::TAP::Formatter::TeamCity;

use strict;
use warnings;

use TeamCity::BuildMessages qw(:all);
use base qw(TAP::Formatter::Console);

#-----------------------------------------------------------------------------

sub prepare {}

#-----------------------------------------------------------------------------

sub summary {}

#-----------------------------------------------------------------------------

sub open_test {
    my ($self, $test, $parser) = @_;

    teamcity_emit_build_message('testSuiteStarted', name => $test);

    my $session = $self->SUPER::open_test($test, $parser);

    while ( defined( my $result = $parser->next() ) ) {
        next if not $result->is_test();
        $self->_emit_teamcity_build_messages($result);
        exit 1 if $result->is_bailout;
    }

    teamcity_emit_build_message('testSuiteFinished', name => $test);

    return $session;
}

#-----------------------------------------------------------------------------

sub _emit_teamcity_build_messages {
    my ($self, $result) = @_;

    my $expl = $result->explanation() || 'No explanation given';
    my $test_name = $result->description() || 'No test name given';
    $test_name =~ s{\A \s* - \s+}{}mx;

    teamcity_emit_build_message('testStarted', name => $test_name);

    if ( $result->has_todo() ) {
        teamcity_emit_build_message('testIgnored', name => $test_name,  message => $expl);
    }
    elsif ( $result->has_skip() ) {
        teamcity_emit_build_message('testIgnored', name => $test_name,  message => $expl);
    }
    elsif ( $result->is_unknown() ) {
        teamcity_emit_build_message('testFailed', name => $test_name,  message => $expl);
    }
    elsif ( not $result->is_ok() ) {
        teamcity_emit_build_message('testFailed', name => $test_name,  message => $expl);
    }

    teamcity_emit_build_message('testFinsihed', name => $test_name);

    return;
}

#-----------------------------------------------------------------------------
1;

=pod

=cut


##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
