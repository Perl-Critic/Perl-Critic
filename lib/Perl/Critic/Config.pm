#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Config;

use strict;
use warnings;
use File::Spec;
use Config::Tiny;
use English qw(-no_match_vars);
use List::MoreUtils qw(any none);
use Perl::Critic::Utils;
use Carp qw(carp croak);

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

# Globals.  Ick!
my $NAMESPACE = $EMPTY;
my @SITE_POLICIES = ();

#-------------------------------------------------------------------------

sub import {

    my ( $class, %args ) = @_;
    $NAMESPACE = $args{-namespace} || 'Perl::Critic::Policy';

    eval {
        require Module::Pluggable;
        Module::Pluggable->import( search_path => $NAMESPACE, require => 1);
        @SITE_POLICIES = plugins();  #Exported by  Module::Pluggable
    };


    if ( $EVAL_ERROR ) {
        croak qq{Can't load Policies from namespace '$NAMESPACE': $EVAL_ERROR};
    }
    elsif ( ! @SITE_POLICIES ) {
        carp qq{No Policies found in namespace '$NAMESPACE'};
    }

    return 1;
}

#-------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_policies}  = [];

    # Set defaults
    my $profile_path = $args{-profile}   || $EMPTY;
    my $min_severity = $args{-severity}  || $SEVERITY_HIGHEST;
    my $excludes_ref = $args{-exclude}   || [];  #empty array
    my $includes_ref = $args{-include}   || [];  #empty array


    # Allow null config.  This is useful for testing
    return $self if $profile_path eq 'NONE';

    # Load user's profile, then filter and create Policies
    my $profile_ref = _load_profile( $profile_path ) || {};
    my $merged_ref  = _merge_profile( $profile_ref );

    while ( my ( $policy, $params ) = each %{ $merged_ref } ) {

        # Screen against include and exclude patterns.
        # Note that the exclusions have higher precedence.
        next if any  { $policy =~ m{ $_ }imx } @{ $excludes_ref };
        next if none { $policy =~ m{ $_ }imx } @{ $includes_ref };

        # Determine severity
        # TODO: This is awkward to read.  Consider revising
        my $default_severity = $policy->severity();
        my $user_severity    = $params->{severity} || $default_severity;
        next if $user_severity < $min_severity;

        if ( $default_severity != $user_severity ) {
            _redefine_severity( $policy, $user_severity );
        }

        # Finally, create Policy
        $self->add_policy( -policy => $policy, -config => $params );
    }

    #All done!
    return $self;
}

#------------------------------------------------------------------------

sub add_policy {

    my ( $self, %args ) = @_;
    my $policy      = $args{-policy} || return;
    my $config      = $args{-config} || {};
    my $module_name = _long_name($policy, $NAMESPACE);

    eval {
        my $policy_obj  = $module_name->new( %{$config} );
        push @{ $self->{_policies} }, $policy_obj;
    };

    if ($EVAL_ERROR) {
        carp qq{Failed to create polcy '$policy': $EVAL_ERROR};
        return;
    }

    return $self;
}

#------------------------------------------------------------------------

sub policies {
    my $self = shift;
    return $self->{_policies};
}

#------------------------------------------------------------------------
# Begin PRIVATE methods

