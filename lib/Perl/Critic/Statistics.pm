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

our $VERSION = 1.051;

#-----------------------------------------------------------------------------

our $AUTOLOAD;

sub AUTOLOAD {  ## no critic(ProhibitAutoloading)
    my ( $method ) = $AUTOLOAD =~ m/ ( [^:]+ ) \z /xms;
    return if $method eq 'DESTROY';

    my ( $self ) = @_;
    return $self->_critic()->$method(@_);
}

#-----------------------------------------------------------------------------

sub new {
    my ( $class, $critic ) = @_;

    my $self = bless {}, $class;

    $self->{_critic} = $critic;
    $self->{_modules} = 0;
    $self->{_subs} = 0;
    $self->{_statements} = 0;
    $self->{_lines_of_code} = 0;
    $self->{_severity_violations} = {};
    $self->{_policy_violations} = {};
    $self->{_total_violations} = 0;

    return $self;
}

#-----------------------------------------------------------------------------

sub critique {
    my ( $self, $source_code ) = @_;

    return if not $source_code;

    my $critic = $self->_critic();

    my $doc = $critic->_create_perl_critic_document($source_code);
    my @violations = $critic->_gather_violations($doc);

    $self->_accumulate($doc, \@violations);

    return @violations;
}

#-----------------------------------------------------------------------------

sub _accumulate {
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
        $self->{_severity_violations}->{ $violation->severity() }++;
        $self->{_policy_violations}->{ $violation->policy() }++;
        $self->{_total_violations}++;
    }

    return;
}

#------------------------------------------------------------------------------

sub _critic {
    my ( $self ) = @_;

    return $self->{_critic};
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

sub severity_violations {
    my ( $self ) = @_;

    return $self->{_severity_violations};
}

#-----------------------------------------------------------------------------

sub policy_violations {
    my ( $self ) = @_;

    return $self->{_policy_violations};
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

Perl::Critic::Statistics - Decorator for a L<Perl::Critic> instance to accumulate statistics.

=head1 DESCRIPTION

Wraps an instance of L<Perl::Critic> and aggregates statistics resulting from
calls to C<critique()>.

=head1 METHODS

=over

=item C<new( $critic )>

Create a new instance around a L<Perl::Critic>.

=item C<critique( $source_code )>

Version of L<Perl::Critic/"critique"> that gathers statistics.

=item C<modules()>

The number of chunks of code that have been passed to C<critique()>.

=item C<subs()>

The number of subroutines analyzed by C<critique()>.

=item C<statements()>

The number of statements analyzed by C<critique()>.

=item C<lines_of_code()>

The number of lines of code analyzed by C<critique()>.

=item C<severity_violations()>

The number of violations of each severity found by C<critique()> as a
reference to a hash keyed by severity.

=item C<policy_violations()>

The number of violations of each policy found by C<critique()> as a
reference to a hash keyed by full policy name.

=item C<total_violations()>

The the total number of violations found by C<critique()>.

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
