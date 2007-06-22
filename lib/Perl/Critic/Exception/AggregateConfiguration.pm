##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::AggregateConfiguration;

use strict;
use warnings;
use English qw(-no_match_vars);

use Perl::Critic::Utils qw{ :characters };

our $VERSION = 1.053;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::AggregateConfiguration' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A collected set of configuration exceptions.',
        fields      => [ qw{ exceptions } ],
    },
);

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my %options = @_;

    my $exceptions = $options{exceptions};
    if (not $exceptions) {
        $options{exceptions} = [];
    }

    return $class->SUPER::new(%options);
}

#-----------------------------------------------------------------------------

sub add_exception {
    my ( $self, $exception ) = @_;

    push @{ $self->exceptions() }, $exception;

    return;
}

#-----------------------------------------------------------------------------

sub add_exceptions_from {
    my ( $self, $aggregate ) = @_;

    push @{ $self->exceptions() }, @{ $aggregate->exceptions() };

    return;
}

#-----------------------------------------------------------------------------

sub has_exceptions {
    my ( $self ) = @_;

    return @{ $self->exceptions() } ? 1 : 0;
}

#-----------------------------------------------------------------------------

my $MESSAGE_PREFIX = $EMPTY;
my $MESSAGE_SUFFIX = "\n";
my $MESSAGE_SEPARATOR = $MESSAGE_SUFFIX . $MESSAGE_PREFIX;

sub full_message {
    my ( $self ) = @_;

    my $message = $MESSAGE_PREFIX;
    $message .= join $MESSAGE_SEPARATOR, @{ $self->exceptions() };
    $message .= $MESSAGE_SUFFIX;

    return $message;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::AggregateConfiguration - A collection of a set of problems found in the configuration and/or command-line options.

=head1 DESCRIPTION

A set of configuration settings can have multiple problems.  This is
an object for collecting all the problems found so that the user can
see them in one run.


=head1 METHODS

=over

=item C<add_exception( $exception )>

Accumulate the parameter with rest of the exceptions.


=item C<add_exceptions_from( $aggregate )>

Accumulate the exceptions from another instance of this class.


=item C<exceptions()>

Returns a reference to an array of the collected exceptions.


=item C<has_exceptions()>

Answer whether any configuration problems have been found.


=item C<full_message()>

Concatenate the exception messages.  See
L<Exception::Class/"full_message">.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
