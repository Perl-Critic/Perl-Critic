##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::UserProfile;

use strict;
use warnings;
use Carp qw(carp croak confess);
use Config::Tiny qw();
use English qw(-no_match_vars);
use File::Spec qw();
use Perl::Critic::Defaults qw();
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
    $self->_load_profile( $args{-profile}   || _find_profile_path() );
    $self->_set_defaults();
    return $self;
}

#-----------------------------------------------------------------------------

sub defaults {

    my ($self) = @_;
    return $self->{_defaults};
}

#-----------------------------------------------------------------------------

sub policy_params {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );

    return $profile->{$short_name}    || $profile->{$long_name}     ||
           $profile->{"-$short_name"} || $profile->{"-$long_name"}  || {};
}

#-----------------------------------------------------------------------------

sub policy_is_disabled {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );
    return exists $profile->{"-$short_name"} || exists $profile->{"-$long_name"};
}

#-----------------------------------------------------------------------------

sub policy_is_enabled {

    my ( $self, $policy ) = @_;
    my $profile = $self->{_profile};
    my $long_name  = ref $policy || policy_long_name( $policy );
    my $short_name = policy_short_name( $long_name );
    return exists $profile->{$short_name} || exists $profile->{$long_name};
}

#-----------------------------------------------------------------------------
# Begin PRIVATE methods

sub _load_profile {

    my ($self, $profile) = @_;

    # "NONE" means don't load any profile
    if (defined $profile && $profile eq 'NONE') {
        $self->{_profile} = {};
        return $self;
    }

    my %loader_for = (
        ARRAY   => \&_load_profile_from_array,
        DEFAULT => \&_load_profile_from_file,
        HASH    => \&_load_profile_from_hash,
        SCALAR  => \&_load_profile_from_string,
    );

    my $ref_type = ref $profile || 'DEFAULT';
    my $loader = $loader_for{$ref_type};
    confess qq{Can't load UserProfile from type "$ref_type"} if ! $loader;
    $self->{_profile} = $loader->($profile);
    return $self;
}

#-----------------------------------------------------------------------------

sub _set_defaults {
    my ($self) = @_;
    my $profile = $self->{_profile};
    my $defaults = $profile->{_} || {};
    $self->{_defaults} = Perl::Critic::Defaults->new( %{ $defaults } );
    return $self;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_file {
    my $file = shift || return {};
    my $prof = Config::Tiny->read($file);
    if (defined $prof) {
        return $prof;
    } else {
        croak(sprintf qq{Config::Tiny could not parse profile '%s':\n\t%s\n},
              $file, Config::Tiny::errstr());
    }
}

#-----------------------------------------------------------------------------

sub _load_profile_from_array {
    my $array_ref = shift;
    my $joined    = join qq{\n}, @{ $array_ref };
    my $prof = Config::Tiny->read_string( $joined );
    croak( 'Profile error: ' . Config::Tiny::errstr() ) if not defined $prof;
    return $prof;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_string {
    my $string = shift;
    my $prof = Config::Tiny->read_string( ${ $string } );
    croak( 'Profile error: ' . Config::Tiny::errstr() ) if not defined $prof;
    return $prof;
}

#-----------------------------------------------------------------------------

sub _load_profile_from_hash {
    my $hash_ref = shift;
    return $hash_ref;
}

#-----------------------------------------------------------------------------

sub _find_profile_path {

    #Define default filename
    my $rc_file = '.perlcriticrc';

    #Check explicit environment setting
    return $ENV{PERLCRITIC} if exists $ENV{PERLCRITIC};

    #Check current directory
    return $rc_file if -f $rc_file;

    #Check home directory
    if ( my $home_dir = _find_home_dir() ) {
        my $path = File::Spec->catfile( $home_dir, $rc_file );
        return $path if -f $path;
    }

    #No profile defined
    return;
}

#-----------------------------------------------------------------------------

sub _find_home_dir {

    #Try using File::HomeDir
    eval { require File::HomeDir };
    if ( not $EVAL_ERROR ) {
        return File::HomeDir->my_home();
    }

    #Check usual environment vars
    for my $key (qw(HOME USERPROFILE HOMESHARE)) {
        next if not defined $ENV{$key};
        return $ENV{$key} if -d $ENV{$key};
    }

    #No home directory defined
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords UserProfile

=head1 NAME

Perl::Critic::UserProfile - Interface to the user's profile

=head1 DESCRIPTION

This is a helper class that encapsulates the contents of the user's
profile, which is usually stored in a F<.perlcriticrc> file. There are
no user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C< new( -profile => $p ) >

B<-profile> is the path to the user's profile.  If -profile is not
defined, then it looks for the profile at F<./.perlcriticrc> and then
F<$HOME/.perlcriticrc>.  If neither of those files exists, then the
UserProfile is created with default values.

=back

=head1 METHODS

=over 8

=item C< defaults() >

Returns the L<Perl::Critic::Defaults> object for this UserProfile.

=item C< policy_is_disabled( $policy ) >

Given a reference to a L<Perl::Critic::Policy> object or the name of
one, returns true if the user has disabled that policy in their
profile.

=item C< policy_is_enabled( $policy ) >

Given a reference to a L<Perl::Critic::Policy> object or the name of
one, returns true if the user has explicitly enabled that policy in
their user profile.

=item C< policy_params() >

Given a reference to a L<Perl::Critic::Policy> object or the name of
one, returns a hash of the user's configuration parameters for that
policy.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 expandtab
