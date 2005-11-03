package Perl::Critic::Config;

use strict;
use warnings;
use File::Spec;
use Config::Tiny;
use English qw(-no_match_vars);
use List::MoreUtils qw(any none);
use Perl::Critic::Utils;
use Carp qw(croak);

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#-------------------------------------------------------------------------

sub new {

    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Avoid 'uninitialized' warnings
    my $ref_type = defined $args{-profile} ? ref $args{-profile} : $EMPTY;

    #Allow empty config.  This is useful for testing
    return $self if defined $args{-profile} && $args{-profile} eq 'NONE';

    #Now load profile in various ways
    if ( $ref_type eq 'SCALAR' ) {
        %{ $self } = _load_from_string( %args );
    }
    elsif ( $ref_type eq 'ARRAY' ) {
        %{ $self } = _load_from_array( %args );
    }
    elsif ( $ref_type eq 'HASH' ){
        %{ $self } = _load_from_hash( %args );
    }
    else {
        %{ $self } = _load_from_file( %args );
    }

    #Filter config by patterns or priority
    if ( $args{-exclude} || $args{-include} ) {
      _filter_by_pattern( $self, %args );
    }
    else {
      _filter_by_priority( $self, %args );
    }

    #All done!
    return $self;
}

#------------------------------------------------------------------------
#Begin PRIVATE methods

sub _load_from_file {

    my %args = @_;
    my $file = $args{-profile};
    $file = defined $file ? $file : find_profile_path();
    
    my %profile = ();
    if (! $file ){
	
	#No profile exists, so just construct hash from
	#default policy lists, using no parameters
	%profile = map { ( $_ => {} ) } default_policies();
    }
    else {

	#Load user's configuration and merge it with the
	#default profile, using the user's parameters
	croak qq{'$file' is not a file} if ! -f $file;
	my $user_prefs = Config::Tiny->read($file);
	%profile = _merge_profile( $user_prefs );
  }
    return %profile;
}

#------------------------------------------------------------------------

sub _load_from_array {
    my %args        = @_;
    my $joined      = join qq{\n}, @{ $args{-profile} };
    my $user_prefs  = Config::Tiny->read_string( $joined );
    return _merge_profile( $user_prefs );
}

#------------------------------------------------------------------------

sub _load_from_string {
    my %args          = @_;
    my $string        = ${ $args{-profile} };
    my $user_prefs    = Config::Tiny->read_string( $string );
    return _merge_profile( $user_prefs );
}

#------------------------------------------------------------------------

sub _load_from_hash {
    my %args          = @_;
    my $user_prefs    = $args{-profile};
    return _merge_profile( $user_prefs );
}

#------------------------------------------------------------------------

sub _merge_profile {
    my $user_prefs  = shift;
    my %config      = ();

    #Add user's custom policies first
    while ( my ($policy, $params) = each %{ $user_prefs } ) {
	next if $policy eq $EMPTY;       #Skip default section
	next if $policy =~ m{ \A - }mx;  #Skip negated policies
	$config{$policy} = $params || {};
    }

    #Now add default policies
    for my $policy ( default_policies() ){
	next if defined $user_prefs->{"-$policy"}; #Skip negated policies
	$config{$policy} = $user_prefs->{$policy} || {};
    }

    return %config;
}

#------------------------------------------------------------------------

sub _filter_by_pattern {
    my ($config, %args) = @_;
    my $in_patterns = $args{-include} || [];
    my $ex_patterns = $args{-exclude} || [];

    for my $policy ( keys %{ $config } ) {
        if (   none {$policy =~ m{ $_ }imx} @{ $in_patterns }
	       or any  {$policy =~ m{ $_ }imx} @{ $ex_patterns } ) {
            delete $config->{$policy};
        }
    }
    return $config;
}

#------------------------------------------------------------------------

