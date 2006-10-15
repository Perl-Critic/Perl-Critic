##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::Defaults;

use strict;
use warnings;
use Carp qw(cluck);
use English qw(-no_match_vars);
use Perl::Critic::Utils;

our $VERSION = 0.21;

#-----------------------------------------------------------------------------

sub new {

    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;

    # Multi-value defaults
    $self->{_exclude}    = defined $args{-exclude} ?
                           [ split m/\s+/mx, $args{-exclude} ] :  [];
    $self->{_include}    = defined $args{-include} ?
                           [ split m/\s+/mx, $args{-include} ] :  [];
    # Single-value defaults
    $self->{_severity}   = $args{-severity} || $SEVERITY_HIGHEST;
    $self->{_theme}      = $args{-theme}    || $EMPTY;
    $self->{_top}        = $args{-top}      || $FALSE;
    $self->{_verbose}    = $args{-verbose}  || 3;

    # Switch-like defaults
    $self->{_force}      = exists $args{-force}   ? $TRUE : $FALSE;
    $self->{_nocolor}    = exists $args{-nocolor} ? $TRUE : $FALSE;
    $self->{_only}       = exists $args{-only}    ? $TRUE : $FALSE;

    return $self;
}

#-----------------------------------------------------------------------------

sub severity {
    my ($self) = @_;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub theme {
    my ($self) = @_;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub exclude {
    my ($self) = @_;
    return $self->{_exclude};
}

#-----------------------------------------------------------------------------

sub include {
    my ($self) = @_;
    return $self->{_include};
}

#-----------------------------------------------------------------------------

sub only {
    my ($self) = @_;
    return $self->{_only};
}

#-----------------------------------------------------------------------------

sub verbose {
    my ($self) = @_;
    return $self->{_verbose};
}

#-----------------------------------------------------------------------------

sub nocolor {
    my ($self) = @_;
    return $self->{_nocolor};
}

#-----------------------------------------------------------------------------

sub force {
    my ($self) = @_;
    return $self->{_force};
}

#-----------------------------------------------------------------------------

sub top {
    my ($self) = @_;
    return $self->{_top};
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Config::Defaults - Manage default settings for Perl::Critic

=head1 DESCRIPTION

This is a helper class that encapsulates the default parameters for
constructing a L<Perl::Critic::Config> object.  There are no
user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C< new( %DEFAULT_PARAMS ) >

=back

=head1 METHODS

=over 8

=item C< exclude() >

=item C< force() >

=item C< include() >

=item C< nocolor() >

=item C< only() >

=item C< severity() >

=item C< theme() >

=item C< top() >

=item C< verbose() >

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
