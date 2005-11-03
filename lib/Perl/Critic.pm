package Perl::Critic;

use strict;
use warnings;
use File::Spec;
use English qw(-no_match_vars);
use Perl::Critic::Config;
use Perl::Critic::Utils;
use Carp;
use PPI;

our $VERSION = '0.13';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------
#
sub new {

    my ( $class, %args ) = @_;

    # Default arguments
    my $priority     = defined $args{-priority} ? $args{-priority} : 0;
    my $profile_path = $args{-profile};
    my $force        = $args{-force} || 0;

    # Create and init object
    my $self = bless {}, $class;
    $self->{_force}    = $force;
    $self->{_policies} = [];

    # Read profile and add policies
    my $config = Perl::Critic::Config->new( %args );
    while ( my ( $policy, $params ) = each %{$config} ) {
        $self->add_policy( -policy => $policy, -config => $params );
    }
    return $self;
}

#----------------------------------------------------------------------------
#
sub add_policy {

    my ( $self, %args ) = @_;
    my $module_name = $args{-policy} || return;
    my $config      = $args{-config} || {};

    #Qualify name if full module name not given
    my $namespace = 'Perl::Critic::Policy';
    if ( $module_name !~ m{ \A $namespace }mx ) {
        $module_name = $namespace . q{::} . $module_name;
    }

    #Convert module name to file path.  I'm trying to do
    #this in a portable way, but I'm not sure it actually is.
    my $module_file = File::Spec->catfile( split q{::}, $module_name );
    $module_file .= '.pm';

    #Try to load module and instantiate
    eval {
        require $module_file;    ## no critic
        my $policy = $module_name->new( %{$config} );
        push @{ $self->{_policies} }, $policy;
    };

    #Failure to load is not fatal
    if ($EVAL_ERROR) {
        carp qq{Cannot load policy module $module_name: $EVAL_ERROR};
        return;
    }

    return $self;
}

#----------------------------------------------------------------------------
#
sub critique {
    # Here we go!
    my ( $self, $source_code ) = @_;

    # Parse the code
    my $doc = PPI::Document->new($source_code);

    # Bail on error
    if( ! defined $doc ) {
	my $errstr = PPI::Document::errstr();
	my $file = -f $source_code ? $source_code : 'stdin';
	die qq{Cannot parse code: $errstr of '$file'\n};
    }

    # Pre-index location of each node (for speed)
    $doc->index_locations();

    # Filter exempt code, if desired
    $self->{_force} ||  _filter_code($doc);

    # Remove the magic shebang fix
    _unfix_shebang($doc);

    # Run engine, testing each Policy at each element
    my $elems = $doc->find( 'PPI::Element' )   || return;   #Nothing to do!
    my @pols  = @{ $self->policies() };  @pols || return;   #Nothing to do! 
    return map { my $e = $_; map { $_->violates($e, $doc) } @pols } @{$elems};
}

#----------------------------------------------------------------------------
#
sub policies { $_[0]->{_policies} }

#============================================================================
#PRIVATE SUBS

