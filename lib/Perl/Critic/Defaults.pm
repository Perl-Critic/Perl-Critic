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
    my $key = undef;

    # Multi-value defaults
    my $exclude = _default( 'exclude', q{}, %args );
    $self->{_exclude}    = [ split m/\s+/mx, $exclude ];
    my $include = _default( 'include', q{}, %args );
    $self->{_include}    = [ split m/\s+/mx, $include ];

    # Single-value defaults
    $self->{_force}    = _default('force',    $FALSE,            %args);
    $self->{_only}     = _default('only',     $FALSE,            %args);
    $self->{_severity} = _default('severity', $SEVERITY_HIGHEST, %args);
    $self->{_theme}    = _default('theme',    $EMPTY,            %args);
    $self->{_top}      = _default('top',      $FALSE,            %args);
    $self->{_verbose}  = _default('verbose',  3,                 %args);

    return $self;
}

#-----------------------------------------------------------------------------

sub _default {
    my ($key_name, $default, %args) = @_;
    $key_name = _kludge( $key_name, %args );
    return $key_name ? $args{$key_name} : $default;
}

sub _kludge {
    my ($key, %args) = @_;
    return          if not defined $key;
    return $key     if defined $args{$key};
    return "-$key"  if defined $args{"-$key"};
    return "--$key" if defined $args{"--$key"};
    return; # Key does not exist
}

#-----------------------------------------------------------------------------
# Public ACCESSOR methods

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
