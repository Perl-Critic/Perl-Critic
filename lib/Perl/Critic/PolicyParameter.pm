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

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

# Grrr... one of the OO limitations of Perl: you can't put references to
# subclases in a superclass.  This map and method belong in Behavior.pm.
my %_behaviors =
    (
        'boolean'     => Perl::Critic::PolicyParameter::BooleanBehavior->new(),
        'enumeration' => Perl::Critic::PolicyParameter::EnumerationBehavior->new(),
    );

sub _get_behavior_for_name {
    my $behavior_name = shift;

    my $behavior = $_behaviors{$behavior_name}
        or confess qq{There's no "$behavior_name" behavior.};

    return $behavior
}

#-----------------------------------------------------------------------------

sub new {
    my ($class, $policy, $specification) = @_;
    my $self = bless {}, $class;

    defined $policy
        or confess
            'Attempt to create a ', __PACKAGE__, ' without a policy.';
    defined $specification
        or confess
            'Attempt to create a ', __PACKAGE__, ' without a specification.';

    $self->{_policy} = $policy;

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

# See if the policy has specified a behavior, and if so, let the behavior
# plug in its implementations of parser, etc.
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

    $self->_set_description($specification->{description});
    $self->_set_default_string($specification->{default_string});

    # TODO: What is this?
    if ( exists $specification->{default} ) {
        $self->_set_default($specification->{default});
    }

    $self->_set_parser($specification->{parser});

    return;
}

#-----------------------------------------------------------------------------

sub get_name {
    my $self = shift;

    return $self->{_name};
}

#-----------------------------------------------------------------------------

sub get_policy {
    my $self = shift;

    return $self->{_policy};
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

sub _get_default {
    my $self = shift;

    return $self->{_default};
}

sub _set_default {
    my ($self, $new_value) = @_;

    $self->{_default} = $new_value;

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

sub get_config_value {
    my ($self, %config) = @_;

    my $config_string = $config{$self->get_name()};
    if ( not defined $config_string ) {
        return $self->_get_default();
    }

    my $parser = _get_parser();
    if ($parser) {
        return $parser->($config_string)
    }

    return $self->_get_default();
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::PolicyParameter - Metadata about a parameter for a Policy.

=head1 DESCRIPTION



=head1 METHODS


=head1 DOCUMENTATION


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
