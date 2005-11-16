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
use Module::Pluggable (search_path => ['Perl::Critic::Policy'], require => 1);
use English qw(-no_match_vars);
use List::MoreUtils qw(any none);
use Perl::Critic::Utils;
use Carp qw(carp croak);

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#This finds all Perl::Critic::Policy::* modules and requires them.
my @SITE_POLICIES = plugins();  #Imported from Module::Pluggable

#-------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_policies} = [];

    # Set defaults
    my $profile_path = $args{-profile}  || $EMPTY;
    my $min_priority = $args{-priority} || 1;
    my $excludes_ref = $args{-exclude}  || [];  #empty array
    my $includes_ref = $args{-include}  || [];  #empty array

    # Allow null config.  This is useful for testing
    return $self if $profile_path eq 'NONE';

    # Load user's profile, then filter and create Policies
    my $profile_ref = _load_profile( $profile_path ) || {};
    while ( my ( $policy, $params ) = each %{ $profile_ref } ) {
        next if any  { $policy =~ m{ $_ }imx } @{ $excludes_ref };
        next if none { $policy =~ m{ $_ }imx } @{ $includes_ref };
        next if ( $params->{priority} ||= 0 ) > $min_priority;
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
    my $module_name = _long_name($policy);

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
    my $ref_type = ref $profile;

    #Load profile in various ways
    my $user_prefs  =  $ref_type eq 'SCALAR' ?  _load_from_string( $profile )
                    :  $ref_type eq 'ARRAY'  ?  _load_from_array( $profile )
                    :  $ref_type eq 'HASH'   ?  _load_from_hash( $profile )
                    :                           _load_from_file( $profile );

    #Apply profile
    my %final = ();
    for my $policy ( @SITE_POLICIES ) {
        my $short_name = _short_name($policy);
        next if exists $user_prefs->{"-$short_name"};
        my $params = $user_prefs->{$short_name} || {};
	$final{ $policy } = $params;
    }

    return \%final;
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
    my $module_name = shift;
    my $namespace = 'Perl::Critic::Policy';
    if ( $module_name !~ m{ \A $namespace }mx ) {
        $module_name = $namespace . q{::} . $module_name;
    }
    return $module_name;
}

sub _short_name {
    my $module_name = shift;
    my $namespace = 'Perl::Critic::Policy';
    $module_name =~ s{\A $namespace ::}{}mx;
    return $module_name;
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
        next if !defined $ENV{$var};
        my $path = File::Spec->catfile( $ENV{$var}, $rc_file );
        return $path if -f $path;
    }

    #No profile found!
    return;
}

#----------------------------------------------------------------------------

sub site_policies {
    return @SITE_POLICIES
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

Perl::Critic::Config - Load Perl::Critic user-preferences

=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic>.  The Config dictates which
Policy modules will be loaded into the Perl::Critic engine and how
they should be configured.  You should never need to instantiate
Perl::Critic::Config directly as the L<Perl::Critic> constructor will
do it for you.

=head1 CONSTRUCTOR

=over 8

=item new ( [ -profile => $FILE, -priority => $N, -include => \@PATTERNS, -exclude => \@PATTERNS ] )

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
file can't be found, or if C<$FILE> is an empty string, then it
defaults to include all the Policy modules that ship with
Perl::Critic. See L<"CONFIGURATION"> for more information.

B<-priority> is the maximum priority value of Policies that should be
added to the Perl::Critic::Config.  1 is the "highest" priority, and
all numbers larger than 1 have "lower" priority. Once the
user-preferences have been read from the C<-profile>, all Policies
that are configured with a priority greater than C<$N> will be removed
from this Config.  For a given C<-profile>, increasing C<$N> will
result in more Policy violations.  The default C<-priority> is 1.  See
L<"CONFIGURATION"> for more information.

B<-include> is a reference to a list of C<@PATTERNS>.  Once the
user-preferences have been read from the C<-profile>, all Policies
that do not match at least one C<m/$PATTERN/imx> will be removed
from this Config.  Using the C<-include> option causes the <-priority>
option to be ignored.

B<-exclude> is a reference to a list of C<@PATTERNS>.  Once the
user-preferences have been read from the C<-profile>, all Policies
that match at least one C<m/$PATTERN/imx> will be removed from
this Config.  Using the C<-exclude> option causes the <-priority>
option to be ignored.  The C<-exclude> patterns are applied after the
<-include> patterns, therefore, the C<-exclude> patterns take
precedence.

=back

=head1 METHODS

=over 8

=item add_policy( -policy => $policy_name, -config => \%config_hash )

TODO: Document this mehtod

=item policies( void )

TODO: Document this method

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
C<-profile> option is not given to the constructor,
Perl::Critic::Config defaults to inlucde all the policies that are
shipped with Perl::Critic.

The format of the configuration file is a series of named sections
that contain key-value pairs separated by '='. Comments should
start with '#' and can be placed on a separate line or after the
name-value pairs if you desire.  The general recipe is a series of
blocks like this:

    [Perl::Critic::Policy::Category::PolicyName]
    priority = 1
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Policy::Category::PolicyName> is the full name of a
module that implements the policy.  The Policy modules distributed
with Perl::Critic have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can ommit the C<'Perl::Critic::Policy'> part of the
module name.  All Policy modules must be a subclass of
L<Perl::Critic::Policy>.

C<priority> is the level of importance you wish to assign to this
policy.  1 is the "highest" priority level, and all numbers greater
than 1 have increasingly "lower" priority.  Only those policies with a
priority less than or equal to the C<-priority> value given to the
constructor will be loaded.  The priority can be an arbitrarily large
positive integer.  If the priority is not defined, it defaults to 1.

The remaining key-value pairs are configuration parameters for that
specific Policy and will be passed into the constructor of the
L<Perl::Critic::Policy> subclass.  The constructors for most Policy
modules do not support arguments, and those that do should have
reasonable defaults.  See the documentation on the appropriate Policy
module for more details.

By default, all the policies that are distributed with Perl::Critic
are added to the Config.  Rather than assign a priority level to a
Policy, you can simply "turn off" a Policy by prepending a '-' to the
name of the module in the config file.  In this manner, the Policy
will never be loaded, regardless of the C<-priority> given to the
constructor.


A simple configuration might look like this:

    #--------------------------------------------------------------
    # These are really important, so always load them

    [TestingAndDebugging::RequirePackageStricture]
    priority = 1

    [TestingAndDebugging::RequirePackageWarnings]
    priority = 1

    #--------------------------------------------------------------
    # These are less important, so only load when asked

    [Variables::ProhibitPackageVars]
    priority = 2

    [ControlStructures::ProhibitPostfixControls]
    priority = 2

    #--------------------------------------------------------------
    # I do not agree with these, so never load them

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
