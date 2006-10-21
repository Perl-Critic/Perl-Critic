##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##############################################################################

package Perl::Critic::Config;

use strict;
use warnings;
use Carp qw(confess);
use English qw(-no_match_vars);
use List::MoreUtils qw(any none);
use Scalar::Util qw(blessed);
use Perl::Critic::PolicyFactory;
use Perl::Critic::Theme qw();
use Perl::Critic::UserProfile qw();
use Perl::Critic::Utils;

our $VERSION = 0.21;


#-----------------------------------------------------------------------------
# Constructor

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;

    # Set some attributes
    my $p = $args{-profile};
    my $profile = Perl::Critic::UserProfile->new( -profile => $p );
    $self->{_exclude}  = $args{-exclude}  || $profile->defaults->exclude();
    $self->{_force}    = $args{-force}    || $profile->defaults->force();
    $self->{_include}  = $args{-include}  || $profile->defaults->include();
    $self->{_only}     = $args{-only}     || $profile->defaults->only();
    $self->{_severity} = $args{-severity} || $profile->defaults->severity();
    $self->{_top}      = $args{-top}      || $profile->defaults->top();
    $self->{_verbose}  = $args{-verbose}  || $profile->defaults->verbose();
    $self->{_profile}  = $profile;
    $self->{_policies} = [];

    # Construct PolicyFactory and get all the Policies
    my $factory = Perl::Critic::PolicyFactory->new( -profile  => $profile );
    my @policies = $factory->policies();

    #Construct Theme from the user's definition
    my $theme = $args{-theme} || $profile->defaults->theme();
    my $t = Perl::Critic::Theme->new( -theme => $theme, -policies => \@policies );
    $self->{_theme} = $t;

    # "NONE" means don't load any policies
    return $self if defined $p and $p eq 'NONE';

    $self->_load_policies( @policies );
    return $self;
}

#-----------------------------------------------------------------------------

sub add_policy {

    my ( $self, %args ) = @_;
    my $profile = $self->{_profile};
    my $policy  = $args{-policy} || confess q{The -policy argument is required};

    if ( blessed $policy ) {
        push @{ $self->{_policies} }, $policy;
        return $self;
    }

    # NOTE: The "-config" alias is supported for backward compatibility.
    my $params  = $args{-params} || $args{-config} || $profile->policy_params( $policy );

    # TODO: Use PolicyFactory::create_policy to instantiate the Policy.

    eval {
        my $policy_name = policy_long_name( $policy );
        my $policy_obj  = $policy_name->new( %{ $params } );
        push @{ $self->{_policies} }, $policy_obj;
    };

    # Failure to create a policy is now fatal!
    confess qq{Unable to create policy '$policy': $EVAL_ERROR} if $EVAL_ERROR;
    return $self;
}

#-----------------------------------------------------------------------------

