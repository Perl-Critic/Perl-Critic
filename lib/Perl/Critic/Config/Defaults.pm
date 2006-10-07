##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::Config::Defaults;

use strict;
use warnings;
use Carp qw(cluck);
use English qw(-no_match_vars);
use Perl::Critic::Utils;

our $VERSION = 0.20;

#-----------------------------------------------------------------------------

my %valid_switches = hashify( qw(-severity -themes -include -exclude) );

#-----------------------------------------------------------------------------

sub new {

    my ($class, %defaults) = @_;
    my $self = bless {}, $class;
    _validate_defaults( %defaults );

    $self->{_severity}   = $defaults{-severity} || $SEVERITY_HIGHEST;
    $self->{_themes}     = $defaults{-themes}   || [];
    $self->{_exclude}    = $defaults{-exclude}  || [];
    $self->{_include}    = $defaults{-include}  || [];

    return $self;
}

#-----------------------------------------------------------------------------

sub default_severity {
    my ($self) = @_;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub default_themes {
    my ($self) = @_;
    return $self->{_themes};
}

#-----------------------------------------------------------------------------

sub default_exclude {
    my ($self) = @_;
    return $self->{_exclude};
}

#-----------------------------------------------------------------------------

sub default_include {
    my ($self) = @_;
    return $self->{_include};
}

#-----------------------------------------------------------------------------

sub _validate_defaults {
    my (%defaults) = @_;
    for my $switch ( keys %defaults ) {
        cluck qq{Invalid switch "$switch"} if not $valid_switches{$switch};
    }
    return;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Config::Defaults - Manage defaults for Perl::Critic

=head1 DESCRIPTION

This is a helper class that encapsulates the default parameters for
constructing a L<Perl::Critic::Config> object.  There are no
user-servicable parts here.

=head1 METHODS

=over 8

=item C<new>

=item C<default_severity>

=item C<default_include>

=item C<default_exclude>

=item C<default_themes>

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
