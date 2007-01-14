##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Defaults;

use strict;
use warnings;
use Carp qw(cluck);
use English qw(-no_match_vars);
use Perl::Critic::Utils;

our $VERSION = 1.00;

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
    $self->{_force}        = _default('force',        $FALSE,            %args);
    $self->{_only}         = _default('only',         $FALSE,            %args);
    $self->{_singlepolicy} = _default('singlepolicy', $EMPTY,            %args);
    $self->{_severity}     = _default('severity',     $SEVERITY_HIGHEST, %args);
    $self->{_theme}        = _default('theme',        $EMPTY,            %args);
    $self->{_top}          = _default('top',          $FALSE,            %args);
    $self->{_verbose}      = _default('verbose',      4,                 %args);

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

sub singlepolicy {
    my ($self) = @_;
    return $self->{_singlepolicy};
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

Perl::Critic::Defaults - Manage default settings for Perl::Critic

=head1 DESCRIPTION

This is a helper class that encapsulates the default parameters for
constructing a L<Perl::Critic::Config> object.  There are no
user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C< new( %DEFAULT_PARAMS ) >

Returns a reference to a new C<Perl::Critic::Defaults> object.  The
arguments are name-value pairs that correspond to the methods listed
below.

=back

=head1 METHODS

=over 8

=item C< exclude() >

Returns a reference to a list of the default exclusion patterns.  If
there are no default exclusion patterns, then the list will be empty.

=item C< force() >

Returns the default value of the C<force> flag (Either 1 or 0).

=item C< include() >

Returns a reference to a list of the default inclusion patterns.  If
there are no default exclusion patterns, then the list will be empty.

=item C< only() >

Returns the default value of the C<only> flag (Either 1 or 0).

=item C< singlepolicy() >

Returns the default single-policy pattern.  (As a string.)

=item C< severity() >

Returns the default C<severity> setting. (1..5).

=item C< theme() >

Returns the default C<theme> setting. (As a string).

=item C< top() >

Returns the default C<top> setting. (Either 0 or a positive integer).

=item C< verbose() >

Returns the default C<verbose> setting. (Either a number or format
string).

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
