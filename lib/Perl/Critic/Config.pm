#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Config;

use strict;
use warnings;
use Carp qw(carp confess);
use Config::Tiny qw();
use English qw(-no_match_vars);
use File::Spec qw();
use File::Spec::Unix qw();
use List::MoreUtils qw(any none);
use Scalar::Util qw(blessed);
use Perl::Critic::Utils;
use Perl::Critic::Config::Defaults;

our $VERSION = 0.21;

# Globals.  Ick!
my $NAMESPACE = $EMPTY;
my @SITE_POLICIES = ();
my $TEST_MODE = 0;

#-----------------------------------------------------------------------------

sub import {

    my ( $class, %args ) = @_;
    $NAMESPACE = $args{-namespace} || 'Perl::Critic::Policy';
    $TEST_MODE ||= $args{-test};

    eval {
        require Module::Pluggable;
        Module::Pluggable->import(search_path => $NAMESPACE,
                                  require => 1, inner => 0);
        @SITE_POLICIES = plugins(); #Exported by Module::Pluggable
    };

    if ( $EVAL_ERROR ) {
        confess qq{Can't load Policies from namespace '$NAMESPACE': $EVAL_ERROR};
    }
    elsif ( ! @SITE_POLICIES ) {
        carp qq{No Policies found in namespace '$NAMESPACE'};
    }

    # In test mode, only load native policies, not third-party ones
    if ( $TEST_MODE && any {m/\b blib \b/xms} @INC ) {
        @SITE_POLICIES = _modules_from_blib( @SITE_POLICIES );
    }

    return 1;
}

#---------------------------------------------------------------------------
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
    $self->{_exclude}  = [];
    $self->{_themes}   = [];
    $self->_init(%args);
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ($self, %args) = @_;

    # Locate the user's profile
    my $profile_path = $args{-profile} || find_profile_path();
    return $self if defined $profile_path && $profile_path eq 'NONE';
    $self->{_profile_path} = $profile_path;

    # Now load the profile
    $self->_load_profile();

    # Set attributes from arguments and defaults
    $self->_set_attributes( %args );

    # Load policies
    $self->_load_policies();

    #All done!
    return $self;
}

sub _load_policies {

    my ($self) = @_;

    for my $policy_name ( @SITE_POLICIES ) {

        my $params = $self->_get_policy_params( $policy_name );
        my $policy = $self->_create_policy( $policy_name, $params );
        my $load_me = $TRUE; #Assume policy should be loaded

        ##no critic (ProhibitPostfixControls)
        $load_me = $FALSE if $self->_policy_is_disabled( $policy );
        $load_me = $FALSE if $self->_policy_is_unimportant( $policy );
        $load_me = $FALSE if not $self->_policy_fits_themes( $policy );
        $load_me = $TRUE  if $self->_policy_is_included( $policy );
        $load_me = $FALSE if $self->_policy_is_excluded( $policy);

        next if not $load_me;
        $self->add_policy( -policy => $policy );
    }

    return $self;
}

#-----------------------------------------------------------------------------
# Factory method

sub _create_policy {
    my ($self, $policy_name, $params) = @_;

    # Pull out base parameters
    my $user_severity   = $params->{severity};
    my $user_set_themes = $params->{set_themes};
    my $user_add_themes = $params->{add_themes};

    # Construct policy from remaining params
    my $policy = $policy_name->new( %{$params} );

    # Set base attributes on policy
    if ( defined $user_severity ) {
        $policy->set_severity( $user_severity );
    }

    if ( defined $user_set_themes ) {
        my @user_set_themes_list = _parse_theme_string( $user_set_themes );
        $policy->set_themes( @user_set_themes_list );
    }

    if ( defined $user_add_themes ) {
        my @user_add_themes_list = _parse_themes_string( $user_add_themes );
        $policy->add_themes( @user_add_themes_list );
    }

    # Return constructed policy
    return $policy;
}

#-----------------------------------------------------------------------------

sub _policy_is_disabled {
    my ($self, $policy) = @_;
    my $policy_long_name  = ref $policy;
    my $policy_short_name = _policy_short_name($policy_long_name, $NAMESPACE);
    my $profile = $self->{_profile};

    return exists $profile->{"-$policy_short_name"} ||
        exists $profile->{"-$policy_long_name"};
}

