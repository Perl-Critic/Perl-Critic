package Perl::Critic::PolicyParameter::Behavior::Enumeration;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Exception::Fatal::PolicyDefinition
    qw{ &throw_policy_definition };
use Perl::Critic::Utils qw{ :characters &words_from_string &hashify };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    my $valid_values = $specification->{enumeration_values}
        or throw_policy_definition
            'No enumeration_values given for '
                . $parameter->get_name()
                . $PERIOD;
    ref $valid_values eq 'ARRAY'
        or throw_policy_definition
            'The value given for enumeration_values for '
                . $parameter->get_name()
                . ' is not an array reference.';
    scalar @{$valid_values} > 1
        or throw_policy_definition
            'There were not at least two valid values given for'
                . ' enumeration_values for '
                . $parameter->get_name()
                . $PERIOD;

    # Unfortunately, this has to be a reference, rather than a regular hash,
    # due to a problem in Devel::Cycle
    # (http://rt.cpan.org/Ticket/Display.html?id=25360) which causes
    # t/92_memory_leaks.t to fall over.
    my $value_lookup = { hashify( @{$valid_values} ) };
    $parameter->_get_behavior_values()->{enumeration_values} = $value_lookup;

    my $allow_multiple_values =
        $specification->{enumeration_allow_multiple_values};

    if ($allow_multiple_values) {
        $parameter->_set_parser(
            sub {
                # Normally bad thing, obscuring a variable in a outer scope
                # with a variable with the same name is being done here in
                # order to remain consistent with the parser function interface.
                my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

                my @potential_values;
                my $value_string = $parameter->get_default_string();

                if (defined $config_string) {
                    $value_string = $config_string;
                }

                if ( defined $value_string ) {
                    @potential_values = words_from_string($value_string);

                    my @bad_values =
                        grep { not exists $value_lookup->{$_} } @potential_values;
                    if (@bad_values) {
                        $policy->throw_parameter_value_exception(
                            $parameter->get_name(),
                            $value_string,
                            undef,
                            q{contains invalid values: }
                                . join (q{, }, @bad_values)
                                . q{. Allowed values are: }
                                . join (q{, }, sort keys %{$value_lookup})
                                . qq{.\n},
                        );
                    }
                }

                my %actual_values = hashify(@potential_values);

                $policy->__set_parameter_value($parameter, \%actual_values);

                return;
            }
        );
    } else {
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

                if (
                        defined $value_string
                    and $EMPTY ne $value_string
                    and not defined $value_lookup->{$value_string}
                ) {
                    $policy->throw_parameter_value_exception(
                        $parameter->get_name(),
                        $value_string,
                        undef,
                        q{is not one of the allowed values: }
                            . join (q{, }, sort keys %{$value_lookup})
                            . qq{.\n},
                    );
                }

                $policy->__set_parameter_value($parameter, $value_string);

                return;
            }
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    my $description = $parameter->_get_description_with_trailing_period();
    if ( $description ) {
        $description .= qq{\n};
    }

    my %values = %{$parameter->_get_behavior_values()->{enumeration_values}};
    return
        $description
        . 'Valid values: '
        . join (', ', sort keys %values)
        . $PERIOD;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::Behavior::Enumeration - Actions appropriate for an enumerated value.


=head1 DESCRIPTION

Provides a standard set of functionality for an enumerated
L<Perl::Critic::PolicyParameter|Perl::Critic::PolicyParameter> so that
the developer of a policy does not have to provide it her/himself.

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

=item enumeration_values

Mandatory.  The set of valid values for the parameter, as an array
reference.


=item enumeration_allow_multiple_values

Optional, defaults to false.  Should the parameter support a single
value or accept multiple?


=back


=item C<generate_parameter_description( $parameter )>

Create a description of the parameter, based upon the description on
the parameter itself, but enhancing it with information from this
behavior.

In this specific case, the universe of values is added at the end.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Elliot Shank.

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
