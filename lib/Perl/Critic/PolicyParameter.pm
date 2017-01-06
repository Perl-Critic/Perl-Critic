package Perl::Critic::PolicyParameter;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Exporter 'import';

Readonly::Array our @EXPORT_OK => qw{ $NO_DESCRIPTION_AVAILABLE };

use String::Format qw{ stringf };

use Perl::Critic::Exception::Fatal::PolicyDefinition
    qw{ throw_policy_definition };
use Perl::Critic::PolicyParameter::Behavior;
use Perl::Critic::PolicyParameter::Behavior::Boolean;
use Perl::Critic::PolicyParameter::Behavior::Enumeration;
use Perl::Critic::PolicyParameter::Behavior::Integer;
use Perl::Critic::PolicyParameter::Behavior::String;
use Perl::Critic::PolicyParameter::Behavior::StringList;

use Perl::Critic::Utils qw{ :characters &interpolate };
use Perl::Critic::Utils::DataConversion qw{ &defined_or_empty };

our $VERSION = '1.126';

Readonly::Scalar our $NO_DESCRIPTION_AVAILABLE => 'No description available.';

#-----------------------------------------------------------------------------

# Grrr... one of the OO limitations of Perl: you can't put references to
# subclases in a superclass (well, not nicely).  This map and method belong
# in Behavior.pm.
Readonly::Hash my %BEHAVIORS =>
    (
        'boolean'     => Perl::Critic::PolicyParameter::Behavior::Boolean->new(),
        'enumeration' => Perl::Critic::PolicyParameter::Behavior::Enumeration->new(),
        'integer'     => Perl::Critic::PolicyParameter::Behavior::Integer->new(),
        'string'      => Perl::Critic::PolicyParameter::Behavior::String->new(),
        'string list' => Perl::Critic::PolicyParameter::Behavior::StringList->new(),
    );

sub _get_behavior_for_name {
    my $behavior_name = shift;

    my $behavior = $BEHAVIORS{$behavior_name}
        or throw_policy_definition qq{There's no "$behavior_name" behavior.};

    return $behavior;
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, $specification) = @_;
    my $self = bless {}, $class;

    defined $specification
        or throw_policy_definition
            'Attempt to create a ', __PACKAGE__, ' without a specification.';

    my $behavior_specification;

    my $specification_type = ref $specification;
    if ( not $specification_type ) {
        $self->{_name} = $specification;

        $behavior_specification = {};
    } else {
        $specification_type eq 'HASH'
            or throw_policy_definition
                'Attempt to create a ',
                __PACKAGE__,
                " with a $specification_type as a specification.",
                ;

        defined $specification->{name}
            or throw_policy_definition
                'Attempt to create a ', __PACKAGE__, ' without a name.';
        $self->{_name} = $specification->{name};

        $behavior_specification = $specification;
    }

    $self->_initialize_from_behavior($behavior_specification);
    $self->_finish_standard_initialization($behavior_specification);

    return $self;
}

# See if the specification includes a Behavior name, and if so, let the
# Behavior with that name plug in its implementations of parser, etc.
sub _initialize_from_behavior {
    my ($self, $specification) = @_;

    my $behavior_name = $specification->{behavior};
    my $behavior;
    if ($behavior_name) {
        $behavior = _get_behavior_for_name($behavior_name);
    } else {
        $behavior = _get_behavior_for_name('string');
    }

    $self->{_behavior} = $behavior;
    $self->{_behavior_values} = {};

    $behavior->initialize_parameter($self, $specification);

    return;
}

# Grab the rest of the values out of the specification, including overrides
# of what the Behavior specified.
sub _finish_standard_initialization {
    my ($self, $specification) = @_;

    my $description =
        $specification->{description} || $NO_DESCRIPTION_AVAILABLE;
    $self->_set_description($description);
    $self->_set_default_string($specification->{default_string});

    $self->_set_parser($specification->{parser});

    return;
}

#-----------------------------------------------------------------------------

sub get_name {
    my $self = shift;

    return $self->{_name};
}

#-----------------------------------------------------------------------------