#-----------------------------------------------------------------------------

sub _policy_fits_themes {
    my ($self, $policy) = @_;
    my @policy_themes    = $policy->get_themes();
    my @requested_themes = $self->themes();

    return 1 if not @requested_themes; #If none requested, then it always fits
    return 1 if _intersection(\@policy_themes, \@requested_themes);
    return 0;
}

#-----------------------------------------------------------------------------

sub _policy_is_unimportant {
    my ($self, $policy) = @_;
    my $policy_severity = $policy->get_severity();
    my $min_severity    = $self->severity();
    return $policy_severity < $min_severity;
}

#-----------------------------------------------------------------------------

sub _policy_is_included {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy || _policy_long_name($policy, $NAMESPACE);
    my @inclusions  = $self->include();
    return any { $policy_long_name =~ m/$_/imx } @inclusions;
}

#-----------------------------------------------------------------------------

sub _policy_is_excluded {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy || _policy_long_name($policy, $NAMESPACE);
    my @exclusions  = $self->exclude();
    return any { $policy_long_name =~ m/$_/imx } @exclusions;
}

#-----------------------------------------------------------------------------

sub _get_policy_params {
    my ($self, $policy) = @_;
    my $policy_long_name  = ref $policy || _policy_long_name($policy, $NAMESPACE);
    my $policy_short_name = _policy_short_name($policy_long_name, $NAMESPACE);

    my $profile = $self->{_profile};
    return $profile->{$policy_short_name}    ||
           $profile->{$policy_long_name}     ||
           $profile->{"-$policy_short_name"} ||
           $profile->{"-$policy_long_name"}  ||
           {};
}

#-----------------------------------------------------------------------------

sub _set_attributes {
    my ($self, %args) = @_;
    my $profile = $self->{_profile};
    my $user_defaults = $profile->{_} || {};
    my $defaults = Perl::Critic::Config::Defaults->new( %{ $user_defaults } );
    $self->{_severity} = $args{-severity} || $defaults->default_severity();
    $self->{_exclude}  = $args{-exclude}  || $defaults->default_exclude();
    $self->{_include}  = $args{-include}  || $defaults->default_include();
    $self->{_themes}   = $args{-themes}   || $defaults->default_themes();
    $self->{_defaults} = $defaults;
    return $self;
}

#-----------------------------------------------------------------------------

sub _parse_theme_string {
    my ($theme_string) = @_;
    return map { lc $_ } split m{ \s+ }mx, $theme_string;
}

sub _intersection {
    my ($arrayref_1, $arrayref_2) = @_;
    my %hashed = (); #Need a better name for this variable.
    @hashed{ @{$arrayref_1} } = @{$arrayref_1}; #e.g. (foo) ---> (foo => foo);
    return @hashed{ @{$arrayref_2} }; #Slicing out matching values
}

#------------------------------------------------------------------------

sub add_policy {

    my ( $self, %args ) = @_;
    my $policy  = $args{-policy} || return;
    my $config  = $args{-config} || {};

    if( not blessed($policy) ) {

        my $policy_long_name = _policy_long_name($policy, $NAMESPACE);
        eval { $policy  = $self->_create_policy($policy_long_name, $config) };

        if ($EVAL_ERROR) {
            confess qq{Failed to create policy "$policy": $EVAL_ERROR};
        }
    }

    push @{ $self->{_policies} }, $policy;
    return $self;
}

#------------------------------------------------------------------------
# Begin ACCESSSOR methods


sub policies {
    my $self = shift;
    return @{ $self->{_policies} };
}

sub profile_path {
    my $self = shift;
    return $self->{_profile_path};
}

sub profile {
    my $self = shift;
    return $self->{_profile};
}

sub defaults {
    my $self = shift;
    return $self->{_defaults};
}

sub severity {
    my $self = shift;
    return $self->{_severity};
}

sub include {
    my $self = shift;
    return @{ $self->{_include} };
}

sub exclude {
    my $self = shift;
    return @{ $self->{_exclude} };
}

sub themes {
    my $self = shift;
    return @{ $self->{_themes} };
}

#------------------------------------------------------------------------
# Begin PRIVATE methods

