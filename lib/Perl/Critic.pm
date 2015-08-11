package Perl::Critic;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use Exporter 'import';

use File::Spec;
use List::MoreUtils qw< firstidx >;
use Scalar::Util qw< blessed >;

use Perl::Critic::Exception::Configuration::Generic;
use Perl::Critic::Config;
use Perl::Critic::Violation;
use Perl::Critic::Document;
use Perl::Critic::Statistics;
use Perl::Critic::Utils qw< :characters hashify shebang_line >;

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

Readonly::Array our @EXPORT_OK => qw(critique);

#=============================================================================
# PUBLIC methods

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
    $self->{_config} = $args{-config} || Perl::Critic::Config->new( %args );
    $self->{_stats} = Perl::Critic::Statistics->new();
    return $self;
}

#-----------------------------------------------------------------------------

sub config {
    my $self = shift;
    return $self->{_config};
}

#-----------------------------------------------------------------------------

sub add_policy {
    my ( $self, @args ) = @_;
    #Delegate to Perl::Critic::Config
    return $self->config()->add_policy( @args );
}

#-----------------------------------------------------------------------------

sub policies {
    my $self = shift;

    #Delegate to Perl::Critic::Config
    return $self->config()->policies();
}

#-----------------------------------------------------------------------------

sub statistics {
    my $self = shift;
    return $self->{_stats};
}

#-----------------------------------------------------------------------------

sub critique {  ## no critic (ArgUnpacking)

    #-------------------------------------------------------------------
    # This subroutine can be called as an object method or as a static
    # function.  In the latter case, the first argument can be a
    # hashref of configuration parameters that shall be used to create
    # an object behind the scenes.  Note that this object does not
    # persist.  In other words, it is not a singleton.  Here are some
    # of the ways this subroutine might get called:
    #
    # #Object style...
    # $critic->critique( $code );
    #
    # #Functional style...
    # critique( $code );
    # critique( {}, $code );
    # critique( {-foo => bar}, $code );
    #------------------------------------------------------------------

    my ( $self, $source_code ) = @_ >= 2 ? @_ : ( {}, $_[0] );
    $self = ref $self eq 'HASH' ? __PACKAGE__->new(%{ $self }) : $self;
    return if not defined $source_code;  # If no code, then nothing to do.

    my $config = $self->config();
    my $doc =
        blessed($source_code) && $source_code->isa('Perl::Critic::Document')
            ? $source_code
            : Perl::Critic::Document->new(
                '-source' => $source_code,
                '-program-extensions' => [$config->program_extensions_as_regexes()],
            );

    if ( 0 == $self->policies() ) {
        Perl::Critic::Exception::Configuration::Generic->throw(
            message => 'There are no enabled policies.',
        )
    }

    return $self->_gather_violations($doc);
}

#=============================================================================
# PRIVATE methods

sub _gather_violations {
    my ($self, $doc) = @_;

    # Disable exempt code lines, if desired
    if ( not $self->config->force() ) {
        $doc->process_annotations();
    }

    # Evaluate each policy
    my @policies = $self->config->policies();
    my @ordered_policies = _futz_with_policy_order(@policies);
    my @violations = map { _critique($_, $doc) } @ordered_policies;

    # Accumulate statistics
    $self->statistics->accumulate( $doc, \@violations );

    # If requested, rank violations by their severity and return the top N.
    if ( @violations && (my $top = $self->config->top()) ) {
        my $limit = @violations < $top ? $#violations : $top-1;
        @violations = Perl::Critic::Violation::sort_by_severity(@violations);
        @violations = ( reverse @violations )[ 0 .. $limit ];  #Slicing...
    }

    # Always return violations sorted by location
    return Perl::Critic::Violation->sort_by_location(@violations);
}

#=============================================================================
# PRIVATE functions

