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

our $VERSION = 0.22;

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
    $self->_init( %args );
    return $self;
}

#-----------------------------------------------------------------------------

sub _init {

    my ( $self, %args ) = @_;
    my $profile = $args{-profile};
    $self->{_policies} = [];

    my $policy_names = $args{-policy_names} || \@SITE_POLICY_NAMES;
    for my $policy_name ( @{ $policy_names } ) {
        my $params = $profile->policy_params( $policy_name );
        my $policy = $self->create_policy( $policy_name, $params );
        push @{ $self->{_policies} }, $policy;
    }
    return $self;
}

#-----------------------------------------------------------------------------

sub create_policy {

    my ($self, $policy_name, $params) = @_;

    confess q{policy argument is required} if not $policy_name;
    $policy_name = policy_long_name( $policy_name );
    $params ||= {};

    # Pull out base parameters.  Alternate spellings are supported just for
    # convenience to the user, but please don't document them.
    my $user_set_themes = $params->{set_themes} || $params->{set_theme};
    my $user_add_themes = $params->{add_themes} || $params->{add_theme};
    my $user_severity   = $params->{severity};

    # Construct policy from remaining params
    my $policy = $policy_name->new( %{$params} );

    # Set base attributes on policy
    if ( defined $user_severity ) {
        my $normalized_severity = _normalize_severity( $user_severity );
        $policy->set_severity( $normalized_severity );
    }

    if ( defined $user_set_themes ) {
        my @set_themes = _parse_theme_string( $user_set_themes );
        $policy->set_themes( @set_themes );
    }

    if ( defined $user_add_themes ) {
        my @add_themes = _parse_theme_string( $user_add_themes );
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

sub _normalize_severity {
    my $s = shift || return $SEVERITY_HIGHEST;
    $s = $s > $SEVERITY_HIGHEST ? $SEVERITY_HIGHEST : $s;
    $s = $s < $SEVERITY_LOWEST  ? $SEVERITY_LOWEST : $s;
    return $s;
}

#-----------------------------------------------------------------------------

sub _parse_theme_string {
    my $theme_string = shift;
    return sort split m{\s+}mx, $theme_string;
}

#----------------------------------------------------------------------------

sub site_policy_names {
    return @SITE_POLICY_NAMES;
}

#----------------------------------------------------------------------------
# This list should be in alphabetic order but it's no longer critical

sub native_policy_names {
    return qw(
      Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr
      Perl::Critic::Policy::BuiltinFunctions::ProhibitReverseSortBlock
      Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval
      Perl::Critic::Policy::BuiltinFunctions::ProhibitStringySplit
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalCan
      Perl::Critic::Policy::BuiltinFunctions::ProhibitUniversalIsa
      Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidGrep
      Perl::Critic::Policy::BuiltinFunctions::ProhibitVoidMap
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
      Perl::Critic::Policy::ControlStructures::ProhibitMutatingListFunctions
      Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls
      Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks
      Perl::Critic::Policy::ControlStructures::ProhibitUnreachableCode
      Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks
      Perl::Critic::Policy::Documentation::RequirePodAtEnd
      Perl::Critic::Policy::Documentation::RequirePodSections
      Perl::Critic::Policy::ErrorHandling::RequireCarping
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
      Perl::Critic::Policy::Modules::RequireFilenameMatchesPackage
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
      Perl::Critic::Policy::TestingAndDebugging::ProhibitProlongedStrictureOverride
      Perl::Critic::Policy::TestingAndDebugging::RequireTestLabels
      Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict
      Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitMismatchedOperators
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

__END__

#----------------------------------------------------------------------------

=pod

=for stopwords PolicyFactory -params

=head1 NAME

Perl::Critic::PolicyFactory - Instantiate Policy objects

=head1 DESCRIPTION

This is a helper class that instantiates L<Perl::Critic::Policy>
objects with the user's preferred parameters. There are no
user-serviceable parts here.

=head1 CONSTRUCTOR

=over 8

=item C<< new( -profile => $profile, -policy_names => \@policy_names ) >>

Returns a reference to a new Perl::Critic::PolicyFactory object.

B<-profile> is a reference to a L<Perl::Critic::UserProfile> object.
This argument is required.

B<-policy_names> is a reference to an array of fully-qualified Policy
names.  Internally, the PolicyFactory will create one instance each of
the named Policies.

=back

=head1 METHODS

=over 8

=item C<< create_policy( -policy => $policy_name, -params => \%param_hash ) >>

Creates one Policy object.  If the object cannot be instantiated, it
will throw a fatal exception.  Otherwise, it returns a reference to
the new Policy object.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass module.
The C<'Perl::Critic::Policy'> portion of the name can be omitted for
brevity.  This argument is required.

B<-params> is an optional reference to hash of parameters that will be
passed into the constructor of the Policy.  If C<-params> is not
defined, we will use the appropriate Policy parameters from the
L<Perl::Critic::UserProfile>.

=item C< policies() >

Returns a list of of references to all the L<Perl::Critic::Policy>
objects that were created by this PolicyFactory.

=back

=head1 SUBROUTINES

Perl::Critic::PolicyFactory has a few static subroutines that are used
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
# ex: set ts=8 sts=4 sw=4 expandtab :
