##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter::Behavior;

use strict;
use warnings;
use Carp qw(confess);

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;

    return bless {}, $class;
}

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::Behavior - Type-specific subroutines for a PolicyParameter.


=head1 DESCRIPTION

Provides a standard set of functionality for a
L<Perl::Critic::PolicyParameter> so that the developer of a policy does not
have to provide it her/himself.


=head1 METHODS

=over

=item C<initialize_parameter( $parameter, $specification )>

Plug in the functionality this behavior provides into the parameter, based
upon the configuration provided by the specification.  The configuration
items looked for depends upon the specific behavior subclass.

=back


=head1 AUTHOR

Elliot Shank <perl@galumph.org>

=head1 COPYRIGHT

Copyright (c) 2006-2007 Elliot Shank.  All rights reserved.

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