sub _load_profile {

    my ($self, $profile) = (@_);
    $profile ||= $self->profile_path();
    return {} if defined $profile && $profile eq $EMPTY;
    my $ref_type = ref $profile || 'DEFAULT';

    my %handlers = (
        SCALAR  => \&_load_profile_from_string,
        ARRAY   => \&_load_profile_from_array,
        HASH    => \&_load_profile_from_hash,
        DEFAULT => \&_load_profile_from_file,
    );

    my $handler = $handlers{$ref_type};
    confess qq{Can't create Config from $ref_type} if ! $handler;
    $self->{_profile} = $handler->($profile);
    return $self;
}

#------------------------------------------------------------------------

sub _load_profile_from_file {
    my $file = shift;
    $file ||= find_profile_path() || return {};
    confess qq{'$file' is not a file} if ! -f $file;
    return Config::Tiny->read($file);
}

#------------------------------------------------------------------------

sub _load_profile_from_array {
    my $array_ref = shift;
    my $joined    = join qq{\n}, @{ $array_ref };
    return Config::Tiny->read_string( $joined );
}

#------------------------------------------------------------------------

sub _load_profile_from_string {
    my $string = shift;
    return Config::Tiny->read_string( ${ $string } );
}

#------------------------------------------------------------------------

sub _load_profile_from_hash {
    my $hash_ref = shift;
    return $hash_ref;
}

#-----------------------------------------------------------------------------

sub _policy_long_name {
    my ($module_name, $namespace) = @_;
    if ( $module_name !~ m{ \A $namespace }mx ) {
        $module_name = $namespace . q{::} . $module_name;
    }
    return $module_name;
}

sub _policy_short_name {
    my ($module_name, $namespace) = @_;
    $module_name =~ s{\A $namespace ::}{}mx;
    return $module_name;
}

#----------------------------------------------------------------------------

sub _normalize_severity {
    my $severity = abs int shift;
    return $SEVERITY_HIGHEST if $severity > $SEVERITY_HIGHEST;
    return $SEVERITY_LOWEST  if $severity < $SEVERITY_LOWEST;
    return $severity;
}

#----------------------------------------------------------------------------

sub _validate_user_profile {
    my ($profile, $namespace) = @_;
    for my $policy_name ( sort keys %{ $profile } ) {
        next if _is_valid_policy( $policy_name, $namespace );
        carp qq{Can't find policy module '$policy_name'\n};
    }
    return 1;
}

sub _is_valid_policy {
    my ($policy_name, $namespace) = @_;
    $policy_name =~ s{\A \s* -}{}mx;
    my $policy_long_name = _policy_long_name($policy_name, $namespace);
    return any { $policy_long_name eq $_ } @SITE_POLICIES;
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

    #Check home directory
    if ( my $home_dir = _find_home_dir() ) {
        my $path = File::Spec->catfile( $home_dir, $rc_file );
        return $path if -f $path;
    }

    #No profile defined
    return;
}

sub _find_home_dir {

    #Try using File::HomeDir
    eval { require File::HomeDir };
    if ( ! $EVAL_ERROR ) {
        return File::HomeDir->my_home();
    }

    #Check usual environment vars
    for my $key (qw(HOME USERPROFILE HOMESHARE)) {
        next if ! defined $ENV{$key};
        return $ENV{$key} if -d $ENV{$key};
    }

    #No home directory defined
    return;
}

#----------------------------------------------------------------------------

sub site_policies {
    return @SITE_POLICIES;
}

# This list should be in alphabetic order but it's no longer critical
sub native_policies {
    return qw(
      Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr
      Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock
      Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep
      Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap
      Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction
      Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock
      Perl::Critic::Policy::ClassHierarchies::ProhibitAutoloading
      Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA
      Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless
      Perl::Critic::Policy::CodeLayout::ProhibitHardTabs
      Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins
      Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists
      Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines
      Perl::Critic::Policy::CodeLayout::RequireTidyCode
      Perl::Critic::Policy::CodeLayout::RequireTrailingCommas
      Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops
      Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse
      Perl::Critic::Policy::ControlStructures::ProhibitDeepNests
      Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls
      Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks
      Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode
      Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks
      Perl::Critic::Policy::Documentation::RequirePodAtEnd
      Perl::Critic::Policy::Documentation::RequirePodSections
      Perl::Critic::Policy::ErrorHandling::RequireCarping
      Perl::Critic::Policy::File::RequireFilenameMatchesPackage
      Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators
      Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles
      Perl::Critic::Policy::InputOutput::ProhibitInteractiveTest
      Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect
      Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop
      Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen
      Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint
      Perl::Critic::Policy::Miscellanea::ProhibitFormats
      Perl::Critic::Policy::Miscellanea::ProhibitTies
      Perl::Critic::Policy::Miscellanea::RequireRcsKeywords
      Perl::Critic::Policy::Modules::ProhibitAutomaticExportation
      Perl::Critic::Policy::Modules::ProhibitEvilModules
      Perl::Critic::Policy::Modules::ProhibitMultiplePackages
      Perl::Critic::Policy::Modules::RequireBarewordIncludes
      Perl::Critic::Policy::Modules::RequireEndWithOne
      Perl::Critic::Policy::Modules::RequireExplicitPackage
      Perl::Critic::Policy::Modules::RequireVersionVar
      Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs
      Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars
      Perl::Critic::Policy::References::ProhibitDoubleSigils
      Perl::Critic::Policy::RegularExpressions::ProhibitCaptureWithoutTest
      Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting
      Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching
      Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils
      Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms
      Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity
      Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef
      Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes
      Perl::Critic::Policy::Subroutines::ProtectPrivateSubs
      Perl::Critic::Policy::Subroutines::RequireFinalReturn
      Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict
      Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings
      Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels
      Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict
      Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings
      Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars
      Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators
      Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator
      Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator
      Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations
      Perl::Critic::Policy::Variables::ProhibitLocalVars
      Perl::Critic::Policy::Variables::ProhibitMatchVars
      Perl::Critic::Policy::Variables::ProhibitPackageVars
      Perl::Critic::Policy::Variables::ProhibitPunctuationVars
      Perl::Critic::Policy::Variables::ProtectPrivateVars
      Perl::Critic::Policy::Variables::RequireInitializationForLocalVars
      Perl::Critic::Policy::Variables::RequireLexicalLoopIterators
      Perl::Critic::Policy::Variables::RequireNegativeIndices
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

=item C<< add_policy( -policy => $policy_name, -config => \%config_hash ) >>

Loads a Policy object and adds into this Config.  If the object
cannot be instantiated, it will throw a warning and return a false
value.  Otherwise, it returns a reference to this Config.  Arguments
are key-value pairs as follows:

B<-policy> is the name of a L<Perl::Critic::Policy> subclass or an
reference to an actual Policy object.  If given a class name, The
C<'Perl::Critic::Policy'> portion of the name can be omitted for
brevity.  This argument is required.

B<-config> is an optional reference to a hash of Policy configuration
parameters (Note that this is B<not> a Perl::Critic::Config
object). The contents of this hash reference will be passed into to
the constructor of the Policy module.  See the documentation in the
relevant Policy module for a description of the arguments it supports.
NOTE: this parameter is ignored when the -policy argument is a
reference to an actual policy object.


=item C<policies()>

Returns a list containing references to all the Policy objects that
have been loaded into this Config.  Objects will be in the order that
they were loaded.

=back

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item C<find_profile_path()>

Searches the C<PERLCRITIC> environment variable, the current
directory, and you home directory (in that order) for a
F<.perlcriticrc> file.  If the file is found, the full path is
returned.  Otherwise, returns undef;

=item C<site_policies()>

Returns a list of all the Policy modules that are currently installed
in the Perl::Critic:Policy namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.

=item C<native_policies()>

Returns a list of all the Policy modules that have been distributed
with Perl::Critic.  Does not include any third-party modules.

=back

=head1 ADVANCED USAGE

All the Policy modules that ship with Perl::Critic are in the
C<"Perl::Critic::Policy"> namespace.  To load modules from an alternate
namespace, import Perl::Critic::Config using the C<-namespace> option
like this:

  use Perl::Critic::Config -namespace => 'Foo::Bar'; #Loads from Foo::Bar::*

At the moment, only one alternate namespace may be specified.  Unless
Policy module names are fully qualified, Perl::Critic::Config assumes
that all Policies are in the specified namespace.  So if you want to
use Policies from multiple namespaces, you will need to use the full
module name in your F<.perlcriticrc> file.

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
