##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Statistics;

use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Utils::McCabe qw{ &calculate_mccabe_of_sub };

#-----------------------------------------------------------------------------

our $VERSION = 1.052;

#-----------------------------------------------------------------------------

sub new {
    my ( $class ) = @_;

    my $self = bless {}, $class;

    $self->{_modules} = 0;
    $self->{_subs} = 0;
    $self->{_statements} = 0;
    $self->{_lines_of_code} = 0;
    $self->{_violations_by_policy} = {};
    $self->{_violations_by_severity} = {};
    $self->{_total_violations} = 0;

    return $self;
}

#-----------------------------------------------------------------------------

sub accumulate {
    my ($self, $doc, $violations) = @_;

    $self->{_modules}++;

    my $subs = $doc->find('PPI::Statement::Sub');
    if ($subs) {
        foreach my $sub ( @{$subs} ) {
            $self->{_subs}++;
            $self->{_subs_total_mccabe} += calculate_mccabe_of_sub( $sub );
        }
    }

    my $statements = $doc->find('PPI::Statement');
    $self->{_statements} += $statements ? scalar @{$statements} : 0;

    ## no critic (RequireExtendedFormatting, RequireLineBoundaryMatching)
    my @lines_of_code = split /$INPUT_RECORD_SEPARATOR/, $doc->serialize();
    ## use critic
    $self->{_lines_of_code} += scalar @lines_of_code;

    foreach my $violation ( @{ $violations } ) {
        $self->{_violations_by_severity}->{ $violation->severity() }++;
        $self->{_violations_by_policy}->{ $violation->policy() }++;
        $self->{_total_violations}++;
    }

    return;
}

#-----------------------------------------------------------------------------

sub modules {
    my ( $self ) = @_;

    return $self->{_modules};
}

#-----------------------------------------------------------------------------

sub subs {
    my ( $self ) = @_;

    return $self->{_subs};
}

#-----------------------------------------------------------------------------

sub statements {
    my ( $self ) = @_;

    return $self->{_statements};
}

#-----------------------------------------------------------------------------

sub lines_of_code {
    my ( $self ) = @_;

    return $self->{_lines_of_code};
}

#-----------------------------------------------------------------------------

sub _subs_total_mccabe {
    my ( $self ) = @_;

    return $self->{_subs_total_mccabe};
}

#-----------------------------------------------------------------------------

sub violations_by_severity {
    my ( $self ) = @_;

    return $self->{_violations_by_severity};
}

#-----------------------------------------------------------------------------

sub violations_by_policy {
    my ( $self ) = @_;

    return $self->{_violations_by_policy};
}

#-----------------------------------------------------------------------------

sub total_violations {
    my ( $self ) = @_;

    return $self->{_total_violations};
}

#-----------------------------------------------------------------------------

sub average_sub_mccabe {
    my ( $self ) = @_;

    return if $self->subs() == 0;

    return $self->_subs_total_mccabe() / $self->subs();
}

#-----------------------------------------------------------------------------

sub violations_per_line_of_code {
    my ( $self ) = @_;

    return if $self->lines_of_code() == 0;

    return $self->total_violations() / $self->lines_of_code();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords McCabe

=head1 NAME

Perl::Critic::Statistics - Compile stats on Perl::Critic violations

=head1 DESCRIPTION

This class accumulates statistics on Perl::Critic violations across one or
more files.  NOTE: This class is experimental and subject to change.

=head1 METHODS

=over

=item C<new()>

Create a new instance of Perl::Critic::Statistics.  No arguments are supported
at this time.

=item C< accumulate( $doc, \@violations ) >

Accumulates statistics about the C<$doc> and the C<@violations> that were
found.

=item C<modules()>

The number of chunks of code (usually files) that have been analyzed.

=item C<subs()>

The total number of subroutines analyzed by this Critic.

=item C<statements()>

The total number of statements analyzed by this Critic.

=item C<lines_of_code()>

The total number of lines of code analyzed by this Critic.

=item C<violations_by_severity()>

The number of violations of each severity found by this Critic as a
reference to a hash keyed by severity.

=item C<violations_by_policy()>

The number of violations of each policy found by this Critic as a
reference to a hash keyed by full policy name.

=item C<total_violations()>

The the total number of violations found by this Critic.

=item C<average_sub_mccabe()>

The average McCabe score of all scanned subroutines.

=item C<violations_per_line_of_code()>

The total violations divided by the lines of code.

=back


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