sub _load_policies {

    my ( $self, @policies ) = @_;

    for my $policy ( @policies ) {

        my $load_me = $self->only() ? $FALSE : $TRUE;

        ##no critic (ProhibitPostfixControls)
        $load_me = $FALSE if $self->_policy_is_disabled( $policy );
        $load_me = $TRUE  if $self->_policy_is_enabled( $policy );
        $load_me = $FALSE if $self->_policy_is_unimportant( $policy );
        $load_me = $FALSE if not $self->_policy_is_thematic( $policy );
        $load_me = $TRUE  if $self->_policy_is_included( $policy );
        $load_me = $FALSE if $self->_policy_is_excluded( $policy );

        next if not $load_me;
        $self->add_policy( -policy => $policy );
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub _policy_is_disabled {
    my ($self, $policy) = @_;
    my $profile = $self->{_profile};
    return $profile->policy_is_disabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_enabled {
    my ($self, $policy) = @_;
    my $profile = $self->{_profile};
    return $profile->policy_is_enabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_thematic {
    my ($self, $policy) = @_;
    my $policy_name = ref $policy;
    return any { $policy_name eq $_ } $self->theme()->members();
}

#-----------------------------------------------------------------------------

sub _policy_is_unimportant {
    my ($self, $policy) = @_;
    my $policy_severity = $policy->get_severity();
    my $min_severity    = $self->{_severity};
    return $policy_severity < $min_severity;
}

#-----------------------------------------------------------------------------

sub _policy_is_included {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @inclusions  = $self->include();
    return any { $policy_long_name =~ m/$_/imx } @inclusions;
}

#-----------------------------------------------------------------------------

sub _policy_is_excluded {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @exclusions  = $self->exclude();
    return any { $policy_long_name =~ m/$_/imx } @exclusions;
}

#------------------------------------------------------------------------
# Begin ACCESSSOR methods

sub policies {
    my $self = shift;
    return @{ $self->{_policies} };
}

#----------------------------------------------------------------------------

sub exclude {
    my $self = shift;
    return @{ $self->{_exclude} };
}

#----------------------------------------------------------------------------

sub force {
    my $self = shift;
    return $self->{_force};
}

#----------------------------------------------------------------------------

sub include {
    my $self = shift;
    return @{ $self->{_include} };
}

#----------------------------------------------------------------------------

sub only {
    my $self = shift;
    return $self->{_only};
}
#----------------------------------------------------------------------------

sub severity {
    my $self = shift;
    return $self->{_severity};
}

#----------------------------------------------------------------------------

sub theme {
    my $self = shift;
    return $self->{_theme};
}

#----------------------------------------------------------------------------

sub top {
    my $self = shift;
    return $self->{_top};
}

#----------------------------------------------------------------------------

sub verbose {
    my $self = shift;
    return $self->{_verbose};
}

#----------------------------------------------------------------------------

sub site_policy_names {
    return Perl::Critic::PolicyFactory::site_policy_names();
}

#----------------------------------------------------------------------------

sub native_policy_names {
    return Perl::Critic::PolicyFactory::native_policy_names();
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=for stopwords params

=head1 NAME

Perl::Critic::Config - Find and load Perl::Critic user-preferences

=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic>.  The Config object defines which
Policy modules will be loaded into the Perl::Critic engine and how
they should be configured.  You should never really need to
instantiate Perl::Critic::Config directly because the Perl::Critic
constructor will do it for you.

=head1 CONSTRUCTOR

=over 8

=item C<< new( [ -profile => $FILE, -severity => $N, -include => \@PATTERNS, -exclude => \@PATTERNS ] ) >>

Returns a reference to a new Perl::Critic::Config object, which is
basically just a blessed hash of configuration parameters.  There
aren't any special methods for getting and setting individual values,
so just treat it like an ordinary hash.  All arguments are optional
key-value pairs as follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not
defined, Perl::Critic::Config attempts to find a F<.perlcriticrc>
configuration file in the current directory, and then in your home
directory.  Alternatively, you can set the C<PERLCRITIC> environment
variable to point to a file in another location.  If a configuration
file can't be found, or if C<$FILE> is an empty string, then all
Policies will be loaded with their default configuration.  See
L<"CONFIGURATION"> for more information.

B<-severity> is the minimum severity level.  Only Policy modules that
have a severity greater than C<$N> will be loaded into this Config.
Severity values are integers ranging from 1 (least severe) to 5 (most
severe).  The default is 5.  For a given C<-profile>, decreasing the
C<-severity> will usually result in more Policy violations.  Users can
redefine the severity level for any Policy in their F<.perlcriticrc>
file.  See L<"CONFIGURATION"> for more information.

B<-include> is a reference to a list of string C<@PATTERNS>.  Policies
that match at least one C<m/$PATTERN/imx> will be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-exclude> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Polices
that match at least one C<m/$PATTERN/imx> will not be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-include> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

=back

=head1 METHODS

=over 8

=item C<< add_policy( -policy => $policy_name, -params => \%param_hash ) >>

Creates a Policy object and loads it into this Config.  If the object
cannot be instantiated, it will throw a fatal exception.  Otherwise,
it returns a reference to this Critic.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass
module.  The C<'Perl::Critic::Policy'> portion of the name can be
omitted for brevity.  This argument is required.

B<-params> is an optional reference to a hash of Policy parameters.
The contents of this hash reference will be passed into to the
constructor of the Policy module.  See the documentation in the
relevant Policy module for a description of the arguments it supports.

=item C< policies() >

Returns a list containing references to all the Policy objects that
have been loaded into this Config.  Objects will be in the order that
they were loaded.

=item C< exclude() >

=item C< force() >

=item C< include() >

=item C< only() >

=item C< severity() >

=item C< theme() >

=item C< top() >

=item C< verbose() >

=back

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item C<site_policy_names()>

Returns a list of all the Policy modules that are currently installed
in the Perl::Critic:Policy namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.

=item C<native_policy_names()>

Returns a list of all the Policy modules that have been distributed
with Perl::Critic.  Does not include any third-party modules.

=back

=head1 CONFIGURATION

The default configuration file is called F<.perlcriticrc>.
Perl::Critic::Config will look for this file in the current directory
first, and then in your home directory.  Alternatively, you can set
the PERLCRITIC environment variable to explicitly point to a different
file in another location.  If none of these files exist, and the
C<-profile> option is not given to the constructor, then all the
modules that are found in the Perl::Critic::Policy namespace will be
loaded with their default configuration.

The format of the configuration file is a series of named sections
that contain key-value pairs separated by '='. Comments should
start with '#' and can be placed on a separate line or after the
name-value pairs if you desire.  The general recipe is a series of
blocks like this:

    [Perl::Critic::Policy::Category::PolicyName]
    severity = 1
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Policy::Category::PolicyName> is the full name of a
module that implements the policy.  The Policy modules distributed
with Perl::Critic have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can omit the C<'Perl::Critic::Policy'> part of the
module name.

C<severity> is the level of importance you wish to assign to the
Policy.  All Policy modules are defined with a default severity value
ranging from 1 (least severe) to 5 (most severe).  However, you may
disagree with the default severity and choose to give it a higher or
lower severity, based on your own coding philosophy.

The remaining key-value pairs are configuration parameters that will
be passed into the constructor of that Policy.  The constructors for
most Policy modules do not support arguments, and those that do should
have reasonable defaults.  See the documentation on the appropriate
Policy module for more details.

Instead of redefining the severity for a given Policy, you can
completely disable a Policy by prepending a '-' to the name of the
module in your configuration file.  In this manner, the Policy will
never be loaded, regardless of the C<-severity> given to the
Perl::Critic::Config constructor.

A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequireUseStrict]
    severity = 5

    [TestingAndDebugging::RequireUseWarnings]
    severity = 5

    #--------------------------------------------------------------
    # I think these are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    severity = 2

    [ControlStructures::ProhibitPostfixControls]
    allow = if unless  #A policy-specific configuration
    severity = 2

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity,
    # so no additional configuration is required for them.

A few sample configuration files are included in this distribution
under the F<t/samples> directory. The F<perlcriticrc.none> file
demonstrates how to disable Policy modules.  The
F<perlcriticrc.levels> file demonstrates how to redefine the severity
level for any given Policy module.  The F<perlcriticrc.pbp> file
configures Perl::Critic to load only Policies described in Damian
Conway's book "Perl Best Practices."

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
