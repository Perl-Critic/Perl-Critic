##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PolicyFactory;

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars);
use File::Spec::Unix qw();
use List::MoreUtils qw(any);
use Perl::Critic::Utils;

our $VERSION = 1.00;

#-----------------------------------------------------------------------------

# Globals.  Ick!
my @SITE_POLICY_NAMES = ();

#-----------------------------------------------------------------------------

sub import {

    my ( $class, %args ) = @_;
    my $test_mode = $args{-test};

    if ( not @SITE_POLICY_NAMES ) {
        eval {
            require Module::Pluggable;
            Module::Pluggable->import(search_path => $POLICY_NAMESPACE,
                                      require => 1, inner => 0);
            @SITE_POLICY_NAMES = plugins(); #Exported by Module::Pluggable
        };

        if ( $EVAL_ERROR ) {
            confess qq{Can't load Policies from namespace '$POLICY_NAMESPACE': $EVAL_ERROR};
        }
        elsif ( ! @SITE_POLICY_NAMES ) {
            confess qq{No Policies found in namespace '$POLICY_NAMESPACE'};
        }
    }

    # In test mode, only load native policies, not third-party ones
    if ( $test_mode && any {m/\b blib \b/xms} @INC ) {
        @SITE_POLICY_NAMES = _modules_from_blib( @SITE_POLICY_NAMES );
    }

    return 1;
}

#-----------------------------------------------------------------------------
# Some static helper subs

sub _modules_from_blib {
    my (@modules) = @_;
    return grep { _was_loaded_from_blib( _module2path($_) ) } @modules;
}

sub _module2path {
    my $module = shift || return;
    return File::Spec::Unix->catdir(split m/::/xms, $module) . '.pm';
}

sub _was_loaded_from_blib {
    my $path = shift || return;
    my $full_path = $INC{$path};
    return $full_path && $full_path =~ m/\b blib \b/xms;
}

#-----------------------------------------------------------------------------
# Constructor

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_policies} = [];
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;
    my $profile = $args{-profile} || confess q{The -profile argument is required};

    for my $policy_name ( @SITE_POLICY_NAMES ) {
        my $policy_params = $profile->policy_params( $policy_name );
        my $policy = $self->create_policy( -name   => $policy_name,
                                           -params => $policy_params );
        push @{ $self->{_policies} }, $policy;
    }
    return $self;
}

#-----------------------------------------------------------------------------

sub create_policy {

    my ($self, %args ) = @_;
    my $policy_params = $args{-params};
    my $policy_name = $args{-name} || confess q{The -name argument is required};
    $policy_name = policy_long_name( $policy_name );

    # This function will delete keys from $policy_params, so we copy them to
    # avoid modifying the callers's hash.  What a pain in the ass!
    my %policy_params_copy = $policy_params ? %{$policy_params} : ();

    # Pull out base parameters.
    my $user_set_themes = delete $policy_params_copy{set_themes};
    my $user_add_themes = delete $policy_params_copy{add_themes};
    my $user_severity   = delete $policy_params_copy{severity};

    # Validate remaining parameters. This dies on failure
    _validate_policy_params( $policy_name, \%policy_params_copy );

    # Construct policy from remaining params
    my $policy = $policy_name->new( %policy_params_copy );

    # Set base attributes on policy
    if ( defined $user_severity ) {
        my $normalized_severity = severity_to_number( $user_severity );
        $policy->set_severity( $normalized_severity );
    }

    if ( defined $user_set_themes ) {
        my @set_themes = words_from_string( $user_set_themes );
        $policy->set_themes( @set_themes );
    }

    if ( defined $user_add_themes ) {
        my @add_themes = words_from_string( $user_add_themes );
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

sub site_policy_names {
    return @SITE_POLICY_NAMES;
}

#-----------------------------------------------------------------------------

sub _validate_policy_params {
    my ($policy, $params) = @_;

    # If the Policy author hasn't provided the "supported_parameters" method,
    # then we can't tell which parameters it supports.  So we let it go.
    return if not $policy->can('supported_parameters');
    my @supported_params = $policy->supported_parameters();

    my %is_supported = hashify( @supported_params );
    my $msg = $EMPTY;

    for my $offered_param ( keys %{ $params } ) {
        if ( not defined $is_supported{$offered_param} ) {
            $msg .= qq{Parameter "$offered_param" isn't supported by $policy\n};
        }
    }

    die "$msg\n" if $msg;
    return 1;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords PolicyFactory -params

=head1 NAME

Perl::Critic::PolicyFactory - Instantiate Policy objects

=head1 DESCRIPTION

This is a helper class that instantiates L<Perl::Critic::Policy> objects with
the user's preferred parameters. There are no user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C<< new( -profile => $profile >>

Returns a reference to a new Perl::Critic::PolicyFactory object.

B<-profile> is a reference to a L<Perl::Critic::UserProfile> object.  This
argument is required.

=back

=head1 METHODS

=over 8

=item C<< create_policy( -name => $policy_name, -params => \%param_hash ) >>

Creates one Policy object.  If the object cannot be instantiated, it will
throw a fatal exception.  Otherwise, it returns a reference to the new Policy
object.

B<-name> is the name of a L<Perl::Critic::Policy> subclass module.  The
C<'Perl::Critic::Policy'> portion of the name can be omitted for brevity.
This argument is required.

B<-params> is an optional reference to hash of parameters that will be passed
into the constructor of the Policy.  If C<-params> is not defined, we will use
the appropriate Policy parameters from the L<Perl::Critic::UserProfile>.

=item C< policies() >

Returns a list of of references to all the L<Perl::Critic::Policy> objects
that were created by this PolicyFactory.

=back

=head1 SUBROUTINES

Perl::Critic::PolicyFactory has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item C<site_policy_names()>

Returns a list of all the Policy modules that are currently installed in the
Perl::Critic:Policy namespace.  These will include modules that are
distributed with Perl::Critic plus any third-party modules that have been
installed.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