sub _filter_code {

    my $doc        = shift;
    my $nodes_ref  = $doc->find('PPI::Token::Comment') || return;
    my $no_critic  = qr{\A \s* \#\# \s* no  \s+ critic}mx;
    my $use_critic = qr{\A \s* \#\# \s* use \s+ critic}mx;

  PRAGMA:
    for my $pragma ( grep { $_ =~ $no_critic } @{$nodes_ref} ) {

        #Handle single-line usage
        if ( my $sib = $pragma->sprevious_sibling() ) {
            if ( $sib->location->[0] == $pragma->location->[0] ) {
                $sib->statement->delete();
                next PRAGMA;
            }
        }

      SIB:
        while ( my $sib = $pragma->next_sibling() ) {
            my $ended = $sib->isa('PPI::Token::Comment') && $sib =~ $use_critic;
            $sib->delete();    #$sib is undef now.
            last SIB if $ended;
        }
    }
    continue {
        $pragma->delete();
    }
}
 
sub _unfix_shebang {


    #When you install a script using ExtUtils::MakeMaker or
    #Module::Build, it inserts some magical code into the top of the
    #file (just after the shebang).  This code allows people to call
    #your script using a shell, like `sh my_script`.  Unfortunately,
    #this code causes several Policy violations, so we just remove it.

    my $doc = shift;
    my $first_stmnt = $doc->schild(0) || return;


    #Different versions of MakeMaker and Build use slightly differnt
    #shebang fixing strings.  This matches most of the ones I've found
    #in my own Perl distribution, but it may not be bullet-proof.

    my $fixin_rx = qr{^eval 'exec .* \$0 \${1\+"\$@"}'\s*[\r\n]\s*if.+;};
    if ( $first_stmnt =~ $fixin_rx ) { $first_stmnt->delete() }
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic - Critique Perl source for style and standards

=head1 SYNOPSIS

  use Perl::Critic;

  #Create Critic and load Policies from default config file
  $critic = Perl::Critic->new();

  #Create Critic and load only the most important Polices
  $critic = Perl::Critic->new(-priority => 1);

  #Create Critic and load Policies from specific config file
  $critic = Perl::Critic->new(-profile => $file);

  #Create Critic and load Policy by hand
  $critic = Perl::Critic->new(-profile => 'NONE');
  $critic->add_policy('MyPolicyModule');

  #Analyze code for policy violations
  @violations = $critic->critique($source_code);

=head1 DESCRIPTION

Perl::Critic is an extensible framework for creating and applying
coding standards to Perl source code.  Essentially, it is a static
source code analysis engine.  Perl::Critic is distributed with a
number of L<Perl::Critic::Policy> modules that attempt to enforce
various coding guidelines.  Most Policies are based on Damian Conway's
book B<Perl Best Practices>.  You can choose and customize those
Polices through the Perl::Critic interface.  You can also create new
Policy modules that suit your own tastes.

For a convenient command-line interface to Perl::Critic, see the
documentation for L<perlcritic>.  If you want to integrate
Perl::Critic with your build process, L<Test::Perl::Critic> provides a
nice interface that is suitable for test scripts.

=head1 CONSTRUCTOR

=over 8

=item new ( [ -profile => $FILE, -priority => $N, -include => \@PATTERNS, -exclude => \@PATTERNS, -force => 1 ] )

Returns a reference to a new Perl::Critic object.  Most arguments are
just passed directly into L<Perl::Critic::Config>, but I have described
them here as well.  All arguments are optional key-value pairs as
follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not
defined, Perl::Critic::Config attempts to find a F<.perlcriticrc>
configuration file in the current directory, and then in your home
directory.  Alternatively, you can set the C<PERLCRITIC> environment
variable to point to a file in another location.  If a configuration
file can't be found, or if C<$FILE> is an empty string, then it
defaults to include all the Policy modules that ship with
Perl::Critic.  See L<"CONFIGURATION"> for more information.

B<-priority> is the maximum priority value of Policies that should be
added to the Perl::Critic::Config.  1 is the "highest" priority,
and all numbers larger than 1 have "lower" priority. Once the
user-preferences have been read from the C<-profile>, All Policies
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
the Config.  Using the C<-exclude> option causes the <-priority>
option to be ignored.  The C<-exclude> patterns are applied after the
<-include> patterns, therefore, the C<-exclude> patterns take
precedence.

B<-force> controls whether Perl::Critic observes the magical C<"no
critic"> pseudo-pragmas in your code.  If set to a true value,
Perl::Critic will analyze all code.  If set to a false value (which is
the default) Perl::Critic will overlook code that is tagged with these
comments.  See L<"BENDING THE RULES"> for more information.

=back

=head1 METHODS

=over 8

=item add_policy( -policy => $STRING [, -config => \%HASH ] )

Loads a Policy into this Critic engine.  The engine will attempt to
C<require> the module named by $STRING and instantiate it. If the
module fails to load or cannot be instantiated, it will throw a
warning and return a false value.  Otherwise, it returns a reference
to this Critic engine.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass
module.  The C<'Perl::Critic::Policy'> portion of the name can be
omitted for brevity.  This argument is required.

B<-config> is an optional reference to a hash of Policy configuration
parameters (Note that this is B<not> a Perl::Critic::Config object). The
contents of this hash reference will be passed into to the constructor
of the Policy module.  See the documentation in the relevant Policy
module for a description of the arguments it supports.

=item critique( $source_code )

Runs the C<$source_code> through the Perl::Critic engine using all the
policies that have been loaded into this engine.  If C<$source_code>
is a scalar reference, then it is treated as string of actual Perl
code.  Otherwise, it is treated as a path to a file containing Perl
code.  Returns a list of L<Perl::Critic::Violation> objects for each
violation of the loaded Policies.  The list is sorted in the order
that the Violations appear in the code.  If there are no violations,
returns an empty list.

=item policies( void )

Returns a list containing references to all the Policy objects that
have been loaded into this engine.  Objects will be in the order that
they were loaded.

=back

=head1 CONFIGURATION

The default configuration file is called F<.perlcriticrc>.
Perl::Critic::Config will look for this file in the current directory
first, and then in your home directory.  Alternatively, you can set
the PERLCRITIC environment variable to explicitly point to a different
file in another location.  If none of these files exist, and the
C<-profile> option is not given to the constructor,
Perl::Critic::Config defaults to include all the policies that are
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
brevity, you can omit the C<'Perl::Critic::Policy'> part of the
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

=head1 THE POLICIES

The following Policy modules are distributed with Perl::Critic.  The
Policy modules have been categorized according to the table of
contents in Damian Conway's book B<Perl Best Practices>.  Since most
coding standards take the form "do this..." or "don't do that...", I
have adopted the convention of naming each module C<RequireSomething>
or C<ProhibitSomething>.  See the documentation of each module for
it's specific details.

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr>

Use 4-argument C<substr> instead of writing C<substr($foo, 2, 6) = $bar>

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitSleepViaSelect>

Use L<Time::HiRes> instead of C<select(undef, undef, undef, .05)>

=head2 L<Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval>

Write C<eval { my $foo; bar($foo) }> instead of C<eval "my $foo; bar($foo);">

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockGrep>

Write C<grep { $_ =~ /$pattern/ } @list> instead of C<grep /$pattern/, @list>

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireBlockMap>

Write C<map { $_ =~ /$pattern/ } @list> instead of C<map /$pattern/, @list>

=head2 L<Perl::Critic::Policy::BuiltinFunctions::RequireGlobFunction>

Use C<glob q{*}> instead of <*>

=head2 L<Perl::Critic::Policy::ClassHierarchies::ProhibitOneArgBless>

Write C<bless {}, $class;> instead of just C<bless {};>

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitHardTabs>

Use spaces instead of tabs

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitParensWithBuiltins>

Write C<open $handle, $path> instead of C<open($handle, $path)>

=head2 L<Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists>

Write C< qw(foo bar baz) > instead of C< ('foo', 'bar', 'baz') >

=head2 L<Perl::Critic::Policy::CodeLayout::RequireTidyCode>

Must run code through L<perltidy>

=head2 L<Perl::Critic::Policy::CodeLayout::RequireTrailingCommas>

Put a comma at the end of every multi-line list declaration, including the last one

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitCascadingIfElse>

Don't write long "if-elsif-elsif-elsif-elsif...else" chains

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops>

Write C<for(0..20)> instead of C<for($i=0; $i<=20; $i++)>

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitPostfixControls>

Write C<if($condition){ do_something() }> instead of C<do_something() if $condition>

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks>

Write C<if(! $condition)> instead of C<unless($condition)>

=head2 L<Perl::Critic::Policy::ControlStructures::ProhibitUntilBlocks>

Write C<while(! $condition)> instead of C<until($condition)>

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitBacktickOperators>

Discourage stuff like C<@files = `ls $directory`>

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles>

Write C<open my $fh, q{<}, $filename;> instead of C<open FH, q{<}, $filename;>

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitOneArgSelect>

Never write C<select($fh)>

=head2 L<Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen>

Write C<open $fh, q{<}, $filename;> instead of C<open $fh, "<$filename";>

=head2 L<Perl::Critic::Policy::Miscellanea::RequireRcsKeywords>

Put source-control keywords in every file.

=head2 L<Perl::Critic::Policy::Modules::ProhibitMultiplePackages>

Put packages (especially subclasses) in separate files

=head2 L<Perl::Critic::Policy::Modules::RequireBarewordIncludes>

Write C<require Module> instead of C<require 'Module.pm'>

=head2 L<Perl::Critic::Policy::Modules::ProhibitSpecificModules>

Don't use evil modules

=head2 L<Perl::Critic::Policy::Modules::RequireExplicitPackage>

Always make the C<package> explicit

=head2 L<Perl::Critic::Policy::Modules::RequireVersionVar>

Give every module a C<$VERSION> number

=head2 L<Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching>

Always use the C</m> modifier with regular expressions

=head2 L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting>

Always use the C</x> modifier with regular expressions

=head2 L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>

Write C<sub my_function{}> instead of C<sub MyFunction{}>

=head2 L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>

Write C<$my_variable = 42> instead of C<$MyVariable = 42>

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitBuiltinHomonyms>

Don't declare your own C<open> function.

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef>

Return failure with bare C<return> instead of C<return undef>

=head2 L<Perl::Critic::Policy::Subroutines::ProhibitSubroutinePrototypes>

Don't write C<sub my_function (@@) {}>

=head2 L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageStricture>

Always C<use strict>

=head2 L<Perl::Critic::Policy::TestingAndDebugging::RequirePackageWarnings>

Always C<use warnings>

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

Don't C< use constant $FOO => 15 >

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes>

Write C<q{}> instead of C<''>

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>

Always use single quotes for literal strings.

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitLeadingZeros>

Write C<oct(755)> instead of C<0755>

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyQuotes>

Use C<q{}> or C<qq{}> instead of quotes for awkward-looking strings

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

Warns that you might have used single quotes when you really wanted double-quotes.

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators>

Write C< 141_234_397.0145 > instead of C< 141234397.0145 >

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator>

Write C< print <<'THE_END' > or C< print <<"THE_END" >

=head2 L<Perl::Critic::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

Write C< <<'THE_END'; > instead of C< <<'theEnd'; >

=head2 L<Perl::Critic::Policy::Variables::ProhibitLocalVars>

Use C<my> instead of C<local>, except when you have to.

=head2 L<Perl::Critic::Policy::Variables::ProhibitPackageVars>

Eliminate globals declared with C<our> or C<use vars>

=head2 L<Perl::Critic::Policy::Variables::ProhibitPunctuationVars>

Write C<$EVAL_ERROR> instead of C<$@>

=head1 BENDING THE RULES

B<NOTE:> This feature changed in version 0.09 and is not backward
compatible with earlier versions.

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

The C<"## no critic"> comments direct Perl::Critic to overlook the
remaining lines of code until the end of the current block, or until a
C<"## use critic"> comment is found (whichever comes first).  If the
C<"## no critic"> comment is on the same line as a code statement,
then only that line of code is overlooked.  To direct perlcritic to
ignore the C<"## no critic"> comments, use the C<-force> option.

Use this feature wisely.  C<"## no critic"> should be used in the
smallest possible scope, or only on individual lines of code. If
Perl::Critic complains about your code, try and find a compliant
solution before resorting to this feature.

=head1 EXTENDING THE CRITIC

The modular design of Perl::Critic is intended to facilitate the
addition of new Policies.  To create a new Policy, make a subclass of
L<Perl::Critic::Policy> and override the C<violates()> method.  Your
module should go somewhere in the Perl::Critic::Policy namespace.  To
use the new Policy, just add it to your F<.perlcriticrc> file.  You'll
need to have some understanding of L<PPI>, but most Policy modules are
pretty straightforward and only require about 20 lines of code.

If you develop any new Policy modules, feel free to send them to
<thaljef@cpan.org> and I'll be happy to put them into the Perl::Critic
distribution.

=head1 IMPORTANT CHANGES

As new Policy modules were added to Perl::Critic, the overall
performance started to deteriorate rapidly.  Since each module would
traverse the document (several times for some modules), a lot of time
was spent iterating over the same document nodes.  So starting in
version 0.11, I have switched to a stream-based approach where the
document is traversed once and every Policy module is tested at each
node.  The result is roughly a 300% improvement.  

Unfortunately, Policy modules prior to version 0.11 won't be
compatible.  Hopefully, few people have started creating their own
Policy modules.  Converting them to the stream-based model is fairly
easy, and actually results in somewhat cleaner code.  Look at the
ControlStrucutres::* modules for some examples.

=head1 PREREQUISITES

Perl::Critic requires the following modules:

L<PPI>

L<Config::Tiny>

L<File::Spec>

L<List::Util>

L<List::MoreUtils>

L<Pod::Usage>

L<Pod::PlainText>

L<IO::String>

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

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
