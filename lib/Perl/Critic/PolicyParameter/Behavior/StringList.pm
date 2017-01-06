package Perl::Critic::PolicyParameter::Behavior::StringList;

use 5.006001;
use strict;
use warnings;

use Perl::Critic::Utils qw{ :characters &words_from_string &hashify };

use base qw{ Perl::Critic::PolicyParameter::Behavior };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

sub initialize_parameter {
    my ($self, $parameter, $specification) = @_;

    # Unfortunately, this has to be kept as a reference, rather than a regular
    # array, due to a problem in Devel::Cycle
    # (http://rt.cpan.org/Ticket/Display.html?id=25360) which causes
    # t/92_memory_leaks.t to fall over.
    my $always_present_values = $specification->{list_always_present_values};
    $parameter->_get_behavior_values()->{always_present_values} =
        $always_present_values;

    if ( not $always_present_values ) {
        $always_present_values = [];
    }

    $parameter->_set_parser(
        sub {
            # Normally bad thing, obscuring a variable in a outer scope
            # with a variable with the same name is being done here in
            # order to remain consistent with the parser function interface.
            my ($policy, $parameter, $config_string) = @_;  ## no critic(Variables::ProhibitReusedNames)

            my @values = @{$always_present_values};
            my $value_string = $parameter->get_default_string();

            if (defined $config_string) {
                $value_string = $config_string;
            }

            if ( defined $value_string ) {
                push @values, words_from_string($value_string);
            }

            my %values = hashify(@values);

            $policy->__set_parameter_value($parameter, \%values);

            return;
        }
    );

    return;
}

#-----------------------------------------------------------------------------

sub generate_parameter_description {
    my ($self, $parameter) = @_;

    my $always_present_values =
        $parameter->_get_behavior_values()->{always_present_values};

    my $description = $parameter->_get_description_with_trailing_period();
    if ( $description and $always_present_values ) {
        $description .= qq{\n};
    }

    if ( $always_present_values ) {
        $description .= 'Values that are always included: ';
        $description .= join ', ', sort @{ $always_present_values };
        $description .= $PERIOD;
    }

    return $description;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::PolicyParameter::Behavior::StringList - Actions appropriate for a parameter that is a list of strings.


=head1 DESCRIPTION

Provides a standard set of functionality for a string list
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

This behavior looks for one configuration item:

=over

=item always_present_values

Optional.  Values that should always be included, regardless of what
the configuration of the parameter specifies, as an array reference.

=back

=item C<generate_parameter_description( $parameter )>

Create a description of the parameter, based upon the description on
the parameter itself, but enhancing it with information from this
behavior.

In this specific case, the always present values are added at the end.

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
