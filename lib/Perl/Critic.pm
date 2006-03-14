#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic;

use strict;
use warnings;
use File::Spec;
use English qw(-no_match_vars);
use Perl::Critic::Config;
use Perl::Critic::Utils;
use Carp;
use PPI;

our $VERSION = '0.14_02';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    $self->{_force}  = $args{-force}  || 0;
    $self->{_config} = $args{-config} || Perl::Critic::Config->new( %args );
    return $self;
}

#----------------------------------------------------------------------------

sub config {
    my $self = shift;
    return $self->{_config};
}

#----------------------------------------------------------------------------

sub add_policy {
    my ( $self, @args ) = @_;
    #Delegate to Perl::Critic::Config
    return $self->config()->add_policy( @args );
}

#----------------------------------------------------------------------------

sub policies {
    my $self = shift;
    #Delegate to Perl::Critic::Config
    return $self->config()->policies();
}

#----------------------------------------------------------------------------

sub critique {

    # Here we go!
    my ( $self, $source_code ) = @_;

    # Parse the code
    my $doc = PPI::Document->new($source_code);

    # Bail on error
    if ( !defined $doc ) {
        my $errstr = PPI::Document::errstr();
        my $file = -f $source_code ? $source_code : 'stdin';
        die qq{Cannot parse code: $errstr of '$file'\n};
    }

    # Pre-index location of each node (for speed)
    $doc->index_locations();

    # keys of hash are line numbers to ignore for violations
    my %is_line_disabled;

    # Remove the magic shebang fix
    %is_line_disabled = ( %is_line_disabled, _unfix_shebang($doc) );

    # Filter exempt code, if desired
    if ( !$self->{_force} ) {
        %is_line_disabled = ( %is_line_disabled, _filter_code($doc) );
    }

    # Run engine, testing each Policy at each element
    my %types = ( 'PPI::Document' => [$doc],
                  'PPI::Element'  => $doc->find('PPI::Element') || [], );
    my @violations;
    my @pols = @{ $self->policies() };
    @pols || return;    #Nothing to do!
    for my $pol (@pols) {
        for my $type ( $pol->applies_to() ) {
            $types{$type}
              ||= [ grep { $_->isa($type) } @{ $types{'PPI::Element'} } ];
            push @violations, grep { !$is_line_disabled{ $_->location->[0] } }
                map { $pol->violates( $_, $doc ) } @{ $types{$type} };
        }
    }
    return Perl::Critic::Violation->sort_by_location(@violations);
}

#============================================================================
#PRIVATE SUBS

