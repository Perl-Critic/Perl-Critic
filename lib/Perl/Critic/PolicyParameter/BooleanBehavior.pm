##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter::BooleanBehavior;

use strict;
use warnings;
use Carp qw(confess);
use Perl::Critic::Utils;

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

sub _parse {
    my ($self, $parameter, %config) = @_;

    my $key = $parameter->get_name();
    my $value = $parameter->get_default();

    if ( defined $config{$key} ) {
        if ( $config{$key} ) {
            $value = $TRUE;
        } else {
            $value = $FALSE;
        }
    }

    return $value;
}

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    $parameter->_set_parser(\&_parse);

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::PolicyParameter::BooleanBehavior - Subroutines for a boolean PolicyParameter.

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
