package Perl::Critic::PolicyParameter::Behavior::Integer;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ :characters };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $minimum = $specification->{integer_minimum};
    my $maximum = $specification->{integer_maximum};

    $parameter->_get_behavior_values()->{minimum} = $minimum;
    $parameter->_get_behavior_values()->{maximum} = $maximum;

    $parameter->_set_parser(
        sub {
            # Normally bad thing, obscuring a variable in a outer scope
            # with a variable with the same name is being done here in
            # order to remain consistent with the parser function interface.
            my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

            my $value_string = $parameter->get_default_string();

            if (defined $config_string) {
                $value_string = $config_string;
            }

            my $value;
            if ( defined $value_string ) {
                if (
                        $value_string !~ m/ \A [-+]? [1-9] [\d_]* \z /xms
                    and $value_string ne '0'
                ) {
                    $policy->throw_parameter_value_exception(
                        $parameter->get_name(),
                        $value_string,
                        undef,
                        'does not look like an integer.',
                    );
                }

                $value_string =~ tr/_//d;
                $value = $value_string + 0;

                if ( defined $minimum and $minimum > $value ) {
                    $policy->throw_parameter_value_exception(
                        $parameter->get_name(),
                        $value_string,
                        undef,
                        qq{is less than $minimum.},
                    );
                }

                if ( defined $maximum and $maximum < $value ) {
                    $policy->throw_parameter_value_exception(
                        $parameter->get_name(),
                        $value_string,
                        undef,
                        qq{is greater than $maximum.},
                    );
                }
            }

            $policy->__set_parameter_value($parameter, $value);
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

Perl::Critic::PolicyParameter::Behavior::Integer - Actions appropriate for an integer parameter.


=head1 DESCRIPTION

Provides a standard set of functionality for an integer
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter> so that
the developer of a policy does not have to provide it her/himself.

The parser provided by this behavior allows underscores ("_") in input
values as in a Perl numeric literal.

NOTE: Do not instantiate this class.  Use the singleton instance held
onto by
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter>.


=head1 INTERFACE SUPPORT

This is considered to be a non-public class.  Its interface is subject
to change without notice.


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

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
