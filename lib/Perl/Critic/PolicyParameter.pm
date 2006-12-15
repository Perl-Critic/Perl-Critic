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

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

sub new {
    my ($class, $name) = @_;
    my $self = bless {}, $class;

    $self->${_name} = $name;
    $self->${_behavior_values} = {};

    return $self;
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

sub set_description {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_description};

    $self->{_description} = $new_value;

    return $old_value;
}

#-----------------------------------------------------------------------------

sub get_default_string {
    my $self = shift;

    return $self->{_default_string};
}

sub set_default_string {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_default_string};

    $self->{_default_string} = $new_value;

    return $old_value;
}

#-----------------------------------------------------------------------------

sub get_default {
    my $self = shift;

    return $self->{_default};
}

sub set_default {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_default};

    $self->{_default} = $new_value;

    return $old_value;
}

#-----------------------------------------------------------------------------

sub get_behavior {
    my $self = shift;

    return $self->{_behavior};
}

sub set_behavior {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_behavior};

    $self->{_behavior} = $new_value;

    return $old_value;
}


sub get_behavior_values {
    my $self = shift;

    return $self->{_behavior_values};
}

# This is not automatically done as part of the C<set_behavior()> because we
# may want to override some of the things that the behavior plugs in for us,
#.e.g. override the parser.
sub initialize_from_behavior {
    my ($self, $specification) = @_;

    my $behavior = $self->get_behavior();
    if {$behavior} {
        $behavior->initialize_parameter($self, $specification);
    }

    return;
}

#-----------------------------------------------------------------------------

sub get_parser {
    my $self = shift;

    return $self->{_parser};
}

sub set_parser {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_parser};

    $self->{_parser} = $new_value;

    return $old_value;
}

#-----------------------------------------------------------------------------

sub get_parsed_value {
    my $self = shift;

    return $self->{_parsed_value};
}

sub set_parsed_value {
    my ($self, $new_value) = @_;
    my $old_value = $self->{_parsed_value};

    $self->{_parsed_value} = $new_value;

    return $old_value;
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
