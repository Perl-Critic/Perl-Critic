package Perl::Critic::Statistics;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Utils::McCabe qw{ calculate_mccabe_of_sub };

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub new {
    my ( $class ) = @_;

    my $self = bless {}, $class;

    $self->{_modules} = 0;
    $self->{_subs} = 0;
    $self->{_statements} = 0;
    $self->{_lines} = 0;
    $self->{_lines_of_blank} = 0;
    $self->{_lines_of_comment} = 0;
    $self->{_lines_of_data} = 0;
    $self->{_lines_of_perl} = 0;
    $self->{_lines_of_pod} = 0;
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

    ## no critic (RequireDotMatchAnything, RequireExtendedFormatting, RequireLineBoundaryMatching)
    my @lines = split /$INPUT_RECORD_SEPARATOR/, $doc->serialize();
    ## use critic
    $self->{_lines} += scalar @lines;
    {
        my ( $in_data, $in_pod );
        foreach ( @lines ) {
            if ( q{=} eq substr $_, 0, 1 ) {    ## no critic (ProhibitCascadingIfElse)
                $in_pod = not m/ \A \s* =cut \b /smx;
                $self->{_lines_of_pod}++;
            } elsif ( $in_pod ) {
                $self->{_lines_of_pod}++;
            } elsif ( q{__END__} eq $_ || q{__DATA__} eq $_ ) {
                $in_data = 1;
                $self->{_lines_of_perl}++;
            } elsif ( $in_data ) {
                $self->{_lines_of_data}++;
            } elsif ( m/ \A \s* \# /smx ) {
                $self->{_lines_of_comment}++;
            } elsif ( m/ \A \s* \z /smx ) {
                $self->{_lines_of_blank}++;
            } else {
                $self->{_lines_of_perl}++;
            }
        }
    }

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

sub lines {
    my ( $self ) = @_;

    return $self->{_lines};
}

#-----------------------------------------------------------------------------

sub lines_of_blank {
    my ( $self ) = @_;

    return $self->{_lines_of_blank};
}

#-----------------------------------------------------------------------------

sub lines_of_comment {
    my ( $self ) = @_;

    return $self->{_lines_of_comment};
}

#-----------------------------------------------------------------------------

sub lines_of_data {
    my ( $self ) = @_;

    return $self->{_lines_of_data};
}

#-----------------------------------------------------------------------------

sub lines_of_perl {
    my ( $self ) = @_;

    return $self->{_lines_of_perl};
}

#-----------------------------------------------------------------------------

sub lines_of_pod {
    my ( $self ) = @_;

    return $self->{_lines_of_pod};
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

sub statements_other_than_subs {
    my ( $self ) = @_;

    return $self->statements() - $self->subs();
}

#-----------------------------------------------------------------------------

sub average_sub_mccabe {
    my ( $self ) = @_;

    return if $self->subs() == 0;

    return $self->_subs_total_mccabe() / $self->subs();
}

#-----------------------------------------------------------------------------

sub violations_per_file {
    my ( $self ) = @_;

    return if $self->modules() == 0;

    return $self->total_violations() / $self->modules();
}

#-----------------------------------------------------------------------------

sub violations_per_statement {
    my ( $self ) = @_;

    my $statements = $self->statements_other_than_subs();

    return if $statements == 0;

    return $self->total_violations() / $statements;
}

#-----------------------------------------------------------------------------

sub violations_per_line_of_code {
    my ( $self ) = @_;

    return if $self->lines() == 0;

    return $self->total_violations() / $self->lines();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords McCabe

=head1 NAME

Perl::Critic::Statistics - Compile stats on Perl::Critic violations.


=head1 DESCRIPTION

This class accumulates statistics on Perl::Critic violations across one or
more files.  NOTE: This class is experimental and subject to change.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


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


=item C<lines()>

The total number of lines of code analyzed by this Critic.


=item C<lines_of_blank()>

The total number of blank lines analyzed by this Critic. This includes only
blank lines in code, not POD or data.


=item C<lines_of_comment()>

The total number of comment lines analyzed by this Critic. This includes only
lines whose first non-whitespace character is C<#>.


=item C<lines_of_data()>

The total number of lines of data section analyzed by this Critic, not
counting the C<__END__> or C<__DATA__> line. POD in a data section is counted
as POD, not data.


=item C<lines_of_perl()>

The total number of lines of Perl code analyzed by this Critic. Perl appearing
in the data section is not counted.


=item C<lines_of_pod()>

The total number of lines of POD analyzed by this Critic. Pod occurring in a
data section is counted as POD, not as data.


=item C<violations_by_severity()>

The number of violations of each severity found by this Critic as a
reference to a hash keyed by severity.


=item C<violations_by_policy()>

The number of violations of each policy found by this Critic as a
reference to a hash keyed by full policy name.


=item C<total_violations()>

The total number of violations found by this Critic.


=item C<statements_other_than_subs()>

The total number of statements minus the number of subroutines.
Useful because a subroutine is considered a statement by PPI.


=item C<average_sub_mccabe()>

The average McCabe score of all scanned subroutines.


=item C<violations_per_file()>

The total violations divided by the number of modules.


=item C<violations_per_statement()>

The total violations divided by the number statements minus
subroutines.


=item C<violations_per_line_of_code()>

The total violations divided by the lines of code.


=back


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
