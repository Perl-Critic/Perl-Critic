##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::ConfigErrors;

use strict;
use warnings;
use English qw(-no_match_vars);

use Perl::Critic::Utils qw{ :characters };

use overload ( q{""} => 'to_string' );

#-----------------------------------------------------------------------------

our $VERSION = '1.081_004';

#-----------------------------------------------------------------------------
# Constructor

sub new {
    my ( $class ) = @_;
    my $self = bless {}, $class;

    $self->{_messages} = [];

    return $self;
}

#-----------------------------------------------------------------------------

sub add_message {
    my ( $self, $message ) = @_;

    push @{ $self->messages() }, $message;

    return;
}

#-----------------------------------------------------------------------------

sub add_bad_option_message {
    my ( $self, $option_name, $value, $source, $suffix ) = @_;

    if ($source) {
        $source = qq{ found in "$source"};
    }
    else {
        $source = q{};
    }

    $self->add_message(
        qq{The value for "$option_name" ("$value")$source }
            . $suffix
    );

    return;
}

#-----------------------------------------------------------------------------

sub messages {
    my ( $self ) = @_;

    return $self->{_messages};
}

#-----------------------------------------------------------------------------

my $MESSAGE_PREFIX = $EMPTY;
#my $MESSAGE_PREFIX = $SPACE x 4;
my $MESSAGE_SUFFIX = "\n";
my $MESSAGE_SEPARATOR = $MESSAGE_SUFFIX . $MESSAGE_PREFIX;

sub to_string {
    my ( $self ) = @_;

    my $string_representation = $MESSAGE_PREFIX;
    $string_representation .= join $MESSAGE_SEPARATOR, @{ $self->messages() };
    $string_representation .= $MESSAGE_SUFFIX;

    return $string_representation;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::ConfigErrors - An exception object collecting a set of problems found by L<Perl::Critic::Config>.

=head1 DESCRIPTION

A set of configuration settings can have multiple problems.  This is
an object for collecting all the problems found so that the user can
see them in one run.  Stringification is overridden to allow this
object to show all the messages when printed as the result of an
C<eval>.


=head1 METHODS

=over

=item C<add_message( $message )>

Accumulate the parameter with rest of the messages.


=item C<add_bad_option_message( $option_name, $value, $source, $suffix )>

Accumulate a standardized message for a bad option.  C<$option_name>
should have a leading minus ("-") if the option was specified on a
command line.  C<$value> is the input that was found wanting.
C<$source> should be the origination point of the C<$value>, most
likely the name of a F<.perlcriticrc>.  C<$suffix> is the non-standard
part of the message, describing the fault(s) of the C<$value>.


=item C<messages()>

Returns a reference to an array of the collected messages.


=item C<to_string()>

Returns a string representation of this object, suitable for printing
as an error message.

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