sub _critique {
    my ($policy, $doc) = @_;

    return if not $policy->prepare_to_scan_document($doc);

    my $maximum_violations = $policy->get_maximum_violations_per_document();
    return if defined $maximum_violations && $maximum_violations == 0;

    my @violations = ();

  TYPE:
    for my $type ( $policy->applies_to() ) {
        my @elements;
        if ($type eq 'PPI::Document') {
            @elements = ($doc);
        }
        else {
            @elements = @{ $doc->find($type) || [] };
        }

      ELEMENT:
        for my $element (@elements) {

            # Evaluate the policy on this $element.  A policy may
            # return zero or more violations.  We only want the
            # violations that occur on lines that have not been
            # disabled.

          VIOLATION:
            for my $violation ( $policy->violates( $element, $doc ) ) {

                my $line = $violation->location()->[0];
                if ( $doc->line_is_disabled_for_policy($line, $policy) ) {
                    $doc->add_suppressed_violation($violation);
                    next VIOLATION;
                }

                push @violations, $violation;
                last TYPE if defined $maximum_violations and @violations >= $maximum_violations;
            }
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _futz_with_policy_order {
    # The ProhibitUselessNoCritic policy is another special policy.  It
    # deals with the violations that *other* Policies produce.  Therefore
    # it needs to be run *after* all the other Policies.  TODO: find
    # a way for Policies to express an ordering preference somehow.

    my @policy_objects = @_;
    my $magical_policy_name = 'Perl::Critic::Policy::Miscellanea::ProhibitUselessNoCritic';
    my $idx = firstidx {ref $_ eq $magical_policy_name} @policy_objects;
    push @policy_objects, splice @policy_objects, $idx, 1;
    return @policy_objects;
}

#-----------------------------------------------------------------------------

1;



__END__

=pod

=for stopwords DGR INI-style API -params pbp refactored ActivePerl ben Jore
Dolan's Twitter Alexandr Ciornii Ciornii's downloadable

=head1 NAME

Perl::Critic - Critique Perl source code for best-practices.


=head1 SYNOPSIS

    use Perl::Critic;
    my $file = shift;
    my $critic = Perl::Critic->new();
    my @violations = $critic->critique($file);
    print @violations;


=head1 DESCRIPTION

Perl::Critic is an extensible framework for creating and applying coding
standards to Perl source code.  Essentially, it is a static source code
analysis engine.  Perl::Critic is distributed with a number of
L<Perl::Critic::Policy> modules that attempt to enforce various coding
guidelines.  Most Policy modules are based on Damian Conway's book B<Perl Best
Practices>.  However, Perl::Critic is B<not> limited to PBP and will even
support Policies that contradict Conway.  You can enable, disable, and
customize those Polices through the Perl::Critic interface.  You can also
create new Policy modules that suit your own tastes.

For a command-line interface to Perl::Critic, see the documentation for
L<perlcritic>.  If you want to integrate Perl::Critic with your build process,
L<Test::Perl::Critic> provides an interface that is suitable for test
programs.  Also, L<Test::Perl::Critic::Progressive> is useful for gradually
applying coding standards to legacy code.  For the ultimate convenience (at
the expense of some flexibility) see the L<criticism> pragma.

If you'd like to try L<Perl::Critic> without installing anything, there is a
web-service available at L<http://perlcritic.com>.  The web-service does not
yet support all the configuration features that are available in the native
Perl::Critic API, but it should give you a good idea of what it does.

Also, ActivePerl includes a very slick graphical interface to Perl-Critic
called C<perlcritic-gui>.  You can get a free community edition of ActivePerl
from L<http://www.activestate.com>.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface will go
through a deprecation cycle.


=head1 CONSTRUCTOR

=over

=item C<< new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -top => $N, -only => $B, -profile-strictness => $PROFILE_STRICTNESS_{WARN|FATAL|QUIET}, -force => $B, -verbose => $N ], -color => $B, -pager => $string, -allow-unsafe => $B, -criticism-fatal => $B) >>

=item C<< new() >>

Returns a reference to a new Perl::Critic object.  Most arguments are just
passed directly into L<Perl::Critic::Config>, but I have described them here
as well.  The default value for all arguments can be defined in your
F<.perlcriticrc> file.  See the L<"CONFIGURATION"> section for more
information about that.  All arguments are optional key-value pairs as
follows:

B<-profile> is a path to a configuration file. If C<$FILE> is not defined,
Perl::Critic::Config attempts to find a F<.perlcriticrc> configuration file in
the current directory, and then in your home directory.  Alternatively, you
can set the C<PERLCRITIC> environment variable to point to a file in another
location.  If a configuration file can't be found, or if C<$FILE> is an empty
string, then all Policies will be loaded with their default configuration.
See L<"CONFIGURATION"> for more information.

B<-severity> is the minimum severity level.  Only Policy modules that have a
severity greater than C<$N> will be applied.  Severity values are integers
ranging from 1 (least severe violations) to 5 (most severe violations).  The
default is 5.  For a given C<-profile>, decreasing the C<-severity> will
usually reveal more Policy violations. You can set the default value for this
option in your F<.perlcriticrc> file.  Users can redefine the severity level
for any Policy in their F<.perlcriticrc> file.  See L<"CONFIGURATION"> for
more information.

If it is difficult for you to remember whether severity "5" is the most or
least restrictive level, then you can use one of these named values:

    SEVERITY NAME   ...is equivalent to...   SEVERITY NUMBER
    --------------------------------------------------------
    -severity => 'gentle'                     -severity => 5
    -severity => 'stern'                      -severity => 4
    -severity => 'harsh'                      -severity => 3
    -severity => 'cruel'                      -severity => 2
    -severity => 'brutal'                     -severity => 1

The names reflect how severely the code is criticized: a C<gentle> criticism
reports only the most severe violations, and so on down to a C<brutal>
criticism which reports even the most minor violations.

B<-theme> is special expression that determines which Policies to apply based
on their respective themes.  For example, the following would load only
Policies that have a 'bugs' AND 'pbp' theme:

  my $critic = Perl::Critic->new( -theme => 'bugs && pbp' );

Unless the C<-severity> option is explicitly given, setting C<-theme> silently
causes the C<-severity> to be set to 1.  You can set the default value for
this option in your F<.perlcriticrc> file.  See the L<"POLICY THEMES"> section
for more information about themes.


B<-include> is a reference to a list of string C<@PATTERNS>.  Policy modules
that match at least one C<m/$PATTERN/ixms> will always be loaded, irrespective
of all other settings.  For example:

    my $critic = Perl::Critic->new(-include => ['layout'] -severity => 4);

This would cause Perl::Critic to apply all the C<CodeLayout::*> Policy modules
even though they have a severity level that is less than 4. You can set the
default value for this option in your F<.perlcriticrc> file.  You can also use
C<-include> in conjunction with the C<-exclude> option.  Note that C<-exclude>
takes precedence over C<-include> when a Policy matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Policy modules
that match at least one C<m/$PATTERN/ixms> will not be loaded, irrespective of
all other settings.  For example:

    my $critic = Perl::Critic->new(-exclude => ['strict'] -severity => 1);

This would cause Perl::Critic to not apply the C<RequireUseStrict> and
C<ProhibitNoStrict> Policy modules even though they have a severity level that
is greater than 1.  You can set the default value for this option in your
F<.perlcriticrc> file.  You can also use C<-exclude> in conjunction with the
C<-include> option.  Note that C<-exclude> takes precedence over C<-include>
when a Policy matches both patterns.

B<-single-policy> is a string C<PATTERN>.  Only one policy that matches
C<m/$PATTERN/ixms> will be used.  Policies that do not match will be excluded.
This option has precedence over the C<-severity>, C<-theme>, C<-include>,
C<-exclude>, and C<-only> options.  You can set the default value for this
option in your F<.perlcriticrc> file.

B<-top> is the maximum number of Violations to return when ranked by their
severity levels.  This must be a positive integer.  Violations are still
returned in the order that they occur within the file. Unless the C<-severity>
option is explicitly given, setting C<-top> silently causes the C<-severity>
to be set to 1.  You can set the default value for this option in your
F<.perlcriticrc> file.

B<-only> is a boolean value.  If set to a true value, Perl::Critic will only
choose from Policies that are mentioned in the user's profile.  If set to a
false value (which is the default), then Perl::Critic chooses from all the
Policies that it finds at your site. You can set the default value for this
option in your F<.perlcriticrc> file.

B<-profile-strictness> is an enumerated value, one of
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_WARN"> (the default),
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">, and
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_QUIET">.  If set to
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">, Perl::Critic
will make certain warnings about problems found in a F<.perlcriticrc> or file
specified via the B<-profile> option fatal. For example, Perl::Critic normally
only C<warn>s about profiles referring to non-existent Policies, but this
value makes this situation fatal.  Correspondingly,
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_QUIET"> makes
Perl::Critic shut up about these things.

B<-force> is a boolean value that controls whether Perl::Critic observes the
magical C<"## no critic"> annotations in your code. If set to a true value,
Perl::Critic will analyze all code.  If set to a false value (which is the
default) Perl::Critic will ignore code that is tagged with these annotations.
See L<"BENDING THE RULES"> for more information.  You can set the default
value for this option in your F<.perlcriticrc> file.

B<-verbose> can be a positive integer (from 1 to 11), or a literal format
specification.  See L<Perl::Critic::Violation|Perl::Critic::Violation> for an
explanation of format specifications.  You can set the default value for this
option in your F<.perlcriticrc> file.

B<-unsafe> directs Perl::Critic to allow the use of Policies that are marked
as "unsafe" by the author.  Such policies may compile untrusted code or do
other nefarious things.

B<-color> and B<-pager> are not used by Perl::Critic but is provided for the
benefit of L<perlcritic|perlcritic>.

B<-criticism-fatal> is not used by Perl::Critic but is provided for the
benefit of L<criticism|criticism>.

B<-color-severity-highest>, B<-color-severity-high>, B<-color-severity-
medium>, B<-color-severity-low>, and B<-color-severity-lowest> are not used by
Perl::Critic, but are provided for the benefit of L<perlcritic|perlcritic>.
Each is set to the Term::ANSIColor color specification to be used to display
violations of the corresponding severity.

B<-files-with-violations> and B<-files-without-violations> are not used by
Perl::Critic, but are provided for the benefit of L<perlcritic|perlcritic>, to
cause only the relevant filenames to be displayed.

=back


=head1 METHODS

=over

=item C<critique( $source_code )>

Runs the C<$source_code> through the Perl::Critic engine using all the
Policies that have been loaded into this engine.  If C<$source_code> is a
scalar reference, then it is treated as a string of actual Perl code.  If
C<$source_code> is a reference to an instance of L<PPI::Document>, then that
instance is used directly. Otherwise, it is treated as a path to a local file
containing Perl code.  This method returns a list of
L<Perl::Critic::Violation> objects for each violation of the loaded Policies.
The list is sorted in the order that the Violations appear in the code.  If
there are no violations, this method returns an empty list.

=item C<< add_policy( -policy => $policy_name, -params => \%param_hash ) >>

Creates a Policy object and loads it into this Critic.  If the object cannot
be instantiated, it will throw a fatal exception.  Otherwise, it returns a
reference to this Critic.

B<-policy> is the name of a L<Perl::Critic::Policy> subclass module.  The
C<'Perl::Critic::Policy'> portion of the name can be omitted for brevity.
This argument is required.

B<-params> is an optional reference to a hash of Policy parameters. The
contents of this hash reference will be passed into to the constructor of the
Policy module.  See the documentation in the relevant Policy module for a
description of the arguments it supports.

=item C< policies() >

Returns a list containing references to all the Policy objects that have been
loaded into this engine.  Objects will be in the order that they were loaded.

=item C< config() >

Returns the L<Perl::Critic::Config> object that was created for or given to
this Critic.

=item C< statistics() >

Returns the L<Perl::Critic::Statistics> object that was created for this
Critic.  The Statistics object accumulates data for all files that are
analyzed by this Critic.

=back


=head1 FUNCTIONAL INTERFACE

For those folks who prefer to have a functional interface, The C<critique>
method can be exported on request and called as a static function.  If the
first argument is a hashref, its contents are used to construct a new
Perl::Critic object internally.  The keys of that hash should be the same as
those supported by the C<Perl::Critic::new()> method.  Here are some examples:

    use Perl::Critic qw(critique);

    # Use default parameters...
    @violations = critique( $some_file );

    # Use custom parameters...
    @violations = critique( {-severity => 2}, $some_file );

    # As a one-liner
    %> perl -MPerl::Critic=critique -e 'print critique(shift)' some_file.pm

None of the other object-methods are currently supported as static
functions.  Sorry.


=head1 CONFIGURATION

Most of the settings for Perl::Critic and each of the Policy modules can be
controlled by a configuration file.  The default configuration file is called
F<.perlcriticrc>.  Perl::Critic will look for this file in the current
directory first, and then in your home directory. Alternatively, you can set
the C<PERLCRITIC> environment variable to explicitly point to a different file
in another location.  If none of these files exist, and the C<-profile> option
is not given to the constructor, then all the modules that are found in the
Perl::Critic::Policy namespace will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks that
contain key-value pairs separated by '='. Comments should start with '#' and
can be placed on a separate line or after the name-value pairs if you desire.

Default settings for Perl::Critic itself can be set B<before the first named
block.> For example, putting any or all of these at the top of your
configuration file will set the default value for the corresponding
constructor argument.

    severity  = 3                                     #Integer or named level
    only      = 1                                     #Zero or One
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = (pbp || security) && bugs             #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list
    criticism-fatal = 1                               #Zero or One
    color     = 1                                     #Zero or One
    allow-unsafe = 1                                  #Zero or One
    pager     = less                                  #pager to pipe output to

The remainder of the configuration file is a series of blocks like this:

    [Perl::Critic::Policy::Category::PolicyName]
    severity = 1
    set_themes = foo bar
    add_themes = baz
    maximum_violations_per_document = 57
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Policy::Category::PolicyName> is the full name of a module
that implements the policy.  The Policy modules distributed with Perl::Critic
have been grouped into categories according to the table of contents in Damian
Conway's book B<Perl Best Practices>. For brevity, you can omit the
C<'Perl::Critic::Policy'> part of the module name.

C<severity> is the level of importance you wish to assign to the Policy.  All
Policy modules are defined with a default severity value ranging from 1 (least
severe) to 5 (most severe).  However, you may disagree with the default
severity and choose to give it a higher or lower severity, based on your own
coding philosophy.  You can set the C<severity> to an integer from 1 to 5, or
use one of the equivalent names:

    SEVERITY NAME ...is equivalent to... SEVERITY NUMBER
    ----------------------------------------------------
    gentle                                             5
    stern                                              4
    harsh                                              3
    cruel                                              2
    brutal                                             1

The names reflect how severely the code is criticized: a C<gentle> criticism
reports only the most severe violations, and so on down to a C<brutal>
criticism which reports even the most minor violations.

C<set_themes> sets the theme for the Policy and overrides its default theme.
The argument is a string of one or more whitespace-delimited alphanumeric
words.  Themes are case-insensitive.  See L<"POLICY THEMES"> for more
information.

C<add_themes> appends to the default themes for this Policy.  The argument is
a string of one or more whitespace-delimited words. Themes are case-
insensitive.  See L<"POLICY THEMES"> for more information.

C<maximum_violations_per_document> limits the number of Violations the Policy
will return for a given document.  Some Policies have a default limit; see the
documentation for the individual Policies to see whether there is one.  To
force a Policy to not have a limit, specify "no_limit" or the empty string for
the value of this parameter.

The remaining key-value pairs are configuration parameters that will be passed
into the constructor for that Policy.  The constructors for most Policy
objects do not support arguments, and those that do should have reasonable
defaults.  See the documentation on the appropriate Policy module for more
details.

Instead of redefining the severity for a given Policy, you can completely
disable a Policy by prepending a '-' to the name of the module in your
configuration file.  In this manner, the Policy will never be loaded,
regardless of the C<-severity> given to the Perl::Critic constructor.

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
    allow = if unless  # My custom configuration
    severity = cruel   # Same as "severity = 2"

    #--------------------------------------------------------------
    # Give these policies a custom theme.  I can activate just
    # these policies by saying `perlcritic -theme larry`

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = larry curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::Capitalization]
    [-ValuesAndExpressions::ProhibitMagicNumbers]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity,
    # so no additional configuration is required for them.

