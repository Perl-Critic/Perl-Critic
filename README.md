# BUILD STATUS

* [![Build Status](https://github.com/Perl-Critic/Perl-Critic/workflows/testsuite/badge.svg?branch=dev)](https://github.com/Perl-Critic/Perl-Critic/actions?query=workflow%3Atestsuite+branch%3Adev)
* [CPAN Testers](http://cpantesters.org/distro/P/Perl-Critic.html)

# NAME

Perl::Critic - Critique Perl source code for best-practices.

# SYNOPSIS

    use Perl::Critic;
    my $file = shift;
    my $critic = Perl::Critic->new();
    my @violations = $critic->critique($file);
    print @violations;

# DESCRIPTION

Perl::Critic is an extensible framework for creating and applying coding
standards to Perl source code.  Essentially, it is a static source code
analysis engine.  Perl::Critic is distributed with a number of
[Perl::Critic::Policy](https://metacpan.org/pod/Perl::Critic::Policy) modules that attempt to enforce various coding
guidelines.  Most Policy modules are based on Damian Conway's book **Perl Best
Practices**.  However, Perl::Critic is **not** limited to PBP and will even
support Policies that contradict Conway.  You can enable, disable, and
customize those Polices through the Perl::Critic interface.  You can also
create new Policy modules that suit your own tastes.

For a command-line interface to Perl::Critic, see the documentation for
[perlcritic](https://metacpan.org/pod/perlcritic).  If you want to integrate Perl::Critic with your build process,
[Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic) provides an interface that is suitable for test
programs.  Also, [Test::Perl::Critic::Progressive](https://metacpan.org/pod/Test::Perl::Critic::Progressive) is useful for gradually
applying coding standards to legacy code.  For the ultimate convenience (at
the expense of some flexibility) see the [criticism](https://metacpan.org/pod/criticism) pragma.

If you'd like to try [Perl::Critic](https://metacpan.org/pod/Perl::Critic) without installing anything, there is a
web-service available at [http://perlcritic.com](http://perlcritic.com).  The web-service does not
yet support all the configuration features that are available in the native
Perl::Critic API, but it should give you a good idea of what it does.

Also, ActivePerl includes a very slick graphical interface to Perl-Critic
called `perlcritic-gui`.  You can get a free community edition of ActivePerl
from [http://www.activestate.com](http://www.activestate.com).

# PREREQUISITES

Perl::Critic runs on Perl back to Perl 5.6.1. It relies on the [PPI](https://metacpan.org/pod/PPI)
module to do the heavy work of parsing Perl.

# INTERFACE SUPPORT

The `Perl::Critic` module is considered to be a public class. Any
changes to its interface will go through a deprecation cycle.

# CONSTRUCTOR

- `new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -top => $N, -only => $B, -profile-strictness => $PROFILE_STRICTNESS_{WARN|FATAL|QUIET}, -force => $B, -verbose => $N ], -color => $B, -pager => $string, -allow-unsafe => $B, -criticism-fatal => $B)`
- `new()`

    Returns a reference to a new Perl::Critic object.  Most arguments are just
    passed directly into [Perl::Critic::Config](https://metacpan.org/pod/Perl::Critic::Config), but I have described them here
    as well.  The default value for all arguments can be defined in your
    `.perlcriticrc` file.  See the ["CONFIGURATION"](#configuration) section for more
    information about that.  All arguments are optional key-value pairs as
    follows:

    **-profile** is a path to a configuration file. If `$FILE` is not defined,
    Perl::Critic::Config attempts to find a `.perlcriticrc` configuration file in
    the current directory, and then in your home directory.  Alternatively, you
    can set the `PERLCRITIC` environment variable to point to a file in another
    location.  If a configuration file can't be found, or if `$FILE` is an empty
    string, then all Policies will be loaded with their default configuration.
    See ["CONFIGURATION"](#configuration) for more information.

    **-severity** is the minimum severity level.  Only Policy modules that have a
    severity greater than `$N` will be applied.  Severity values are integers
    ranging from 1 (least severe violations) to 5 (most severe violations).  The
    default is 5.  For a given `-profile`, decreasing the `-severity` will
    usually reveal more Policy violations. You can set the default value for this
    option in your `.perlcriticrc` file.  Users can redefine the severity level
    for any Policy in their `.perlcriticrc` file.  See ["CONFIGURATION"](#configuration) for
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

    The names reflect how severely the code is criticized: a `gentle` criticism
    reports only the most severe violations, and so on down to a `brutal`
    criticism which reports even the most minor violations.

    **-theme** is special expression that determines which Policies to apply based
    on their respective themes.  For example, the following would load only
    Policies that have a 'bugs' AND 'pbp' theme:

        my $critic = Perl::Critic->new( -theme => 'bugs && pbp' );

    Unless the `-severity` option is explicitly given, setting `-theme` silently
    causes the `-severity` to be set to 1.  You can set the default value for
    this option in your `.perlcriticrc` file.  See the ["POLICY THEMES"](#policy-themes) section
    for more information about themes.

    **-include** is a reference to a list of string `@PATTERNS`.  Policy modules
    that match at least one `m/$PATTERN/ixms` will always be loaded, irrespective
    of all other settings.  For example:

        my $critic = Perl::Critic->new(-include => ['layout'], -severity => 4);

    This would cause Perl::Critic to apply all the `CodeLayout::*` Policy modules
    even though they have a severity level that is less than 4. You can set the
    default value for this option in your `.perlcriticrc` file.  You can also use
    `-include` in conjunction with the `-exclude` option.  Note that `-exclude`
    takes precedence over `-include` when a Policy matches both patterns.

    **-exclude** is a reference to a list of string `@PATTERNS`.  Policy modules
    that match at least one `m/$PATTERN/ixms` will not be loaded, irrespective of
    all other settings.  For example:

        my $critic = Perl::Critic->new(-exclude => ['strict'], -severity => 1);

    This would cause Perl::Critic to not apply the `RequireUseStrict` and
    `ProhibitNoStrict` Policy modules even though they have a severity level that
    is greater than 1.  You can set the default value for this option in your
    `.perlcriticrc` file.  You can also use `-exclude` in conjunction with the
    `-include` option.  Note that `-exclude` takes precedence over `-include`
    when a Policy matches both patterns.

    **-single-policy** is a string `PATTERN`.  Only one policy that matches
    `m/$PATTERN/ixms` will be used.  Policies that do not match will be excluded.
    This option has precedence over the `-severity`, `-theme`, `-include`,
    `-exclude`, and `-only` options.  You can set the default value for this
    option in your `.perlcriticrc` file.

    **-top** is the maximum number of Violations to return when ranked by their
    severity levels.  This must be a positive integer.  Violations are still
    returned in the order that they occur within the file. Unless the `-severity`
    option is explicitly given, setting `-top` silently causes the `-severity`
    to be set to 1.  You can set the default value for this option in your
    `.perlcriticrc` file.

    **-only** is a boolean value.  If set to a true value, Perl::Critic will only
    choose from Policies that are mentioned in the user's profile.  If set to a
    false value (which is the default), then Perl::Critic chooses from all the
    Policies that it finds at your site. You can set the default value for this
    option in your `.perlcriticrc` file.

    **-profile-strictness** is an enumerated value, one of
    ["$PROFILE\_STRICTNESS\_WARN" in Perl::Critic::Utils::Constants](https://metacpan.org/pod/Perl::Critic::Utils::Constants#PROFILE_STRICTNESS_WARN) (the default),
    ["$PROFILE\_STRICTNESS\_FATAL" in Perl::Critic::Utils::Constants](https://metacpan.org/pod/Perl::Critic::Utils::Constants#PROFILE_STRICTNESS_FATAL), and
    ["$PROFILE\_STRICTNESS\_QUIET" in Perl::Critic::Utils::Constants](https://metacpan.org/pod/Perl::Critic::Utils::Constants#PROFILE_STRICTNESS_QUIET).  If set to
    ["$PROFILE\_STRICTNESS\_FATAL" in Perl::Critic::Utils::Constants](https://metacpan.org/pod/Perl::Critic::Utils::Constants#PROFILE_STRICTNESS_FATAL), Perl::Critic
    will make certain warnings about problems found in a `.perlcriticrc` or file
    specified via the **-profile** option fatal. For example, Perl::Critic normally
    only `warn`s about profiles referring to non-existent Policies, but this
    value makes this situation fatal.  Correspondingly,
    ["$PROFILE\_STRICTNESS\_QUIET" in Perl::Critic::Utils::Constants](https://metacpan.org/pod/Perl::Critic::Utils::Constants#PROFILE_STRICTNESS_QUIET) makes
    Perl::Critic shut up about these things.

    **-force** is a boolean value that controls whether Perl::Critic observes the
    magical `"## no critic"` annotations in your code. If set to a true value,
    Perl::Critic will analyze all code.  If set to a false value (which is the
    default) Perl::Critic will ignore code that is tagged with these annotations.
    See ["BENDING THE RULES"](#bending-the-rules) for more information.  You can set the default
    value for this option in your `.perlcriticrc` file.

    **-verbose** can be a positive integer (from 1 to 11), or a literal format
    specification.  See [Perl::Critic::Violation](https://metacpan.org/pod/Perl::Critic::Violation) for an
    explanation of format specifications.  You can set the default value for this
    option in your `.perlcriticrc` file.

    **-unsafe** directs Perl::Critic to allow the use of Policies that are marked
    as "unsafe" by the author.  Such policies may compile untrusted code or do
    other nefarious things.

    **-color** and **-pager** are not used by Perl::Critic but is provided for the
    benefit of [perlcritic](https://metacpan.org/pod/perlcritic).

    **-criticism-fatal** is not used by Perl::Critic but is provided for the
    benefit of [criticism](https://metacpan.org/pod/criticism).

    **-color-severity-highest**, **-color-severity-high**, **-color-severity-
    medium**, **-color-severity-low**, and **-color-severity-lowest** are not used by
    Perl::Critic, but are provided for the benefit of [perlcritic](https://metacpan.org/pod/perlcritic).
    Each is set to the Term::ANSIColor color specification to be used to display
    violations of the corresponding severity.

    **-files-with-violations** and **-files-without-violations** are not used by
    Perl::Critic, but are provided for the benefit of [perlcritic](https://metacpan.org/pod/perlcritic), to
    cause only the relevant filenames to be displayed.

# METHODS

- `critique( $source_code )`

    Runs the `$source_code` through the Perl::Critic engine using all the
    Policies that have been loaded into this engine.  If `$source_code` is a
    scalar reference, then it is treated as a string of actual Perl code.  If
    `$source_code` is a reference to an instance of [PPI::Document](https://metacpan.org/pod/PPI::Document), then that
    instance is used directly. Otherwise, it is treated as a path to a local file
    containing Perl code.  This method returns a list of
    [Perl::Critic::Violation](https://metacpan.org/pod/Perl::Critic::Violation) objects for each violation of the loaded Policies.
    The list is sorted in the order that the Violations appear in the code.  If
    there are no violations, this method returns an empty list.

- `add_policy( -policy => $policy_name, -params => \%param_hash )`

    Creates a Policy object and loads it into this Critic.  If the object cannot
    be instantiated, it will throw a fatal exception.  Otherwise, it returns a
    reference to this Critic.

    **-policy** is the name of a [Perl::Critic::Policy](https://metacpan.org/pod/Perl::Critic::Policy) subclass module.  The
    `'Perl::Critic::Policy'` portion of the name can be omitted for brevity.
    This argument is required.

    **-params** is an optional reference to a hash of Policy parameters. The
    contents of this hash reference will be passed into to the constructor of the
    Policy module.  See the documentation in the relevant Policy module for a
    description of the arguments it supports.

- ` policies() `

    Returns a list containing references to all the Policy objects that have been
    loaded into this engine.  Objects will be in the order that they were loaded.

- ` config() `

    Returns the [Perl::Critic::Config](https://metacpan.org/pod/Perl::Critic::Config) object that was created for or given to
    this Critic.

- ` statistics() `

    Returns the [Perl::Critic::Statistics](https://metacpan.org/pod/Perl::Critic::Statistics) object that was created for this
    Critic.  The Statistics object accumulates data for all files that are
    analyzed by this Critic.

# FUNCTIONAL INTERFACE

For those folks who prefer to have a functional interface, The `critique`
method can be exported on request and called as a static function.  If the
first argument is a hashref, its contents are used to construct a new
Perl::Critic object internally.  The keys of that hash should be the same as
those supported by the `Perl::Critic::new()` method.  Here are some examples:

    use Perl::Critic qw(critique);

    # Use default parameters...
    @violations = critique( $some_file );

    # Use custom parameters...
    @violations = critique( {-severity => 2}, $some_file );

    # As a one-liner
    %> perl -MPerl::Critic=critique -e 'print critique(shift)' some_file.pm

None of the other object-methods are currently supported as static
functions.  Sorry.

# CONFIGURATION

Most of the settings for Perl::Critic and each of the Policy modules can be
controlled by a configuration file.  The default configuration file is called
`.perlcriticrc`.  Perl::Critic will look for this file in the current
directory first, and then in your home directory. Alternatively, you can set
the `PERLCRITIC` environment variable to explicitly point to a different file
in another location.  If none of these files exist, and the `-profile` option
is not given to the constructor, then all the modules that are found in the
Perl::Critic::Policy namespace will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks that
contain key-value pairs separated by '='. Comments should start with '#' and
can be placed on a separate line or after the name-value pairs if you desire.

Default settings for Perl::Critic itself can be set **before the first named
block.** For example, putting any or all of these at the top of your
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

`Perl::Critic::Policy::Category::PolicyName` is the full name of a module
that implements the policy.  The Policy modules distributed with Perl::Critic
have been grouped into categories according to the table of contents in Damian
Conway's book **Perl Best Practices**. For brevity, you can omit the
`'Perl::Critic::Policy'` part of the module name.

`severity` is the level of importance you wish to assign to the Policy.  All
Policy modules are defined with a default severity value ranging from 1 (least
severe) to 5 (most severe).  However, you may disagree with the default
severity and choose to give it a higher or lower severity, based on your own
coding philosophy.  You can set the `severity` to an integer from 1 to 5, or
use one of the equivalent names:

    SEVERITY NAME ...is equivalent to... SEVERITY NUMBER
    ----------------------------------------------------
    gentle                                             5
    stern                                              4
    harsh                                              3
    cruel                                              2
    brutal                                             1

The names reflect how severely the code is criticized: a `gentle` criticism
reports only the most severe violations, and so on down to a `brutal`
criticism which reports even the most minor violations.

`set_themes` sets the theme for the Policy and overrides its default theme.
The argument is a string of one or more whitespace-delimited alphanumeric
words.  Themes are case-insensitive.  See ["POLICY THEMES"](#policy-themes) for more
information.

`add_themes` appends to the default themes for this Policy.  The argument is
a string of one or more whitespace-delimited words. Themes are case-
insensitive.  See ["POLICY THEMES"](#policy-themes) for more information.

`maximum_violations_per_document` limits the number of Violations the Policy
will return for a given document.  Some Policies have a default limit; see the
documentation for the individual Policies to see whether there is one.  To
force a Policy to not have a limit, specify "no\_limit" or the empty string for
the value of this parameter.

The remaining key-value pairs are configuration parameters that will be passed
into the constructor for that Policy.  The constructors for most Policy
objects do not support arguments, and those that do should have reasonable
defaults.  See the documentation on the appropriate Policy module for more
details.

Instead of redefining the severity for a given Policy, you can completely
disable a Policy by prepending a '-' to the name of the module in your
configuration file.  In this manner, the Policy will never be loaded,
regardless of the `-severity` given to the Perl::Critic constructor.

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

For additional configuration examples, see the `perlcriticrc` file that is
included in this `examples` directory of this distribution.

Damian Conway's own Perl::Critic configuration is also included in this
distribution as `examples/perlcriticrc-conway`.

# THE POLICIES

A large number of Policy modules are distributed with Perl::Critic. They are
described briefly in the companion document [Perl::Critic::PolicySummary](https://metacpan.org/pod/Perl::Critic::PolicySummary) and
in more detail in the individual modules themselves.  Say `"perlcritic -doc
PATTERN"` to see the perldoc for all Policy modules that match the regex
`m/PATTERN/ixms`

There are a number of distributions of additional policies on CPAN. If
[Perl::Critic](https://metacpan.org/pod/Perl::Critic) doesn't contain a policy that you want, some one may have
already written it.  See the ["SEE ALSO"](#see-also) section below for a list of some
of these distributions.

# POLICY THEMES

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
    complexity        Policies that specifically relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test programs

Any Policy may fit into multiple themes.  Say `"perlcritic -list"` to get a
listing of all available Policies and the themes that are associated with each
one.  You can also change the theme for any Policy in your `.perlcriticrc`
file.  See the ["CONFIGURATION"](#configuration) section for more information about that.

Using the `-theme` option, you can create an arbitrarily complex rule that
determines which Policies will be loaded.  Precedence is the same as regular
Perl code, and you can use parentheses to enforce precedence as well.
Supported operators are:

    Operator    Alternative    Example
    -----------------------------------------------------------------
    &&          and            'pbp && core'
    ||          or             'pbp || (bugs && security)'
    !           not            'pbp && ! (portability || complexity)'

Theme names are case-insensitive.  If the `-theme` is set to an empty string,
then it evaluates as true all Policies.

# BENDING THE RULES

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

The `"## no critic"` annotations direct Perl::Critic to ignore the remaining
lines of code until a `"## use critic"` annotation is found. If the `"## no
critic"` annotation is on the same line as a code statement, then only that
line of code is overlooked.  To direct perlcritic to ignore the `"## no
critic"` annotations, use the `--force` option.

A bare `"## no critic"` annotation disables all the active Policies.  If you
wish to disable only specific Policies, add a list of Policy names as
arguments, just as you would for the `"no strict"` or `"no warnings"`
pragmas.  For example, this would disable the `ProhibitEmptyQuotes` and
`ProhibitPostfixControls` policies until the end of the block or until the
next `"## use critic"` annotation (whichever comes first):

    ## no critic (EmptyQuotes, PostfixControls)

    # Now exempt from ValuesAndExpressions::ProhibitEmptyQuotes
    $foo = "";

    # Now exempt ControlStructures::ProhibitPostfixControls
    $barf = bar() if $foo;

    # Still subjected to ValuesAndExpression::RequireNumberSeparators
    $long_int = 10000000000;

Since the Policy names are matched against the `"## no critic"` arguments as
regular expressions, you can abbreviate the Policy names or disable an entire
family of Policies in one shot like this:

    ## no critic (NamingConventions)

    # Now exempt from NamingConventions::Capitalization
    my $camelHumpVar = 'foo';

    # Now exempt from NamingConventions::Capitalization
    sub camelHumpSub {}

The argument list must be enclosed in parentheses or brackets and must contain
one or more comma-separated barewords (e.g. don't use quotes).
The `"## no critic"` annotations can be nested, and Policies named by an inner
annotation will be disabled along with those already disabled an outer
annotation.

Some Policies like `Subroutines::ProhibitExcessComplexity` apply to an entire
block of code.  In those cases, the `"## no critic"` annotation must appear
on the line where the violation is reported.  For example:

    sub complicated_function {  ## no critic (ProhibitExcessComplexity)
        # Your code here...
    }

Policies such as `Documentation::RequirePodSections` apply to the entire
document, in which case violations are reported at line 1.

Use this feature wisely.  `"## no critic"` annotations should be used in the
smallest possible scope, or only on individual lines of code. And you should
always be as specific as possible about which Policies you want to disable
(i.e. never use a bare `"## no critic"`).  If Perl::Critic complains about
your code, try and find a compliant solution before resorting to this feature.

# THE [Perl::Critic](https://metacpan.org/pod/Perl::Critic) PHILOSOPHY

Coding standards are deeply personal and highly subjective.  The goal of
Perl::Critic is to help you write code that conforms with a set of best
practices.  Our primary goal is not to dictate what those practices are, but
rather, to implement the practices discovered by others.  Ultimately, you make
the rules -- Perl::Critic is merely a tool for encouraging consistency.  If
there is a policy that you think is important or that we have overlooked, we
would be very grateful for contributions, or you can simply load your own
private set of policies into Perl::Critic.

# EXTENDING THE CRITIC

The modular design of Perl::Critic is intended to facilitate the addition of
new Policies.  You'll need to have some understanding of [PPI](https://metacpan.org/pod/PPI), but most
Policy modules are pretty straightforward and only require about 20 lines of
code.  Please see the [Perl::Critic::DEVELOPER](https://metacpan.org/pod/Perl::Critic::DEVELOPER) file included in this
distribution for a step-by-step demonstration of how to create new Policy
modules.

If you develop any new Policy modules, feel free to send them to `<team@perlcritic.com>` and I'll be happy to consider putting them into the
Perl::Critic distribution.  Or if you would like to work on the Perl::Critic
project directly, you can fork our repository at
[https://github.com/Perl-Critic/Perl-Critic.git](https://github.com/Perl-Critic/Perl-Critic.git).

The Perl::Critic team is also available for hire.  If your organization has
its own coding standards, we can create custom Policies to enforce your local
guidelines.  Or if your code base is prone to a particular defect pattern, we
can design Policies that will help you catch those costly defects **before**
they go into production. To discuss your needs with the Perl::Critic team,
just contact `<team@perlcritic.com>`.

# PREREQUISITES

Perl::Critic requires the following modules:

[B::Keywords](https://metacpan.org/pod/B::Keywords)

[Config::Tiny](https://metacpan.org/pod/Config::Tiny)

[Exception::Class](https://metacpan.org/pod/Exception::Class)

[File::Spec](https://metacpan.org/pod/File::Spec)

[File::Spec::Unix](https://metacpan.org/pod/File::Spec::Unix)

[File::Which](https://metacpan.org/pod/File::Which)

[IO::String](https://metacpan.org/pod/IO::String)

[List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

[List::Util](https://metacpan.org/pod/List::Util)

[Module::Pluggable](https://metacpan.org/pod/Module::Pluggable)

[Perl::Tidy](https://metacpan.org/pod/Perl::Tidy)

[Pod::Spell](https://metacpan.org/pod/Pod::Spell)

[PPI](https://metacpan.org/pod/PPI)

[Pod::PlainText](https://metacpan.org/pod/Pod::PlainText)

[Pod::Select](https://metacpan.org/pod/Pod::Select)

[Pod::Usage](https://metacpan.org/pod/Pod::Usage)

[Readonly](https://metacpan.org/pod/Readonly)

[Scalar::Util](https://metacpan.org/pod/Scalar::Util)

[String::Format](https://metacpan.org/pod/String::Format)

[Task::Weaken](https://metacpan.org/pod/Task::Weaken)

[Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor)

[Text::ParseWords](https://metacpan.org/pod/Text::ParseWords)

[version](https://metacpan.org/pod/version)

# CONTACTING THE DEVELOPMENT TEAM

You are encouraged to subscribe to the public mailing list at
[https://groups.google.com/d/forum/perl-critic](https://groups.google.com/d/forum/perl-critic).
At least one member of the development team is usually hanging around
in [irc://irc.perl.org/#perlcritic](irc://irc.perl.org/#perlcritic) and you can follow Perl::Critic on
Twitter, at [https://twitter.com/perlcritic](https://twitter.com/perlcritic).

# SEE ALSO

There are a number of distributions of additional Policies available. A few
are listed here:

[Perl::Critic::More](https://metacpan.org/pod/Perl::Critic::More)

[Perl::Critic::Bangs](https://metacpan.org/pod/Perl::Critic::Bangs)

[Perl::Critic::Lax](https://metacpan.org/pod/Perl::Critic::Lax)

[Perl::Critic::StricterSubs](https://metacpan.org/pod/Perl::Critic::StricterSubs)

[Perl::Critic::Swift](https://metacpan.org/pod/Perl::Critic::Swift)

[Perl::Critic::Tics](https://metacpan.org/pod/Perl::Critic::Tics)

These distributions enable you to use Perl::Critic in your unit tests:

[Test::Perl::Critic](https://metacpan.org/pod/Test::Perl::Critic)

[Test::Perl::Critic::Progressive](https://metacpan.org/pod/Test::Perl::Critic::Progressive)

There is also a distribution that will install all the Perl::Critic related
modules known to the development team:

[Task::Perl::Critic](https://metacpan.org/pod/Task::Perl::Critic)

# BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you find
any bugs, particularly false-positives or false-negatives from a
Perl::Critic::Policy, please submit them at
[https://github.com/Perl-Critic/Perl-Critic/issues](https://github.com/Perl-Critic/Perl-Critic/issues).  Thanks.

# CREDITS

Adam Kennedy - For creating [PPI](https://metacpan.org/pod/PPI), the heart and soul of [Perl::Critic](https://metacpan.org/pod/Perl::Critic).

Damian Conway - For writing **Perl Best Practices**, finally :)

Chris Dolan - For contributing the best features and Policy modules.

Andy Lester - Wise sage and master of all-things-testing.

Elliot Shank - The self-proclaimed quality freak.

Giuseppe Maxia - For all the great ideas and positive encouragement.

and Sharon, my wife - For putting up with my all-night code sessions.

Thanks also to the Perl Foundation for providing a grant to support Chris
Dolan's project to implement twenty PBP policies.
[http://www.perlfoundation.org/april\_1\_2007\_new\_grant\_awards](http://www.perlfoundation.org/april_1_2007_new_grant_awards)

Thanks also to this incomplete laundry list of folks who have contributed
to Perl::Critic in some way:
Gregory Oschwald,
Mike O'Regan,
Tom Hukins,
Omer Gazit,
Evan Zacks,
Paul Howarth,
Sawyer X,
Christian Walde,
Dave Rolsky,
Jakub Wilk,
Roy Ivy III,
Oliver Trosien,
Glenn Fowler,
Matt Creenan,
Alex Balhatchet,
Sebastian Paaske Tørholm,
Stuart A Johnston,
Dan Book,
Steven Humphrey,
James Raspass,
Nick Tonkin,
Harrison Katz,
Douglas Sims,
Mark Fowler,
Alan Berndt,
Neil Bowers,
Sergey Romanov,
Gabor Szabo,
Graham Knop,
Mike Eldridge,
David Steinbrunner,
Kirk Kimmel,
Guillaume Aubert,
Dave Cross,
Anirvan Chatterjee,
Todd Rinaldo,
Graham Ollis,
Karen Etheridge,
Jonas Brømsø,
Olaf Alders,
Jim Keenan,
Slaven Rezić,
Szymon Nieznański.

# AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

# COPYRIGHT

Copyright (c) 2005-2018 Imaginative Software Systems.  All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  The full text of this license can be found in
the LICENSE file included with this module.
