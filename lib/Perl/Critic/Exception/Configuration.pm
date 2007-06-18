##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::Configuration;

use strict;
use warnings;

our $VERSION = 1.053;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Configuration' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A problem with Perl::Critic configuration, whether from a file or a command line or some other source.',
        fields      => [ qw{ option_name option_value source message_suffix } ],
    },
);

use Perl::Critic::Exception::Internal;

#-----------------------------------------------------------------------------

sub message {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

sub error {
    my $self = shift;

    return $self->full_message();
}

#-----------------------------------------------------------------------------

## no critic (Subroutines::RequireFinalReturn)
sub full_message {
    Perl::Critic::Exception::Internal->throw(
        'Subclass failed to override abstract method.'
    );
}
## use critic


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Configuration - A problem with L<Perl::Critic> configuration

=head1 DESCRIPTION

A representation of a problem found with the configuration of
L<Perl::Critic>, whether from a F<.perlcriticrc>, another profile
file, or command line.

This is an abstract class.  It should never be instantiated.


=head1 METHODS

=over

=item C<option_name()>

The name of the option that was found to be in error.


=item C<option_value()>

The value of the option that was found to be in error.


=item C<source()>

Where the value of the option came from, if it could be determined.


=item C<message_suffix()>

Any text that should be applied to end of the standard message for
this kind of exception.


=item C<message()>

=item C<error()>

Overridden to call C<full_message()>.  I.e. any message string in the
superclass is ignored.


=item C<full_message()>

Overridden to turn it into an abstract method to force subclasses to
implement it.


=back


=head1 SEE ALSO

L<Perl::Critic::Exception::Configuration::Global>
L<Perl::Critic::Exception::Configuration::Policy>


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
