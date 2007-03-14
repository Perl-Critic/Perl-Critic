##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyParameter;

use strict;
use warnings;
use Carp qw(confess);

use Perl::Critic::Utils;
use Perl::Critic::PolicyParameter::Behavior;
use Perl::Critic::PolicyParameter::BooleanBehavior;
use Perl::Critic::PolicyParameter::EnumerationBehavior;
use Perl::Critic::PolicyParameter::IntegerBehavior;
use Perl::Critic::PolicyParameter::StringBehavior;

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

# Grrr... one of the OO limitations of Perl: you can't put references to
# subclases in a superclass.  This map and method belong in Behavior.pm.
my %_behaviors =
    (
        'boolean'     => Perl::Critic::PolicyParameter::BooleanBehavior->new(),
        'enumeration' => Perl::Critic::PolicyParameter::EnumerationBehavior->new(),
        'integer'     => Perl::Critic::PolicyParameter::IntegerBehavior->new(),
        'string'      => Perl::Critic::PolicyParameter::StringBehavior->new(),
    );

sub _get_behavior_for_name {
    my $behavior_name = shift;

    my $behavior = $_behaviors{$behavior_name}
        or confess qq{There's no "$behavior_name" behavior.};

    return $behavior
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, $specification) = @_;
    my $self = bless {}, $class;

    defined $specification
        or confess
            'Attempt to create a ', __PACKAGE__, ' without a specification.';

    my $specification_type = ref $specification;
    if ( not $specification_type ) {
        $self->{_name} = $specification;

        return $self;
    }

    $specification_type eq 'HASH'
        or confess
            'Attempt to create a ',
            __PACKAGE__,
            " with a $specification_type as a specification.",
            ;

    defined $specification->{name}
        or confess 'Attempt to create a ', __PACKAGE__, ' without a name.';
    $self->{_name} = $specification->{name};

    $self->_initialize_from_behavior($specification);
    $self->_finish_initialization($specification);

    return $self;
}

# See if the specification includes a Behavior name, and if so, let the
# Behavior with that name plug in its implementations of parser, etc.
sub _initialize_from_behavior {
    my ($self, $specification) = @_;

    my $behavior_name = $specification->{behavior};
    if ($behavior_name) {
        my $behavior = _get_behavior_for_name($behavior_name);

        $self->{_behavior} = $behavior;
        $self->{_behavior_values} = {};

        $behavior->initialize_parameter($self, $specification);
    }

    return;
}

# Grab the rest of the values out of the specification, including overrides
# of what the Behavior specified.
sub _finish_initialization {
    my ($self, $specification) = @_;

    defined $specification->{description}
        or confess 'Attempt to create a ', __PACKAGE__,
                   ' without a description.';
    $self->_set_description($specification->{description});
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

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Metadata metadata

=head1 NAME

Perl::Critic::PolicyParameter - Metadata about a parameter for a Policy.


=head1 DESCRIPTION

A provider of validation and parsing of parameter values and metadata about
the parameter.


=head1 METHODS

=over

=item C<get_name()>

Return the name of the parameter.  This is the key that will be looked for in
the F<.perlcriticrc>.

=item C<get_description()>

Return an explanation of the significance of the parameter.

=item C<get_default_string()>

Return a representation of the default value of this parameter as it would
appear if it was specified in a F<.perlcriticrc> file.

=item C<parse_and_validate_config_value( $parser, $config )>

Extract the configuration value for this parameter from the overall
configuration and initialize the policy based upon it.

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