sub _load_profile {

    my $profile = shift || $EMPTY;
    my $ref_type = ref $profile || 'DEFAULT';

    my %handlers = (
        SCALAR  => \&_load_from_string,
        ARRAY   => \&_load_from_array,
        HASH    => \&_load_from_hash,
        DEFAULT => \&_load_from_file,
    );

    my $handler_ref = $handlers{$ref_type};
    croak qq{Can't create Config from $ref_type} if ! $handler_ref;
    return $handler_ref->($profile);
}

sub _merge_profile {

    my $profile_ref = shift || {};

    my %merged = ();
    for my $policy ( @SITE_POLICIES ) {
        my $short_name = _short_name($policy, $NAMESPACE);
        next if exists $profile_ref->{"-$short_name"};
        my $params = $profile_ref->{$short_name} || {};
	$merged{ $policy } = $params;
    }

    return \%merged;
}

#------------------------------------------------------------------------

sub _load_from_file {
    my $file = shift;
    $file ||= find_profile_path() || return {};
    croak qq{'$file' is not a file} if ! -f $file;
    return Config::Tiny->read($file);
}

#------------------------------------------------------------------------

sub _load_from_array {
    my $array_ref = shift;
    my $joined    = join qq{\n}, @{ $array_ref };
    return Config::Tiny->read_string( $joined );
}

#------------------------------------------------------------------------

sub _load_from_string {
    my $string = shift;
    return Config::Tiny->read_string( ${ $string } );
}

#------------------------------------------------------------------------

sub _load_from_hash {
    my $hash_ref = shift;
    return $hash_ref;
}

#-----------------------------------------------------------------------------

sub _long_name {
    my ($module_name, $namespace) = @_;
    if ( $module_name !~ m{ \A $namespace }mx ) {
        $module_name = $namespace . q{::} . $module_name;
    }
    return $module_name;
}

sub _short_name {
    my ($module_name, $namespace) = @_;
    $module_name =~ s{\A $namespace ::}{}mx;
    return $module_name;
}

#----------------------------------------------------------------------------

# This is a very sneaky way to override the default severity of each
# policy.  To make it simple for Policy module developers to declare
# the severity of their Policies, severity() is just a static method.
# But we can't just assign to it like you would do with an accessor
# method because it has no state.  Instead, we redefine with a new
# static method that returns the value specified by the user
# (i.e. from the .perlcriticrc).  I like this because it keeps the
# severity data inside the Policy module where other clients can
# easily access it (such as P::C::Violation).

sub _redefine_severity {
    my ( $policy, $severity ) = @_;
    no strict 'refs';
    no warnings 'redefine';
    my $code_ref = eval "sub {return $severity}";  ## no critic
    *{ $policy . '::severity' } = $code_ref;
    return 1;
}

#----------------------------------------------------------------------------
# Begin PUBLIC STATIC methods

sub find_profile_path {

    #Define default filename
    my $rc_file = '.perlcriticrc';

    #Check explicit environment setting
    return $ENV{PERLCRITIC} if exists $ENV{PERLCRITIC};

    #Check current directory
    return $rc_file if -f $rc_file;

    #Check usual environment vars
    for my $var (qw(HOME USERPROFILE HOMESHARE)) {
        next if ! defined $ENV{$var};
        my $path = File::Spec->catfile( $ENV{$var}, $rc_file );
        return $path if -f $path;
    }

    #No profile found!
    return;
}

#----------------------------------------------------------------------------

sub site_policies {
    return @SITE_POLICIES;
}


sub native_policies {
    return qw(
      Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr
      Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap
      Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction
      Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless
      Perl::Critic::Policy::CodeLayout::ProhibitHardTabs
      Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins
      Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists
      Perl::Critic::Policy::CodeLayout::RequireTrailingCommas
      Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse
      Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops
      Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls
      Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks
      Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks
      Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators
      Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles
      Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect
      Perl::Critic::Policy::Modules::ProhibitMultiplePackages
      Perl::Critic::Policy::Modules::ProhibitEvilModules
      Perl::Critic::Policy::Modules::RequireExplicitPackage
      Perl::Critic::Policy::Modules::RequireBarewordIncludes
      Perl::Critic::Policy::Modules::RequireVersionVar
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars
      Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
      Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting
      Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching
      Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms
      Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes
      Perl::Critic::Policy::TestingAndDebugging::RequirePackageStricture
      Perl::Critic::Policy::TestingAndDebugging::RequirePackageWarnings
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars
      Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators
      Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator
      Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator
      Perl::Critic::Policy::Variables::ProhibitLocalVars
      Perl::Critic::Policy::Variables::ProhibitPackageVars
      Perl::Critic::Policy::Variables::ProhibitPunctuationVars
    );
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Config - Find and load Perl::Critic user-preferences

=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic>.  The Config object defines which
Policy modules will be loaded into the Perl::Critic engine and how
they should be configured.  You should never really need to
instantiate Perl::Critic::Config directly as the L<Perl::Critic>
constructor will do it for you.

=head1 CONSTRUCTOR

=over 8

=item new ( [ -profile => $FILE, -severity => $N, -include => \@PATTERNS, -exclude => \@PATTERNS ] )

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
file can't be found, or if C<$FILE> is an empty string, then all the
modules found in the Perl::Critic::Policy namespace will be loaded
with their default configuration.  See L<"CONFIGURATION"> for more
information.

B<-severity> is the minimum severity level.  Only Policy modules that
have a severity greater than C<$N> will be loaded into this Config.
Severity values are integers ranging from 1 (least severe) to 5 (most
severe).  The default is 5.  For a given C<-profile>, decreasing the
C<-severity> will usually result in more Policy violations.  Users can
redefine the severity level for any Policy in their F<.perlcriticrc>
file.  See L<"CONFIGURATION"> for more information.

B<-include> is a reference to a list of string C<@PATTERNS>.  Only
Policies that match at least one C<m/$PATTERN/imx> will be loaded into
this Config.  Using the C<-include> option causes the <-severity>
option to be siltently ignored.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Any
Policy that matches at least one C<m/$PATTERN/imx> will not be loaded
into this Config.  Using the C<-exclude> option causes the <-severity>
option to be siltently ignored.  The C<-exclude> patterns are applied
before the <-include> patterns, therefore, the C<-exclude> patterns
take precedence if a Policy happens to match both patterns.

=back

=head1 METHODS

=over 8

=item add_policy( -policy => $policy_name, -config => \%config_hash )

Loads a Policy object and adds into this Config.  If the object
cannot be instantiated, it will throw a warning and return a false
value.  Otherwise, it returns a reference to this Config.  Arguments
are key-value pairs as follows:

B<-policy> is the name of a L<Perl::Critic::Policy> subclass
module.  The C<'Perl::Critic::Policy'> portion of the name can be
omitted for brevity.  This argument is required.

B<-config> is an optional reference to a hash of Policy configuration
parameters (Note that this is B<not> a Perl::Critic::Config object). The
contents of this hash reference will be passed into to the constructor
of the Policy module.  See the documentation in the relevant Policy
module for a description of the arguments it supports.

=item policies( void )

Returns a list containing references to all the Policy objects that
have been loaded into this Config.  Objects will be in the order that
they were loaded.

=back

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item find_profile_path( void )

Searches the C<PERLCRITIC> environment variable, the current
directory, and you home directory (in that order) for a
F<.perlcriticrc> file.  If the file is found, the full path is
returned.  Otherwise, returns undef;

=item site_policies( void )

Returns a list of all the Policy modules that are currently installed
in the Perl::Critic:Policy namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.

=item native_policies( void )

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
brevity, you can ommit the C<'Perl::Critic::Policy'> part of the
module name.  All Policy modules must be a subclass of
L<Perl::Critic::Policy>.

C<severity> is the level of importance you wish to assign to the
Policy.  All Policy modules are defined with a default severity value
ranging from 1 (least severe) to 5 (most severe).  However, you may
disagree with the default severity and choose to give it a higher or
lower severity, based on your own coding philosophy.
Perl::Critic::Config will only load Policy modules that have a
severity greater than the C<-severity> option that is given to the
constructor.

The remaining key-value pairs are configuration parameters for that
specific Policy and will be passed into the constructor of the
L<Perl::Critic::Policy> subclass.  The constructors for most Policy
modules do not support arguments, and those that do should have
reasonable defaults.  See the documentation on the appropriate Policy
module for more details.

By default, all the modules that are found in the Perl::Critic::Policy
namespace are loaded into the Config.  Rather than assign a severity
level to each Policy, you can simply "turn off" a Policy by prepending
a '-' to the name of the module in your configuration file.  In this
manner, the Policy will never be loaded, regardless of the
C<-severity> given to the Perl::Critic::Config constructor.


A simple configuration might look like this:

    #--------------------------------------------------------------
    # I think these are really important, so always load them

    [TestingAndDebugging::RequirePackageStricture]
    severity = 5

    [TestingAndDebugging::RequirePackageWarnings]
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

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
