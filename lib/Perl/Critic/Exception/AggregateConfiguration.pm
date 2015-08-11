package Perl::Critic::Exception::AggregateConfiguration;

use 5.006001;
use strict;
use warnings;

use Carp qw{ confess };
use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::AggregateConfiguration' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A collected set of configuration exceptions.',
        fields      => [ qw{ exceptions } ],
        alias       => 'throw_aggregate',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_aggregate >;

#-----------------------------------------------------------------------------

sub new {
    my ($class, %options) = @_;

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

sub add_exception_or_rethrow {
    my ( $self, $eval_error ) = @_;

    return if not $eval_error;
    confess $eval_error if not ref $eval_error;

    if ( $eval_error->isa('Perl::Critic::Exception::Configuration') ) {
        $self->add_exception($eval_error);
    }
    elsif (
        $eval_error->isa('Perl::Critic::Exception::AggregateConfiguration')
    ) {
        $self->add_exceptions_from($eval_error);
    }
    else {
        die $eval_error; ## no critic (RequireCarping)
    }

    return;
}

#-----------------------------------------------------------------------------

sub has_exceptions {
    my ( $self ) = @_;

    return @{ $self->exceptions() } ? 1 : 0;
}

#-----------------------------------------------------------------------------

Readonly::Scalar my $MESSAGE_PREFIX => $EMPTY;
Readonly::Scalar my $MESSAGE_SUFFIX => "\n";
Readonly::Scalar my $MESSAGE_SEPARATOR => $MESSAGE_SUFFIX . $MESSAGE_PREFIX;

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


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<add_exception( $exception )>

Accumulate the parameter with rest of the exceptions.


=item C<add_exceptions_from( $aggregate )>

Accumulate the exceptions from another instance of this class.


=item C<exceptions()>

Returns a reference to an array of the collected exceptions.


=item C<add_exception_or_rethrow( $eval_error )>

If the parameter is an instance of
L<Perl::Critic::Exception::Configuration|Perl::Critic::Exception::Configuration>
or
L<Perl::Critic::Exception::AggregateConfiguration|Perl::Critic::Exception::AggregateConfiguration>,
add it.  Otherwise, C<die> with the parameter, if it is a reference,
or C<confess> with it.  If the parameter is false, simply returns.


=item C<has_exceptions()>

Answer whether any configuration problems have been found.


=item C<full_message()>

Concatenate the exception messages.  See
L<Exception::Class/"full_message">.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

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
