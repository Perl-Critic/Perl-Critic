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

sub open_test {
    my ($self, $test, $parser) = @_;

    teamcity_emit_build_message('testSuiteStarted', name => $test);

    my $session = $self->SUPER::open_test($test, $parser);

    while ( defined( my $result = $parser->next() ) ) {
        $self->_emit_teamcity_messages($result) if $result->is_test();
        $session->result($result);
        exit 1 if $result->is_bailout();
    }

    teamcity_emit_build_message('testSuiteFinished', name => $test);

    return $session;
}

#-----------------------------------------------------------------------------

sub _emit_teamcity_messages {
    my ($self, $result) = @_;

    my $expl = $result->explanation() || 'No explanation given';
    my $test_name = $result->description() || 'No test name given';
    $test_name =~ s{\A \s* - \s+}{}mx;

    teamcity_emit_build_message('testStarted', name => $test_name);
    $self->_emit_teamcity_test_results($test_name, $expl, $result);
    teamcity_emit_build_message('testFinished', name => $test_name);

    return;
}

#-----------------------------------------------------------------------------

sub _emit_teamcity_test_results {
    my ($self, $test_name, $expl, $result) = @_;
    
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
    
    return;
}

#-----------------------------------------------------------------------------
1;

=pod

=head1 NAME

TAP::Formatter::TeamCity

=head1 SYNOPSIS

   # When using prove(1):
   prove -formatter TAP::Formatter::TeamCity my_test.t

   # From within a Module::Build subclass:
   sub tap_harness_args { return {formatter_class => 'TAP::Formatter::TeamCity'} }

=head1 DESCRIPTION

=head1 AUTHOR

Jeffrey Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT   

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
