##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::PolicyFactory;

use strict;
use warnings;
use Carp qw(carp confess);
use English qw(-no_match_vars);
use Perl::Critic::Utils;

our $VERSION = 0.21;

#-----------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;
    my $profile = $args{-profile};
    my $policy_names = $args{-policies} || [];
    for my $policy_name ( @{ $policy_names } ) {
        my $params = $profile->policy_params( $policy_name );
        my $policy = $self->create_policy( $policy_name, $params );
        push @{ $self->{_policies} }, $policy;
    }
    return $self;
}

#-----------------------------------------------------------------------------

sub create_policy {

    my ($self, $policy_name, $params) = @_;

    # Pull out base parameters
    my $user_severity   = $params->{severity};
    my $user_set_themes = $params->{set_themes};
    my $user_add_themes = $params->{add_themes};

    # Construct policy from remaining params
    my $policy = $policy_name->new( %{$params} );

    # Set base attributes on policy
    if ( defined $user_severity ) {
        my $normalized_severity = _normalize_severity( $user_severity );
        $policy->set_severity( $normalized_severity );
    }

    if ( defined $user_set_themes ) {
        my @set_themes = _parse_theme( $user_set_themes );
        $policy->set_themes( @set_themes );
    }

    if ( defined $user_add_themes ) {
        my @add_themes = _parse_theme( $user_add_themes );
        $policy->add_themes( @add_themes );
    }

    return $policy;
}

#-----------------------------------------------------------------------------

sub policies {
    my $self = shift;
    return @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub _normalize_severity {
    my $s = shift || return $SEVERITY_HIGHEST;
    $s = $s > $SEVERITY_HIGHEST ? $SEVERITY_HIGHEST : $s;
    $s = $s < $SEVERITY_LOWEST  ? $SEVERITY_LOWEST : $s;
    return $s;
}

#-----------------------------------------------------------------------------

sub _parse_theme {
    my $theme_string = shift;
    return sort split m{\s+}mx, $theme_string;
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::PolicyFactory - Instantiate Policy objects

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over 8

=item C< new( %DEFAULT_PARAMS ) >

=back

=head1 METHODS

=over 8

=item C< policies() >

=item C< create_policy() >

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