For additional configuration examples, see the F<perlcriticrc> file that is
included in this F<examples> directory of this distribution.

Damian Conway's own Perl::Critic configuration is also included in this
distribution as F<examples/perlcriticrc-conway>.


=head1 THE POLICIES

A large number of Policy modules are distributed with Perl::Critic. They are
described briefly in the companion document L<Perl::Critic::PolicySummary> and
in more detail in the individual modules themselves.  Say C<"perlcritic -doc
PATTERN"> to see the perldoc for all Policy modules that match the regex
C<m/PATTERN/ixms>

There are a number of distributions of additional policies on CPAN. If
L<Perl::Critic> doesn't contain a policy that you want, some one may have
already written it.  See the L</"SEE ALSO"> section below for a list of some
of these distributions.


=head1 POLICY THEMES

Each Policy is defined with one or more "themes".  Themes can be used to
create arbitrary groups of Policies.  They are intended to provide an
alternative mechanism for selecting your preferred set of Policies. For
example, you may wish disable a certain subset of Policies when analyzing test
programs.  Conversely, you may wish to enable only a specific subset of
Policies when analyzing modules.

The Policies that ship with Perl::Critic have been broken into the following
themes.  This is just our attempt to provide some basic logical groupings.
You are free to invent new themes that suit your needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All policies that ship with Perl::Critic
    pbp               Policies that come directly from "Perl Best Practices"
    bugs              Policies that that prevent or reveal bugs
    certrec           Policies that CERT recommends
    certrule          Policies that CERT considers rules
    maintenance       Policies that affect the long-term health of the code
    cosmetic          Policies that only have a superficial effect
    complexity        Policies that specificaly relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test programs