sub _filter_code {

    my $doc        = shift;
    my $nodes_ref  = $doc->find('PPI::Token::Comment') || return;
    my $no_critic  = qr{\A \s* \#\# \s* no  \s+ critic}mx;
    my $use_critic = qr{\A \s* \#\# \s* use \s+ critic}mx;

    my %disabled_lines;

  PRAGMA:
    for my $pragma ( grep { $_ =~ $no_critic } @{$nodes_ref} ) {

        my $parent = $pragma->parent();
        my $grandparent = $parent ? $parent->parent() : undef;
        my $sib = $pragma->sprevious_sibling();

        # Handle single-line usage on simple statements
        if ( $sib && $sib->location->[0] == $pragma->location->[0] ) {
            $disabled_lines{ $pragma->location->[0] } = 1;
            next PRAGMA;
        }


        # Handle single-line usage on compound statements
        if ( ref $parent eq 'PPI::Structure::Block' ) {
            if ( ref $grandparent eq 'PPI::Statement::Compound' ) {
                if ( $parent->location->[0] == $pragma->location->[0] ) {
                    $disabled_lines{ $grandparent->location->[0] } = 1;
                    #$disabled_lines{ $parent->location->[0] } = 1;
                    next PRAGMA;
                }
            }
        }


        # Handle multi-line usage.  This is either a "no critic" ..
        # "use critic" region or a block where "no critic" persists
        # until the end of the scope.  The start is the always the "no
        # critic" which we already found.  So now we have to search
        # for the end.

        my $start = $pragma;
        my $end   = $pragma;

      SIB:
        while ( my $sib = $end->next_sibling() ) {
            $end = $sib; # keep track of last sibling encountered in this scope
            last SIB
              if $sib->isa('PPI::Token::Comment') && $sib =~ $use_critic;
        }

        # We either found an end or hit the end of the scope.
        # Flag all intervening lines
        for my $line ( $start->location->[0] .. $end->location->[0] ) {
            $disabled_lines{$line} = 1;
        }
    }

    return %disabled_lines;
}

#----------------------------------------------------------------------------

sub _unfix_shebang {

    #When you install a script using ExtUtils::MakeMaker or
    #Module::Build, it inserts some magical code into the top of the
    #file (just after the shebang).  This code allows people to call
    #your script using a shell, like `sh my_script`.  Unfortunately,
    #this code causes several Policy violations, so we just remove it.

    my $doc         = shift;
    my $first_stmnt = $doc->schild(0) || return;

    #Different versions of MakeMaker and Build use slightly differnt
    #shebang fixing strings.  This matches most of the ones I've found
    #in my own Perl distribution, but it may not be bullet-proof.

    my $fixin_rx = qr{^eval 'exec .* \$0 \${1\+"\$@"}'\s*[\r\n]\s*if.+;};
    if ( $first_stmnt =~ $fixin_rx ) {
        my $line = $first_stmnt->location->[0];
        return ( $line => 1, $line + 1 => 1 );
    }

    return;
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=for stopwords DGR INI-style

=head1 NAME

Perl::Critic - Critique Perl source code for best-practices

=head1 SYNOPSIS

  use Perl::Critic;
  my $file = shift;
  my $critic = Perl::Critic->new();
  my @violations = $critic->critique($file);
  print @violations;

=head1 DESCRIPTION

Perl::Critic is an extensible framework for creating and applying
coding standards to Perl source code.  Essentially, it is a static
source code analysis engine.  Perl::Critic is distributed with a
number of L<Perl::Critic::Policy> modules that attempt to enforce
various coding guidelines.  Most Policy modules are based on Damian
Conway's book B<Perl Best Practices>.  You can enable, disable, and
customize those Polices through the Perl::Critic interface.  You can
also create new Policy modules that suit your own tastes.

For a convenient command-line interface to Perl::Critic, see the
documentation for L<perlcritic>.  If you want to integrate
Perl::Critic with your build process, L<Test::Perl::Critic> provides
an interface that is suitable for test scripts.  For the ultimate
convenience (at the expense of some flexibility) see the L<criticism>
pragma.

Win32 and ActivePerl users can find PPM distributions of Perl::Critic
at L<http://theoryx5.uwinnipeg.ca/ppms/>.

=head1 CONSTRUCTOR

=over 8

=item C<new( -profile =E<gt> $FILE, -severity =E<gt> $N, -include =E<gt> \@PATTERNS, -exclude =E<gt> \@PATTERNS, -force =E<gt> 1 )>

Returns a reference to a new Perl::Critic object.  Most arguments are
just passed directly into L<Perl::Critic::Config>, but I have described
them here as well.  All arguments are optional key-value pairs as
follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not
defined, Perl::Critic::Config attempts to find a F<.perlcriticrc>
configuration file in the current directory, and then in your home
directory.  Alternatively, you can set the C<PERLCRITIC> environment
variable to point to a file in another location.  If a configuration
file can't be found, or if C<$FILE> is an empty string, then all
Policies will be loaded with their default configuration.  See
L<"CONFIGURATION"> for more information.

B<-severity> is the minimum severity level.  Only Policy modules that
have a severity greater than C<$N> will be loaded.  Severity values
are integers ranging from 1 (least severe) to 5 (most severe).  The
default is 5.  For a given C<-profile>, decreasing the C<-severity>
will usually result in more Policy violations.  Users can redefine the
severity level for any Policy in their F<.perlcriticrc> file.  See
L<"CONFIGURATION"> for more information.

B<-include> is a reference to a list of string C<@PATTERNS>.  Policy
modules that match at least one C<m/$PATTERN/imx> will always be
loaded, irrespective of the severity settings.  For example:

  my $critic = Perl::Critic->new(-include => ['layout'] -severity => 4);

This would cause Perl::Critic to load all the C<CodeLayout::*> Policy
modules even though they have a severity level that is less than 4.
You can use C<-include> in conjunction with the C<-exclude> option.
Note that C<-exclude> takes precedence over C<-include> when a Policy
matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Policy
modules that match at least one C<m/$PATTERN/imx> will not be loaded,
irrespective of the severity settings.  For example:

  my $critic = Perl::Critic->new(-exclude => ['strict'] -severity => 1);

This would cause Perl::Critic to not load the C<RequireUseStrict> and
C<ProhibitNoStrict> Policy modules even though they have a severity
level that is greater than 1.  You can use C<-exclude> in conjunction
with the C<-include> option.  Note that C<-exclude> takes precedence
over C<-include> when a Policy matches both patterns.

B<-force> controls whether Perl::Critic observes the magical C<"## no
critic"> pseudo-pragmas in your code.  If set to a true value,
Perl::Critic will analyze all code.  If set to a false value (which is
the default) Perl::Critic will ignore code that is tagged with these
comments.  See L<"BENDING THE RULES"> for more information.

B<-config> is a reference to a L<Perl::Critic::Config> object.  If you
have created your own Config object for some reason, you can pass it
in here instead of having Perl::Critic create one for you.  Using the
C<-config> option causes all the other options to be silently ignored.

=back

=head1 METHODS

=over 8

=item C<critique( $source_code )>

Runs the C<$source_code> through the Perl::Critic engine using all the
Policies that have been loaded into this engine.  If C<$source_code>
is a scalar reference, then it is treated as string of actual Perl
code.  Otherwise, it is treated as a path to a file containing Perl
code.  Returns a list of L<Perl::Critic::Violation> objects for each
violation of the loaded Policies.  The list is sorted in the order
that the Violations appear in the code.  If there are no violations,
returns an empty list.

=item C<add_policy( -policy =E<gt> $policy_name, -config =E<gt> \%config_hash )>

Creates a Policy object and loads it into this Critic.  If the object
cannot be instantiated, it will throw a warning and return a false
value.  Otherwise, it returns a reference to this Critic.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass
module.  The C<'Perl::Critic::Policy'> portion of the name can be
omitted for brevity.  This argument is required.

B<-config> is an optional reference to a hash of Policy configuration
parameters.  Note that this is B<not> the same thing as a
L<Perl::Critic::Config> object. The contents of this hash reference
will be passed into to the constructor of the Policy module.  See the
documentation in the relevant Policy module for a description of the
arguments it supports.

=item C<policies()>

Returns a list containing references to all the Policy objects that
have been loaded into this engine.  Objects will be in the order that
they were loaded.

=item C<config()>

Returns the L<Perl::Critic::Config> object that was created for or given
to this Critic.

=back

=head1 CONFIGURATION

The default configuration file is called F<.perlcriticrc>.
Perl::Critic will look for this file in the current directory first,
and then in your home directory.  Alternatively, you can set the
PERLCRITIC environment variable to explicitly point to a different
file in another location.  If none of these files exist, and the
C<-profile> option is not given to the constructor, then all the
modules that are found in the Perl::Critic::Policy namespace will be
loaded with their default configuration.

The format of the configuration file is a series of INI-style sections
that contain key-value pairs separated by '='. Comments should start
with '#' and can be placed on a separate line or after the name-value
pairs if you desire.  The general recipe is a series of blocks like
this:

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

The remaining key-value pairs are configuration parameters for that
will be passed into the constructor that Policy.  The constructors for
most Policy modules do not support arguments, and those that do should
have reasonable defaults.  See the documentation on the appropriate
Policy module for more details.

Instead of redefining the severity for a given Policy, you can
completely disable a Policy by prepending a '-' to the name of the
module in your configuration file.  In this manner, the Policy will
never be loaded, regardless of the C<-severity> given to the
Perl::Critic constructor.

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
  allow = if unless  #My custom configuration
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
Conway's book "Perl Best Practice."

=head1 THE POLICIES

The following Policy modules are distributed with Perl::Critic.  The
Policy modules have been categorized according to the table of
contents in Damian Conway's book B<Perl Best Practices>.  Since most
coding standards take the form "do this..." or "don't do that...", I
have adopted the convention of naming each module C<RequireSomething>
or C<ProhibitSomething>.  Each Policy is listed here with it's default
severity.  If you don't agree with the default severity, you can
change it in your F<.perlcriticrc> file.  See the documentation of
each module for it's specific details.

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr>

Use 4-argument C<substr> instead of writing C<substr($foo, 2, 6) = $bar> [Severity 3]

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect>

Use L<Time::HiRes> instead of something like C<select(undef, undef, undef, .05)> [Severity 5]

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval>

Write C<eval { my $foo; bar($foo) }> instead of C<eval "my $foo; bar($foo);"> [Severity 5]

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep>

Write C<grep { $_ =~ /$pattern/ } @list> instead of C<grep /$pattern/, @list> [Severity 4]

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap>

Write C<map { $_ =~ /$pattern/ } @list> instead of C<map /$pattern/, @list> [Severity 4]

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction>

Use C<glob q{*}> instead of <*> [Severity 5]

=head2 L<Perl::Critic::Policy::ClassHierarchies::ProhibitExplicitISA>

Employ C<use base> instead of C<@ISA> [Severity 3]

=head2 L<Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless>

Write C<bless {}, $class;> instead of just C<bless {};> [Severity 5]

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitHardTabs>

Use spaces instead of tabs. [Severity 3]

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins>

Write C<open $handle, $path> instead of C<open($handle, $path)> [Severity 1]

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists>

Write C<qw(foo bar baz)> instead of C<('foo', 'bar', 'baz')> [Severity 2]

=head2 L<Perl::Critic::Policy::CodeLayout::RequireTidyCode>

Must run code through L<perltidy>. [Severity 1]

=head2 L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>

Put a comma at the end of every multi-line list declaration, including the last one. [Severity 1]

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse>

Don't write long "if-elsif-elsif-elsif-elsif...else" chains. [Severity 3]

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops>

Write C<for(0..20)> instead of C<for($i=0; $i<=20; $i++)> [Severity 2]

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>

Write C<if($condition){ do_something() }> instead of C<do_something() if $condition> [Severity 2]

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks>

Write C<if(! $condition)> instead of C<unless($condition)> [Severity 2]

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks>

Write C<while(! $condition)> instead of C<until($condition)> [Severity 2]

=head2 L<Perl::Critic::Policy::Documentation::RequirePodAtEnd>

All POD should be after C<__END__> [Severity 1]

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators>

Discourage stuff like C<@files = `ls $directory`> [Severity 3]

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles>

Write C<open my $fh, q{<}, $filename;> instead of C<open FH, q{<}, $filename;> [Severity 5]

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect>

Never write C<select($fh)> [Severity 4]

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitReadlineInForLoop>

Write C<<while( $line = <> ){...}>> instead of C<<for(<>){...}>> [Severity 4]

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen>

Write C<open $fh, q{<}, $filename;> instead of C<open $fh, "<$filename";> [Severity 5]

=head2 L<Perl::Critic::Policy::Miscellanea::ProhibitFormats>

Do not use C<format>. [Severity 3]

=head2 L<Perl::Critic::Policy::Miscellanea::ProhibitTies>

Do not use C<tie>. [Severity 2]

=head2 L<Perl::Critic::Policy::Miscellanea::RequireRcsKeywords>

Put source-control keywords in every file. [Severity 2]

=head2 L<Perl::Critic::Policy::Modules::ProhibitMultiplePackages>

Put packages (especially subclasses) in separate files. [Severity 4]

=head2 L<Perl::Critic::Policy::Modules::RequireBarewordIncludes>

Write C<require Module> instead of C<require 'Module.pm'> [Severity 5]

=head2 L<Perl::Critic::Policy::Modules::ProhibitEvilModules>

Ban modules that aren't blessed by your shop. [Severity 5]

=head2 L<Perl::Critic::Policy::Modules::RequireExplicitPackage>

Always make the C<package> explicit. [Severity 4]

=head2 L<Perl::Critic::Policy::Modules::RequireVersionVar>

Give every module a C<$VERSION> number. [Severity 2]

=head2 L<Perl::Critic::Policy::Modules::RequireEndWithOne>

End each module with an explicitly C<1;> instead of some funky expression. [Severity 4]

=head2 L<Perl::Critic::Policy::NamingConventions::ProhibitAmbiguousNames>

Don't use vague variable or subroutine names like 'last' or 'record'. [Severity 3]

=head2 L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>

Write C<sub my_function{}> instead of C<sub MyFunction{}> [Severity 1]

=head2 L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>

Write C<$my_variable = 42> instead of C<$MyVariable = 42> [Severity 1]

=head2 L<Perl::Critic::Policy::References::ProhibitDoubleSigils>

Write C<@{ $array_ref }> instead of C<@$array_ref> [Severity 2]

=head2 L<Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching>

Always use the C</m> modifier with regular expressions. [Severity 3]

=head2 L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting>

Always use the C</x> modifier with regular expressions. [Severity 2]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils>

Don't call functions with a leading ampersand sigil. [Severity 2]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms>

Don't declare your own C<open> function. [Severity 4]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitExcessComplexity>

Minimize complexity by factoring code into smaller subroutines. [Severity 3]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef>

Return failure with bare C<return> instead of C<return undef> [Severity 5]

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes>

Don't write C<sub my_function (@@) {}> [Severity 5]

=head2 L<Perl::Critic::Policy::Subroutines::ProtectPrivateSubs>

Prevent access to private subs in other packages [Severity 3]

=head2 L<Perl::Critic::Policy::Subroutines::RequireFinalReturn>

End every path through a subroutine with an explicit C<return> statement. [Severity 4]

=head2 L<Perl::Critic::Policy::TestingAndDebugging::ProhibitNoStrict>

Prohibit various flavors of C<no strict> [Severity 5]

=head2 L<Perl::Critic::Policy::TestingAndDebugging::ProhibitNoWarnings>

Prohibit various flavors of C<no warnings> [Severity 4]

=head2 L<Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict>

Always C<use strict> [Severity 5]

=head2 L<Perl::Critic::Policy::TestingAndDebugging::RequireUseWarnings>

Always C<use warnings> [Severity 4]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

Don't C< use constant $FOO => 15 > [Severity 4]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes>

Write C<q{}> instead of C<''> [Severity 2]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>

Always use single quotes for literal strings. [Severity 1]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros>

Write C<oct(755)> instead of C<0755> [Severity 5]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitMixedBooleanOperators>

Write C< !$foo && $bar || $baz > instead of C< not $foo && $bar or $baz>

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes>

Use C<q{}> or C<qq{}> instead of quotes for awkward-looking strings. [Severity 2]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

Warns that you might have used single quotes when you really wanted double-quotes. [Severity 1]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators>

Write C< 141_234_397.0145 > instead of C< 141234397.0145 > [Severity 2]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator>

Write C< print <<'THE_END' > or C< print <<"THE_END" > [Severity 3]

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

Write C< <<'THE_END'; > instead of C< <<'theEnd'; > [Severity 1]

=head2 L<Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations>

Do not write C< my $foo = $bar if $baz; > [Severity 5]

=head2 L<Perl::Critic::Policy::Variables::ProhibitLocalVars>

Use C<my> instead of C<local>, except when you have to. [Severity 2]

=head2 L<Perl::Critic::Policy::Variables::ProhibitMatchVars>

Avoid C<$`>, C<$&>, C<$'> and their English equivalents. [Severity 4]

=head2 L<Perl::Critic::Policy::Variables::ProhibitPackageVars>

Eliminate globals declared with C<our> or C<use vars> [Severity 3]

=head2 L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

Write C<$EVAL_ERROR> instead of C<$@> [Severity 2]

=head2 L<Perl::Critic::Policy::Variables::ProtectPrivateVars>

Prevent access to private vars in other packages [Severity 3]

=head2 L<Perl::Critic::Policy::Variables::RequireInitializationForLocalVars>

Write C<local $foo = $bar;> instead of just C<local $foo;> [Severity 3]

=head1 BENDING THE RULES

Perl::Critic takes a hard-line approach to your code: either you
comply or you don't.  In the real world, it is not always practical
(or even possible) to fully comply with coding standards.  In such
cases, it is wise to show that you are knowingly violating the
standards and that you have a Damn Good Reason (DGR) for doing so.

To help with those situations, you can direct Perl::Critic to ignore
certain lines or blocks of code by using pseudo-pragmas:

    require 'LegacyLibaray1.pl';  ## no critic
    require 'LegacyLibrary2.pl';  ## no critic

    for my $element (@list) {

        ## no critic

        $foo = "";               #Violates 'ProhibitEmptyQuotes'
        $barf = bar() if $foo;   #Violates 'ProhibitPostfixControls'
        #Some more evil code...

        ## use critic

        #Some good code...
        do_something($_);
    }

The C<"## no critic"> comments direct Perl::Critic to ignore the
remaining lines of code until the end of the current block, or until a
C<"## use critic"> comment is found (whichever comes first).  If the
C<"## no critic"> comment is on the same line as a code statement,
then only that line of code is overlooked.  To direct perlcritic to
ignore the C<"## no critic"> comments, use the C<-force> option.

Use this feature wisely.  C<"## no critic"> should be used in the
smallest possible scope, or only on individual lines of code. If
Perl::Critic complains about your code, try and find a compliant
solution before resorting to this feature.

=head1 IMPORTANT CHANGES

Perl-Critic is evolving rapidly.  As such, some of the interfaces have
changed in ways that are not backward-compatible.  This will probably
concern you only if you're developing L<Perl::Critic::Policy> modules.

=head2 VERSION 0.11

Starting in version 0.11, the internal mechanics of Perl-Critic were
rewritten so that only one traversal of the PPI document tree is
required.  Unfortunately, this will break any custom Policy modules
that you might have written for earlier versions.  Converting your
policies to work with the new version is pretty easy and actually
results in cleaner code.  See L<DEVELOPER.pod> for an up-to-date guide
on creating Policy modules.

=head2 VERSION 0.14

Starting in version 0.14, the interface to L<Perl::Critic::Violation>
changed.  This will also break any custom Policy modules that you
might have written for earlier modules.  See L<DEVELOPER.pod> for an
up-to-date guide on creating Policy modules.

The notion of "priority" was also replaced with "severity" in version
0.14_02.  Consequently, the default behavior of Perl::Critic is to only
load the most "severe" Policy modules, rather than loading all of
them.  This decision was based on user-feedback suggesting that
Perl-Critic should be less "critical" for new users, and should steer
them toward gradually increasing the strictness as they adopt better
coding practices.

=head1 EXTENDING THE CRITIC

The modular design of Perl::Critic is intended to facilitate the
addition of new Policies.  You'll need to have some understanding of
L<PPI>, but most Policy modules are pretty straightforward and only
require about 20 lines of code.  Please see the
L<Perl::Critic::DEVELOPER> file included in this distribution for a
step-by-step demonstration of how to create new Policy modules.

If you develop any new Policy modules, feel free to send them to
<thaljef@cpan.org> and I'll be happy to put them into the Perl::Critic
distribution.  Or if you'd like to work on the Perl::Critic project
directly, check out our repository at L<http://perlcritic.tigris.org>.
To subscribe to our mailing list, send a message to
C<dev-subscribe@perlcritic.tigris.org>.

=head1 PREREQUISITES

Perl::Critic requires the following modules:

L<Config::Tiny>

L<File::Spec>

L<IO::String>

L<List::Util>

L<List::MoreUtils>

L<Module::Pluggable>

L<PPI>

L<Pod::Usage>

L<Pod::PlainText>

L<String::Format>

The following modules are optional, but recommended for complete
testing:

L<Test::Pod>

L<Test::Pod::Coverage>

L<Test::Perl::Critic>

=head1 BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you
find any bugs, particularly false-positives or false-negatives from a
Perl::Critic::Policy, please submit them to 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic>.  Thanks.

=head1 CREDITS

Adam Kennedy - For creating L<PPI>, the heart and soul of Perl::Critic.

Damian Conway - For writing B<Perl Best Practices>

Giuseppe Maxia - For all the great ideas and enhancements.

Chris Dolan - For numerous bug reports and suggestions.

Sharon, my wife - For putting up with my all-night code sessions

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