sub get_description {
    my $self = shift;

    return $self->{_description};
}

sub _set_description {
    my ($self, $new_value) = @_;

    return if not defined $new_value;
    $self->{_description} = $new_value;

    return;
}

sub _get_description_with_trailing_period {
    my $self = shift;

    my $description = $self->get_description();
    if ($description) {
        if ( $PERIOD ne substr $description, ( length $description ) - 1 ) {
            $description .= $PERIOD;
        }
    } else {
        $description = $EMPTY;
    }

    return $description;
}

#-----------------------------------------------------------------------------

sub get_default_string {
    my $self = shift;

    return $self->{_default_string};
}

sub _set_default_string {
    my ($self, $new_value) = @_;

    return if not defined $new_value;
    $self->{_default_string} = $new_value;

    return;
}

#-----------------------------------------------------------------------------

sub _get_behavior {
    my $self = shift;

    return $self->{_behavior};
}

sub _get_behavior_values {
    my $self = shift;

    return $self->{_behavior_values};
}

#-----------------------------------------------------------------------------

sub _get_parser {
    my $self = shift;

    return $self->{_parser};
}

sub _set_parser {
    my ($self, $new_value) = @_;

    return if not defined $new_value;
    $self->{_parser} = $new_value;

    return;
}

#-----------------------------------------------------------------------------

sub parse_and_validate_config_value {
    my ($self, $policy, $config) = @_;

    my $config_string = $config->{$self->get_name()};

    my $parser = $self->_get_parser();
    if ($parser) {
        $parser->($policy, $self, $config_string);
    }

    return;
}

#-----------------------------------------------------------------------------

sub generate_full_description {
    my ($self) = @_;

    return $self->_get_behavior()->generate_parameter_description($self);
}

#-----------------------------------------------------------------------------

sub _generate_full_description {
    my ($self, $prefix) = @_;

    my $description = $self->generate_full_description();

    if (not $description) {
        return $EMPTY;
    }

    if ($prefix) {
        $description =~ s/ ^ /$prefix/xmsg;
    }

    return $description;
}

#-----------------------------------------------------------------------------

sub to_formatted_string {
    my ($self, $format) = @_;

    my %specification = (
        n => sub { $self->get_name() },
        d => sub { defined_or_empty( $self->get_description() ) },
        D => sub { defined_or_empty( $self->get_default_string() ) },
        f => sub { $self->_generate_full_description(@_) },
    );

    return stringf( interpolate($format), %specification );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords parsable

=head1 NAME

Perl::Critic::PolicyParameter - Metadata about a parameter for a Policy.


=head1 DESCRIPTION

A provider of validation and parsing of parameter values and metadata
about the parameter.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<get_name()>

Return the name of the parameter.  This is the key that will be looked
for in the F<.perlcriticrc>.


=item C<get_description()>

Return an explanation of the significance of the parameter, as
provided by the developer of the policy.


=item C<get_default_string()>

Return a representation of the default value of this parameter as it
would appear if it was specified in a F<.perlcriticrc> file.


=item C<parse_and_validate_config_value( $parser, $config )>

Extract the configuration value for this parameter from the overall
configuration and initialize the policy based upon it.


=item C<generate_full_description()>

Produce a more complete explanation of the significance of this
parameter than the value returned by C<get_description()>.

If no description can be derived, returns the empty string.

Note that the result may contain multiple lines.


=item C<to_formatted_string( $format )>

Generate a string representation of this parameter, based upon the
format.

The format is a combination of literal and escape characters similar
to the way C<sprintf> works.  If you want to know the specific
formatting capabilities, look at L<String::Format|String::Format>.
Valid escape characters are:

=over

=item C<%n>

The name of the parameter.

=item C<%d>

The description, as supplied by the programmer.

=item C<%D>

The default value, in a parsable form.

=item C<%f>

The full description, which is an extension of the value returned by
C<%d>.  Takes a parameter of a prefix for the beginning of each line.


=back


=back


=head1 SEE ALSO

L<Perl::Critic::DEVELOPER/"MAKING YOUR POLICY CONFIGURABLE">


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
