##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter::EnumerationBehavior;

use strict;
use warnings;
use Carp qw(confess);
use Perl::Critic::Utils;

use base q{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

sub _parse_single {
    my ($self, $parameter, %config) = @_;

    #TODO
}

sub _parse_multiple {
    my ($self, $parameter, %config) = @_;

    #TODO
}

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $enumeration_values_string = $specification->{enumeration_values};

    $enumeration_values_string
        or croak 'No enumeration_values given for '
                    . $parameter->get_name()
                    . '.';
    $parameter->get_behavior_values()->{enumeration_values} =
        hashify( words_from_string( $enumeration_values ) );

    $parameter->get_behavior_values()->{enumeration_allow_multiple_values} = 
        $specification->{enumeration_allow_multiple_values};

    # This is so wrong, but due to time and location constraints and lack of
    # proper Perl OO knowledge, I'll have to look this up later.
    Perl::Critic::PolicyParameter::Behavior::initialize_parameter(@_);

    return;
}

#-----------------------------------------------------------------------------

sub get_parser {
    my ($self, $parameter) = @_;

    if (
        $parameter->get_behavior_values()->{enumeration_allow_multiple_values}
    ) {
        return _parse_multiple;
    }

    return _parse_single;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::PolicyParameter::Behavior - Type-specific subroutines for a PolicyParameter.

=head1 DESCRIPTION


=head1 METHODS


=head1 DOCUMENTATION


=head1 OVERLOADS


=head1 AUTHOR

Elliot Shank <perl@galumph.org>

=head1 COPYRIGHT

Copyright (c) 2006 Elliot Shank.  All rights reserved.

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
