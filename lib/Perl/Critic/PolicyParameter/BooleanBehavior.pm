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

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

sub _parse {
    my ($policy, $parameter, $config_string) = @_;

    my $value;
    my $value_string = $parameter->get_default_string();

    if (defined $config_string) {
        $value_string = $config_string;
    }

    if ( defined $value_string ) {
        if ( $value_string ) {
            $value = $TRUE;
        } else {
            $value = $FALSE;
        }
    }

    my $name = q{_} . $parameter->get_name();
    $policy->{ $name } = $value;
    return;
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

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::BooleanBehavior - Actions appropriate for a boolean.


=head1 DESCRIPTION

Provides a standard set of functionality for a boolean
L<Perl::Critic::PolicyParameter> so that the developer of a policy
does not have to provide it her/himself.


=head1 METHODS

=over

=item C<initialize_parameter( $parameter, $specification )>

Plug in the functionality this behavior provides into the parameter.
At present, this behavior isn't customizable by the specification.

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