sub _filter_by_priority {
    my ($config, %args) = @_;
    my $max_priority = $args{-priority} || 1;

    for my $policy ( keys  %{ $config } ) {
        $config->{$policy}->{priority} ||= 1; #Default to 1
	if( $config->{$policy}->{priority} > $max_priority ) {
	    delete $config->{$policy};
        }
    }
    return $config;
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

sub all_policies {
    return sort default_policies(), optional_policies();
}

#----------------------------------------------------------------------------

sub default_policies {
    return qw(
      BuiltinFunctions::ProhibitLvalueSubstr
      BuiltinFunctions::ProhibitSleepViaSelect
      BuiltinFunctions::ProhibitStringyEval
      BuiltinFunctions::RequireBlockGrep
      BuiltinFunctions::RequireBlockMap
      BuiltinFunctions::RequireGlobFunction
      ClassHierarchies::ProhibitOneArgBless
      CodeLayout::ProhibitHardTabs
      CodeLayout::ProhibitParensWithBuiltins
      CodeLayout::ProhibitQuotedWordLists
      CodeLayout::RequireTrailingCommas
      ControlStructures::ProhibitCascadingIfElse
      ControlStructures::ProhibitCStyleForLoops
      ControlStructures::ProhibitPostfixControls
      ControlStructures::ProhibitUnlessBlocks
      ControlStructures::ProhibitUntilBlocks
      InputOutput::ProhibitBacktickOperators
      InputOutput::ProhibitBarewordFileHandles
      InputOutput::ProhibitOneArgSelect
      Modules::ProhibitMultiplePackages
      Modules::ProhibitSpecificModules
      Modules::RequireExplicitPackage
      Modules::RequireBarewordIncludes
      Modules::RequireVersionVar
      NamingConventions::ProhibitMixedCaseSubs
      NamingConventions::ProhibitMixedCaseVars
      Subroutines::ProhibitExplicitReturnUndef
      RegularExpressions::RequireExtendedFormatting
      RegularExpressions::RequireLineBoundaryMatching
      Subroutines::ProhibitBuiltinHomonyms
      Subroutines::ProhibitSubroutinePrototypes
      TestingAndDebugging::RequirePackageStricture
      TestingAndDebugging::RequirePackageWarnings
      ValuesAndExpressions::ProhibitConstantPragma
      ValuesAndExpressions::ProhibitEmptyQuotes
      ValuesAndExpressions::ProhibitInterpolationOfLiterals
      ValuesAndExpressions::ProhibitLeadingZeros
      ValuesAndExpressions::ProhibitNoisyQuotes
      ValuesAndExpressions::RequireInterpolationOfMetachars
      ValuesAndExpressions::RequireNumberSeparators
      ValuesAndExpressions::RequireQuotedHeredocTerminator
      ValuesAndExpressions::RequireUpperCaseHeredocTerminator
      Variables::ProhibitLocalVars
      Variables::ProhibitPackageVars
      Variables::ProhibitPunctuationVars
    );
}

#----------------------------------------------------------------------------

sub optional_policies {
    return qw(
      CodeLayout::RequireTidyCode
      Miscellanea::RequireRcsKeywords
    );
}

#----------------------------------------------------------------------------

sub pbp_policies {
    return qw(
      BuiltinFunctions::ProhibitLvalueSubstr
      BuiltinFunctions::ProhibitSleepViaSelect
      BuiltinFunctions::ProhibitStringyEval
      BuiltinFunctions::RequireBlockGrep
      BuiltinFunctions::RequireBlockMap
      BuiltinFunctions::RequireGlobFunction
      ClassHierarchies::ProhibitOneArgBless
      CodeLayout::ProhibitHardTabs
      CodeLayout::ProhibitParensWithBuiltins
      CodeLayout::RequireTrailingCommas
      ControlStructures::ProhibitCascadingIfElse
      ControlStructures::ProhibitCStyleForLoops
      ControlStructures::ProhibitPostfixControls
      ControlStructures::ProhibitUnlessBlocks
      ControlStructures::ProhibitUntilBlocks
      InputOutput::ProhibitBarewordFileHandles
      InputOutput::ProhibitOneArgSelect
      NamingConventions::ProhibitMixedCaseSubs
      NamingConventions::ProhibitMixedCaseVars
      Subroutines::ProhibitExplicitReturnUndef
      RegularExpressions::RequireExtendedFormatting
      RegularExpressions::RequireLineBoundaryMatching
      Subroutines::ProhibitBuiltinHomonyms
      Subroutines::ProhibitSubroutinePrototypes
      TestingAndDebugging::RequirePackageStricture
      TestingAndDebugging::RequirePackageWarnings
      ValuesAndExpressions::ProhibitConstantPragma
      ValuesAndExpressions::ProhibitEmptyQuotes
      ValuesAndExpressions::ProhibitInterpolationOfLiterals
      ValuesAndExpressions::ProhibitLeadingZeros
      ValuesAndExpressions::ProhibitNoisyQuotes
      ValuesAndExpressions::RequireInterpolationOfMetachars
      ValuesAndExpressions::RequireNumberSeparators
      ValuesAndExpressions::RequireQuotedHeredocTerminator
      ValuesAndExpressions::RequireUpperCaseHeredocTerminator
      Variables::ProhibitLocalVars
      Variables::ProhibitPackageVars
      Variables::ProhibitPunctuationVars
    );
}



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

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item find_profile_path( void )

Searches the C<PERLCRITIC> environment variable, the current
directory, and you home directory (in that order) for a
F<.perlcriticrc> file.  If the file is found, the full path is
returned.  Otherwise, returns undef;

=item default_policies( void )

Returns a list of the default Policy modules that are automatically
included in the Config.  This includes all the Policy modules that
ship with Perl::Critic except those that depend on optional external
modules.

=item optional_policies( void )

Returns a list of the optional Policy modules that ship with
Perl::Critic but are not part of the default setup.  These Policies
are usually optional because they depend on external modules.

=item all_policies( void )

Returns a list of all the Policy modules that ship with Perl::Critic.
In other words it is the union of C<default_policies()> and
C<optional_policies()>.

=item pbp_policies( void )

Returns a list of only those Policy modules based on Damian Conway's
book "Perl Best Practices."  In the future, Perl::Critic may support
some option to use only PBP Policies.

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
