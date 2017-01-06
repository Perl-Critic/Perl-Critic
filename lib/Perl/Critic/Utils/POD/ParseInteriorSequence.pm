package Perl::Critic::Utils::POD::ParseInteriorSequence;

use 5.006001;
use strict;
use warnings;

use base qw{ Pod::Parser };

use IO::String;

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub interior_sequence {
    my ( $self, $seq_cmd, $seq_arg, $pod_seq ) = @_;
    push @{ $self->{+__PACKAGE__}{interior_sequence} ||= [] }, $pod_seq;
    return $self->SUPER::interior_sequence( $seq_cmd, $seq_arg, $pod_seq );
}

#-----------------------------------------------------------------------------

sub get_interior_sequences {
    my ( $self, $pod ) = @_;
    $self->{+__PACKAGE__}{interior_sequence} = [];
    my $result;
    $self->parse_from_filehandle(
        IO::String->new( \$pod ),
        IO::String->new( \$result )
    );
    return @{ $self->{+__PACKAGE__}{interior_sequence} };
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::POD::ParseInteriorSequence - Pod::Parser subclass to find all interior sequences.


=head1 SYNOPSIS

    use Perl::Critic::Utils::POD::ParseInteriorSequence;

    my $parser = Perl::Critic::Utils::POD::ParseInteriorSequence->new();
    my @sequences = $parser->parse_interior_sequences(
        $pod->content() );


=head1 DESCRIPTION

Provides a means to extract interior sequences from POD text.


=head1 INTERFACE SUPPORT

This module is considered to be private to Perl::Critic. It can be
changed or removed without notice.


=head1 METHODS

=over

=item C<get_interior_sequences( $pod_text )>

Returns an array of all the interior sequences from a given chunk of POD
text, represented as L<Pod::InteriorSequence|Pod::InputObjects> objects.
The POD text is assumed to begin with a POD command (e.g.  C<=pod>).

=item C<interior_sequence( $seq_cmd, $seq_arg, $pod_seq )>

Overrides the parent's method of the same name. Stashes the $pod_seq
argument, which is a C<Pod::InteriorSequence> object, so that
C<get_interior_sequences()> has access to it.

=back


=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>


=head1 COPYRIGHT

Copyright (c) 2011 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