Any Policy may fit into multiple themes.  Say C<"perlcritic -list"> to get a
listing of all available Policies and the themes that are associated with each
one.  You can also change the theme for any Policy in your F<.perlcriticrc>
file.  See the L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> option, you can create an arbitrarily complex rule that
determines which Policies will be loaded.  Precedence is the same as regular
Perl code, and you can use parentheses to enforce precedence as well.
Supported operators are:

    Operator    Alternative    Example
    -----------------------------------------------------------------
    &&          and            'pbp && core'
    ||          or             'pbp || (bugs && security)'
    !           not            'pbp && ! (portability || complexity)'

Theme names are case-insensitive.  If the C<-theme> is set to an empty string,
then it evaluates as true all Policies.


=head1 BENDING THE RULES

Perl::Critic takes a hard-line approach to your code: either you comply or you
don't.  In the real world, it is not always practical (nor even possible) to
fully comply with coding standards.  In such cases, it is wise to show that
you are knowingly violating the standards and that you have a Damn Good Reason
(DGR) for doing so.

To help with those situations, you can direct Perl::Critic to ignore certain
lines or blocks of code by using annotations:

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

The C<"## no critic"> annotations direct Perl::Critic to ignore the remaining
lines of code until a C<"## use critic"> annotation is found. If the C<"## no
critic"> annotation is on the same line as a code statement, then only that
line of code is overlooked.  To direct perlcritic to ignore the C<"## no
critic"> annotations, use the C<--force> option.

