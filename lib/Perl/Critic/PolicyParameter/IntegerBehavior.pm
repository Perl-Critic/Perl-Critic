##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter::IntegerBehavior;

use strict;
use warnings;
use Carp qw(confess);

use Perl::Critic::Utils qw{ :characters };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = 1.053;

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $minimum = $specification->{integer_minimum};
    my $maximum = $specification->{integer_maximum};

    $parameter->_get_behavior_values()->{minimum} = $minimum;
    $parameter->_get_behavior_values()->{maximum} = $maximum;

    my $policy_variable_name = q{_} . $parameter->get_name();

    $parameter->_set_parser(
        sub {
            # Normally bad thing, obscuring a variable in a outer scope
            # with a variable with the same name is being done here in
            # order to remain consistent with the parser function interface.
            my ($policy, $parameter, $config_string) = @_;

            my $value_string = $parameter->get_default_string();

            if (defined $config_string) {
                $value_string = $config_string;
            }

            my $value;
            if ( defined $value_string ) {
                if (
                        $value_string !~ m/ \A [-+]? [1-9] \d* \z /xms
                    and $value_string ne '0'
                ) {
                    die q{Invalid value for },
                        $parameter->get_name(),
                        qq{: $value_string does not look like an integer.\n};
                }

                $value = $value_string + 0;

                if ( defined $minimum and $minimum > $value ) {
                    die q{Invalid value for },
                        $parameter->get_name(),
                        qq{: $value is less than $minimum.\n};
                }

                if ( defined $maximum and $maximum < $value ) {
                    die q{Invalid value for },
                        $parameter->get_name(),
                        qq{: $value is greater than $maximum.\n};
                }
            }

            $policy->{ $policy_variable_name } = $value;
            return;
        }
    );

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    my $minimum = $parameter->_get_behavior_values()->{minimum};
    my $maximum = $parameter->_get_behavior_values()->{maximum};

    my $description = $parameter->_get_description_with_trailing_period();
    if ( $description ) {
        $description .= qq{\n};
    }

    if (defined $minimum or defined $maximum) {
        if (defined $minimum) {
            $description .= "Minimum value $minimum. ";
        } else {
            $description .= 'No minimum. ';
        }

        if (defined $maximum) {
            $description .= "Maximum value $maximum.";
        } else {
            $description .= 'No maximum.';
        }
    } else {
        $description .= 'No limits.';
    }

    return $description;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::IntegerBehavior - Actions appropriate for an integer.


=head1 DESCRIPTION

Provides a standard set of functionality for an integer
L<Perl::Critic::PolicyParameter> so that the developer of a policy
does not have to provide it her/himself.

NOTE: Do not instantiate this class.  Use the singleton instance held
onto by L<Perl::Critic::PolicyParameter>.


=head1 METHODS

=over

=item C<initialize_parameter( $parameter, $specification )>

Plug in the functionality this behavior provides into the parameter,
based upon the configuration provided by the specification.

This behavior looks for two configuration items:

=over

=item integer_minimum

Optional.  The minimum acceptable value.  Inclusive.

=item integer_maximum

Optional.  The maximum acceptable value.  Inclusive.

=back

=item C<generate_parameter_description( $parameter )>

Create a description of the parameter, based upon the description on
the parameter itself, but enhancing it with information from this
behavior.

In this case, this means including the minimum and maximum values.

=back


=head1 AUTHOR

Elliot Shank <perl@galumph.org>

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