A bare C<"## no critic"> annotation disables all the active Policies.  If you
wish to disable only specific Policies, add a list of Policy names as
arguments, just as you would for the C<"no strict"> or C<"no warnings">
pragmas.  For example, this would disable the C<ProhibitEmptyQuotes> and
C<ProhibitPostfixControls> policies until the end of the block or until the
next C<"## use critic"> annotation (whichever comes first):

    ## no critic (EmptyQuotes, PostfixControls)

    # Now exempt from ValuesAndExpressions::ProhibitEmptyQuotes
    $foo = "";

    # Now exempt ControlStructures::ProhibitPostfixControls
    $barf = bar() if $foo;

    # Still subjected to ValuesAndExpression::RequireNumberSeparators
    $long_int = 10000000000;

Since the Policy names are matched against the C<"## no critic"> arguments as
regular expressions, you can abbreviate the Policy names or disable an entire
family of Policies in one shot like this:

    ## no critic (NamingConventions)

    # Now exempt from NamingConventions::Capitalization
    my $camelHumpVar = 'foo';

    # Now exempt from NamingConventions::Capitalization
    sub camelHumpSub {}

The argument list must be enclosed in parentheses or brackets and must contain
one or more comma-separated barewords (e.g. don't use quotes).
The C<"## no critic"> annotations can be nested, and Policies named by an inner
annotation will be disabled along with those already disabled an outer
annotation.

Some Policies like C<Subroutines::ProhibitExcessComplexity> apply to an entire
block of code.  In those cases, the C<"## no critic"> annotation must appear
on the line where the violation is reported.  For example:

    sub complicated_function {  ## no critic (ProhibitExcessComplexity)
        # Your code here...
    }

Policies such as C<Documentation::RequirePodSections> apply to the entire
document, in which case violations are reported at line 1.

Use this feature wisely.  C<"## no critic"> annotations should be used in the
smallest possible scope, or only on individual lines of code. And you should
always be as specific as possible about which Policies you want to disable
(i.e. never use a bare C<"## no critic">).  If Perl::Critic complains about
your code, try and find a compliant solution before resorting to this feature.


=head1 THE L<Perl::Critic> PHILOSOPHY

Coding standards are deeply personal and highly subjective.  The goal of
Perl::Critic is to help you write code that conforms with a set of best
practices.  Our primary goal is not to dictate what those practices are, but
rather, to implement the practices discovered by others.  Ultimately, you make
the rules -- Perl::Critic is merely a tool for encouraging consistency.  If
there is a policy that you think is important or that we have overlooked, we
would be very grateful for contributions, or you can simply load your own
private set of policies into Perl::Critic.


=head1 EXTENDING THE CRITIC

The modular design of Perl::Critic is intended to facilitate the addition of
new Policies.  You'll need to have some understanding of L<PPI>, but most
Policy modules are pretty straightforward and only require about 20 lines of
code.  Please see the L<Perl::Critic::DEVELOPER> file included in this
distribution for a step-by-step demonstration of how to create new Policy
modules.

If you develop any new Policy modules, feel free to send them to C<<
<team@perlcritic.com> >> and I'll be happy to consider putting them into the
Perl::Critic distribution.  Or if you would like to work on the Perl::Critic
project directly, you can fork our repository at L<http://github.com/Perl-
Critic/Perl- Critic.git>.

The Perl::Critic team is also available for hire.  If your organization has
its own coding standards, we can create custom Policies to enforce your local
guidelines.  Or if your code base is prone to a particular defect pattern, we
can design Policies that will help you catch those costly defects B<before>
they go into production. To discuss your needs with the Perl::Critic team,
just contact C<< <team@perlcritic.com> >>.


=head1 PREREQUISITES

Perl::Critic requires the following modules:

L<B::Keywords>

L<Config::Tiny>

L<Email::Address>

L<Exception::Class>

L<File::HomeDir>

L<File::Spec>

L<File::Spec::Unix>

L<File::Which>

L<IO::String>

L<List::MoreUtils>

L<List::Util>

L<Module::Pluggable>

L<Perl::Tidy>

L<Pod::Spell>

L<PPI|PPI>

L<Pod::PlainText>

L<Pod::Select>

L<Pod::Usage>

L<Readonly>

L<Scalar::Util>

L<String::Format>

L<Task::Weaken>

L<Term::ANSIColor>

L<Text::ParseWords>

L<version|version>


=head1 CONTACTING THE DEVELOPMENT TEAM

You are encouraged to subscribe to the mailing list; send a message to
L<mailto:users-subscribe@perlcritic.tigris.org>.  To prevent spam, you may be
required to register for a user account with Tigris.org before being allowed
to post messages to the mailing list. See also the mailing list archives at
L<http://perlcritic.tigris.org/servlets/SummarizeList?listName=users>. At
least one member of the development team is usually hanging around in
L<irc://irc.perl.org/#perlcritic> and you can follow Perl::Critic on Twitter,
at L<https://twitter.com/perlcritic>.


=head1 SEE ALSO

There are a number of distributions of additional Policies available. A few
are listed here:

L<Perl::Critic::More>

L<Perl::Critic::Bangs>

L<Perl::Critic::Lax>

L<Perl::Critic::StricterSubs>

L<Perl::Critic::Swift>

L<Perl::Critic::Tics>

These distributions enable you to use Perl::Critic in your unit tests:

L<Test::Perl::Critic>

L<Test::Perl::Critic::Progressive>

There is also a distribution that will install all the Perl::Critic related
modules known to the development team:

L<Task::Perl::Critic>


=head1 BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you find
any bugs, particularly false-positives or false-negatives from a
Perl::Critic::Policy, please submit them at L<https://github.com/Perl-Critic
/Perl-Critic/issues>.  Thanks.

=head1 CREDITS

Adam Kennedy - For creating L<PPI>, the heart and soul of L<Perl::Critic>.

Damian Conway - For writing B<Perl Best Practices>, finally :)

Chris Dolan - For contributing the best features and Policy modules.

Andy Lester - Wise sage and master of all-things-testing.

Elliot Shank - The self-proclaimed quality freak.

Giuseppe Maxia - For all the great ideas and positive encouragement.

and Sharon, my wife - For putting up with my all-night code sessions.

Thanks also to the Perl Foundation for providing a grant to support Chris
Dolan's project to implement twenty PBP policies.
L<http://www.perlfoundation.org/april_1_2007_new_grant_awards>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2013 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
