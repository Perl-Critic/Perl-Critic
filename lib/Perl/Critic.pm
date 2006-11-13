#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic;

use strict;
use warnings;
use base qw(Exporter);

use Carp;
use File::Spec;
use Scalar::Util qw(blessed);
use English qw(-no_match_vars);
use Perl::Critic::Config;
use Perl::Critic::Violation;
use Perl::Critic::Document;
use PPI::Document;
use PPI::Document::File;

#----------------------------------------------------------------------------

our $VERSION = 0.21;
our @EXPORT_OK = qw(&critique);

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;
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
    return if not $source_code;  # If no code, then nothing to do.

    # $source_code can be a file name, or a reference to a
    # PPI::Document, or a reference to a scalar containing source
    # code.  In the last case, PPI handles the translation for us.

    my $doc = _is_ppi_doc( $source_code ) ? $source_code
              : ref $source_code ? PPI::Document->new($source_code)
              : PPI::Document::File->new($source_code);

    # Bail on error
    if ( not defined $doc ) {
        my $errstr = PPI::Document::errstr();
        my $file = ref $source_code ? undef : $source_code;
        croak qq{Warning: Can't parse code: $errstr}.($file ? qq{ for '$file'} : q{});
    }

    # Pre-index location of each node (for speed)
    $doc->index_locations();

    # Wrap the doc in a caching layer
    $doc = Perl::Critic::Document->new($doc);

    # Disable the magic shebang fix
    my %is_line_disabled = _unfix_shebang($doc);

    # Filter exempt code, if desired
    if ( not $self->config->force() ) {
        my @site_policies = $self->config->site_policy_names();
        %is_line_disabled = ( %is_line_disabled,
                              _filter_code($doc, @site_policies) );
    }

    # Evaluate each policy
    my @pols = $self->config->policies();
    my @violations = map { _critique( $_, $doc, \%is_line_disabled) } @pols;

    # If requested, rank violations by their severity and return the top N.
    if ( @violations && (my $top = $self->config->top()) ) {
        my $limit = @violations < $top ? $#violations : $top-1;
        @violations = Perl::Critic::Violation::sort_by_severity(@violations);
        @violations = ( reverse @violations )[ 0 .. $limit ];  #Slicing...
    }

    # Always return violations sorted by location
    return Perl::Critic::Violation->sort_by_location(@violations);
}

#============================================================================
# PRIVATE functions

sub _is_ppi_doc {
    my ($ref) = @_;
    return blessed($ref) && $ref->isa('PPI::Document');
}

#-----------------------------------------------------------------------------

sub _critique {

    my ($policy, $doc, $is_line_disabled) = @_;
    my @violations = ();

  TYPE:
    for my $type ( $policy->applies_to() ) {

      ELEMENT:
        for my $element ( @{ $doc->find($type) || [] } ) {

            # Evaluate the policy on this $element.  A policy may
            # return zero or more violations.  We only want the
            # violations that occur on lines that have not been
            # disabled.

          VIOLATION:
            for my $violation ( $policy->violates( $element, $doc ) ) {
                my $policy_name = ref $policy;
                my $line = $violation->location()->[0];
                next VIOLATION if $is_line_disabled->{$line}->{$policy_name};
                next VIOLATION if $is_line_disabled->{$line}->{ALL};
                push @violations, $violation;
            }
        }
    }

    return @violations;
}

#-----------------------------------------------------------------------------

sub _filter_code {

    my ($doc, @site_policies)= @_;
    my $nodes_ref  = $doc->find('PPI::Token::Comment') || return;
    my $no_critic  = qr{\A \s* \#\# \s* no  \s+ critic}mx;
    my $use_critic = qr{\A \s* \#\# \s* use \s+ critic}mx;
    my %disabled_lines;

  PRAGMA:
    for my $pragma ( grep { $_ =~ $no_critic } @{$nodes_ref} ) {

        # Parse out the list of Policy names after the
        # 'no critic' pragma.  I'm thinking of this just
        # like a an C<import> argument for real pragmas.
        my @no_policies = _parse_nocritic_import($pragma, @site_policies);

        # Grab surrounding nodes to determine the context.
        # This determines whether the pragma applies to
        # the current line or the block that follows.
        my $parent = $pragma->parent();
        my $grandparent = $parent ? $parent->parent() : undef;
        my $sib = $pragma->sprevious_sibling();


        # Handle single-line usage on simple statements
        if ( $sib && $sib->location->[0] == $pragma->location->[0] ) {
            my $line = $pragma->location->[0];
            for my $policy ( @no_policies ) {
                $disabled_lines{ $line }->{$policy} = 1;
            }
            next PRAGMA;
        }


        # Handle single-line usage on compound statements
        if ( ref $parent eq 'PPI::Structure::Block' ) {
            if ( ref $grandparent eq 'PPI::Statement::Compound'
                 || ref $grandparent eq 'PPI::Statement::Sub' ) {
                if ( $parent->location->[0] == $pragma->location->[0] ) {
                    my $line = $grandparent->location->[0];
                    for my $policy ( @no_policies ) {
                        $disabled_lines{ $line }->{$policy} = 1;
                    }
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
            for my $policy ( @no_policies ) {
                $disabled_lines{ $line }->{$policy} = 1;
            }
        }
    }

    return %disabled_lines;
}

#----------------------------------------------------------------------------

sub _parse_nocritic_import {

    my ($pragma, @site_policies) = @_;

    my $module    = qr{ [\w:]+ }mx;
    my $delim     = qr{ \s* [,\s] \s* }mx;
    my $qw        = qr{ (?: qw )? }mx;
    my $qualifier = qr{ $qw \(? \s* ( $module (?: $delim $module)* ) \s* \)? }mx;
    my $no_critic = qr{ \A \s* \#\# \s* no \s+ critic \s* $qualifier }mx;

    if ( my ($module_list) = $pragma =~ $no_critic ) {
        my @modules = split $delim, $module_list;
        return map { my $req = $_; grep {m/$req/imx} @site_policies } @modules;
    }

    # Default to disabling ALL policies.
    return qw(ALL);
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
        my $line = $first_stmnt->location()->[0];
        return ( $line => {ALL => 1}, $line + 1 => {ALL => 1} );
    }

    #No magic shebang was found!
    return;
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=for stopwords DGR INI-style API -params pbp refactored

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
Conway's book B<Perl Best Practices>.  However, Perl::Critic is B<not>
limited to PBP and will even support Policies that contradict Conway.
You can enable, disable, and customize those Polices through the
Perl::Critic interface.  You can also create new Policy modules that
suit your own tastes.

For a convenient command-line interface to Perl::Critic, see the
documentation for L<perlcritic>.  If you want to integrate
Perl::Critic with your build process, L<Test::Perl::Critic> provides
an interface that is suitable for test scripts.  For the ultimate
convenience (at the expense of some flexibility) see the L<criticism>
pragma.

Win32 and ActivePerl users can find PPM distributions of Perl::Critic
at L<http://theoryx5.uwinnipeg.ca/ppms/>.

If you'd like to try L<Perl::Critic> without installing anything,
there is a web-service available at L<http://perlcritic.com>.  The
web-service does not yet support all the configuration features that
are available in the native Perl::Critic API, but it should give you a
good idea of what it does.  You can also invoke the perlcritic
web-service from the command line by doing an HTTP-post, such as one
of these:

    $> POST http://perlcritic.com/perl/critic.pl < MyModule.pm
    $> lwp-request -m POST http://perlcritic.com/perl/critic.pl < MyModule.pm
    $> wget -q -O - --post-file=MyModule.pm http://perlcritic.com/perl/critic.pl

Please note that the perlcritic web-service is still alpha code.  The
URL and interface to the service are subject to change.

=head1 CONSTRUCTOR

=over 8

=item C<< new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -top => $N, -only => $B, -force => $B, -verbose => $N ] ) >>

=item C<< new( [ -config => Perl::Critic::Config->new() ] >>

=item C<< new() >>

Returns a reference to a new Perl::Critic object.  Most arguments are
just passed directly into L<Perl::Critic::Config>, but I have
described them here as well.  The default value for all arguments can
be defined in your F<.perlcriticrc> file.  See the L<"CONFIGURATION">
section for more information about that.  All arguments are optional
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
have a severity greater than C<$N> will be loaded.  Severity values
are integers ranging from 1 (least severe) to 5 (most severe).  The
default is 5.  For a given C<-profile>, decreasing the C<-severity>
will usually result in more Policy violations.  Users can redefine the
severity level for any Policy in their F<.perlcriticrc> file.  See
L<"CONFIGURATION"> for more information.

B<-theme> is special string that defines a set of Policies based on
their respective themes.  If C<-theme> is given, only policies that
are members of that set will be loaded.  For example, the following
would load only Policies that have a 'danger' and 'pbp' theme:

  my $critic = Perl::Critic->new(-theme => 'danger * pbp');

See the L<"POLICY THEMES"> section for more information about themes.
Unless the C<-severity> option is explicitly given, setting C<-theme>
silently causes the C<-severity> to be set to 1.

B<-include> is a reference to a list of string C<@PATTERNS>.  Policy
modules that match at least one C<m/$PATTERN/imx> will always be
loaded, irrespective of all other settings.  For example:

  my $critic = Perl::Critic->new(-include => ['layout'] -severity => 4);

This would cause Perl::Critic to load all the C<CodeLayout::*> Policy
modules even though they have a severity level that is less than 4.
You can use C<-include> in conjunction with the C<-exclude> option.
Note that C<-exclude> takes precedence over C<-include> when a Policy
matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Policy
modules that match at least one C<m/$PATTERN/imx> will not be loaded,
irrespective of all other settings.  For example:

  my $critic = Perl::Critic->new(-exclude => ['strict'] -severity => 1);

This would cause Perl::Critic to not load the C<RequireUseStrict> and
C<ProhibitNoStrict> Policy modules even though they have a severity
level that is greater than 1.  You can use C<-exclude> in conjunction
with the C<-include> option.  Note that C<-exclude> takes precedence
over C<-include> when a Policy matches both patterns.

B<-top> is the maximum number of Violations to return when ranked by
their severity levels.  This must be a positive integer.  Violations
are still returned in the order that they occur within the file.
Unless the C<-severity> option is explicitly given, setting C<-top>
silently causes the C<-severity> to be set to 1.

B<-only> is a boolean value.  If set to a true value, Perl::Critic
will only choose from Policies that are mentioned in the user's
profile.  If set to a false value (which is the default), then
Perl::Critic chooses from all the Policies that it finds at your site.

B<-force> controls whether Perl::Critic observes the magical C<"## no
critic"> pseudo-pragmas in your code.  If set to a true value,
Perl::Critic will analyze all code.  If set to a false value (which is
the default) Perl::Critic will ignore code that is tagged with these
comments.  See L<"BENDING THE RULES"> for more information.

B<-verbose> can be a positive integer (from 1 to 10), or a literal
format specification.  See L<Perl::Critic::Violations> for an
explanation of format specifications.

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
code.  If C<$source_code> is a reference to an instance of
L<PPI::Document>, then that instance is used directly.  Otherwise, it
is treated as a path to a local file containing Perl code.  This
method Returns a list of L<Perl::Critic::Violation> objects for each
violation of the loaded Policies.  The list is sorted in the order
that the Violations appear in the code.  If there are no violations,
this method returns an empty list.

=item C<< add_policy( -policy => $policy_name, -params => \%param_hash ) >>

Creates a Policy object and loads it into this Critic.  If the object
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
have been loaded into this engine.  Objects will be in the order that
they were loaded.

=item C< config() >

Returns the L<Perl::Critic::Config> object that was created for or given
to this Critic.

=back

=head1 FUNCTIONAL INTERFACE

For those folks who prefer to have a functional interface, The
C<critique> method can be exported on request and called as a static
function.  If the first argument is a hashref, its contents are used
to construct a new Perl::Critic object internally.  The keys of that
hash should be the same as those supported by the C<Perl::Critic::new>
method.  Here are some examples:

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

Most of the settings for Perl::Critic and each of the Policy modules
can be controlled by a configuration file.  The default configuration
file is called F<.perlcriticrc>.  Perl::Critic will look for this file
in the current directory first, and then in your home directory.
Alternatively, you can set the C<PERLCRITIC> environment variable to
explicitly point to a different file in another location.  If none of
these files exist, and the C<-profile> option is not given to the
constructor, then all the modules that are found in the
Perl::Critic::Policy namespace will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style
blocks that contain key-value pairs separated by '='. Comments
should start with '#' and can be placed on a separate line or after
the name-value pairs if you desire.

Default settings for Perl::Critic itself can be set B<before the first
named block.>  For example, putting any or all of these at the top of
your configuration file will set the default value for the
corresponding command-line argument.

    severity  = 3                                     #Integer from 1 to 5
    only      = 1                                     #Zero or One
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = risky + (pbp * security) - cosmetic   #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list

The remainder of the configuration file is a series of blocks like
this:

    [Perl::Critic::Policy::Category::PolicyName]
    severity = 1
    set_theme = foo bar
    add_themes = baz
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
be passed into the constructor for that Policy.  The constructors for
most Policy objects do not support arguments, and those that do should
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
    # Give these policies a custom theme.  I can activate just
    # these policies by saying `perlcritic -theme larry`

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = larry curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity,
    # so no additional configuration is required for them.

For additional configuration examples, see the F<perlcriticrc> file
that is included in this F<t/examples> directory of this distribution.

=head1 THE POLICIES

A large number of Policy modules are distributed with Perl::Critic.
They are described briefly in the companion document
L<Perl::Critic::PolicySummary> and in more detail in the individual
modules themselves.

=head1 POLICY THEMES

B<NOTE:> As of version 0.21, policy themes are still considered
experimental.  The implementation of this feature may change in a
future release.  Additionally, the default theme names that ship with
Perl::Critic may also change.  But this is a pretty cool feature, so
read on...

Each Policy is defined with one or more "themes".  Themes can be used
to create arbitrary groups of Policies.  They are intended to provide
an alternative mechanism for selecting your preferred set of Policies.
The Policies that ship with Perl::Critic have been grouped into themes
that are roughly analogous to their severity levels.  Folks who find
the numeric severity levels awkward can use these mnemonic theme names
instead.

    Severity Level                   Equivalent Theme
    ---------------------------------------------------------------------------
    5                                danger
    4                                risky
    3                                unreliable
    2                                readability
    1                                cosmetic


Say C<"perlcritic -list"> to get a listing of all available policies
and the themes that are associated with each one.  You can also change
the theme for any Policy in your F<.perlcriticrc> file.  See the
L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> command-line option, you can combine themes with
mathematical and boolean operators to create an arbitrarily complex
expression that represents a custom "set" of Policies.  The following
operators are supported

   Operator       Altertative         Meaning
   ----------------------------------------------------------------------------
   *              and                 Intersection
   -              not                 Difference
   +              or                  Union

Operator precedence is the same as that of normal mathematics.  You
can also use parenthesis to enforce precedence.  Here are some examples:

   Expression                  Meaning
   ----------------------------------------------------------------------------
   pbp * risky                 All policies that are "pbp" AND "risky"
   pbp and risky               Ditto

   danger + risky              All policies that are "danger" OR "risky"
   pbp or risky                Ditto

   pbp - cosmetic              All policies that are "pbp" BUT NOT "risky"
   pbp not cosmetic            Ditto

   -unreliable                All policies that are NOT "unreliable"
   not unreliable             Ditto

   (pbp - danger) * risky      All policies that are "pbp" BUT NOT "danger", AND "risky"
   (pbp not danger) and risky  Ditto

Theme names are case-insensitive.  If C<-theme> is set to an empty
string, then it is equivalent to the set of all policies.  A theme
name that doesn't exist is equivalent to an empty set. Please See
L<http://en.wikipedia.org/wiki/Set> for a discussion on set theory.

=head1 BENDING THE RULES

Perl::Critic takes a hard-line approach to your code: either you
comply or you don't.  In the real world, it is not always practical
(nor even possible) to fully comply with coding standards.  In such
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

A bare C<"## no critic"> comment disables all the active Policies.  If
you wish to disable only specific Policies, add a list of Policy names
as arguments, just as you would for the C<"no strict"> or C<"no
warnings"> pragmas.  For example, this would disable the
C<ProhibitEmptyQuotes> and C<ProhibitPostfixControls> policies until
the end of the block or until the next C<"## use critic"> comment
(whichever comes first):

  ## no critic (EmptyQuotes, PostfixControls)

  $foo = "";                  #Now exempt from ValuesAndExpressions::ProhibitEmptyQuotes
  $barf = bar() if $foo;      #Now exempt ControlStructures::ProhibitPostfixControls
  $long_int = 10000000000;    #Still subjected to ValuesAndExpression::RequireNumberSeparators

Since the Policy names are matched against the arguments as regular
expressions, you can abbreviate the Policy names or disable an entire
family of Policies in one shot like this:

  ## no critic (NamingConventions)

  my $camelHumpVar = 'foo';  #Now exempt from NamingConventions::ProhibitMixedCaseVars
  sub camelHumpSub {}        #Now exempt from NamingConventions::ProhibitMixedCaseSubs

The argument list must be enclosed in parens and must contain one or
more comma-separated barewords (e.g. don't use quotes).  The C<"## no
critic"> pragmas can be nested, and Policies named by an inner pragma
will be disabled along with those already disabled an outer pragma.

Use this feature wisely.  C<"## no critic"> should be used in the
smallest possible scope, or only on individual lines of code. And you
should always be as specific as possible about which policies you want
to disable (i.e. never use a bare C<"## no critic">).  If Perl::Critic
complains about your code, try and find a compliant solution before
resorting to this feature.

=head1 IMPORTANT CHANGES

Perl-Critic is evolving rapidly, so some of the interfaces have
changed in ways that are not backward-compatible.  If you have been
using an older version of Perl-Critic and/or you have been developing
custom Policy modules, please read this section carefully.

=head2 VERSION 0.21

In version 0.21, we introduced the concept of policy "themes".  All
you existing custom Policies should still be compatible.  But to take
advantage of the theme feature, you should add a C<default_themes>
method to your custom Policy modules.  See L<Perl::Critic::DEVELOPER>
for an up-to-date guide on creating Policy modules.

The internals of Perl::Critic were also refactored significantly.  The
public API is largely unchanged, but if you've been accessing bits
inside Perl::Critic, then you may be in for a surprise.

=head2 VERSION 0.16

Starting in version 0.16, you can add a list Policy names as arguments
to the C<"## no critic"> pseudo-pragma.  This feature allows you to
disable specific policies.  So if you have been in the habit of adding
additional words after C<"no critic">, then those words might cause
unexpected results.  If you want to append other stuff to the C<"## no
critic"> comment, then terminate the pseudo-pragma with a semi-colon,
and then start another comment.  For example:

    #This may not work as expected.
    $email = 'foo@bar.com';  ## no critic for literal '@'

    #This will work.
    $email = 'foo@bar.com';  ## no critic; #for literal '@'

    #This is even better.
    $email = 'foo@bar.com'; ## no critic (RequireInterpolation);

=head2 VERSION 0.14

Starting in version 0.14, the interface to L<Perl::Critic::Violation>
changed.  This will also break any custom Policy modules that you
might have written for earlier modules. See L<Perl::Critic::DEVELOPER>
for an up-to-date guide on creating Policy modules.

The notion of "priority" was also replaced with "severity" in version
0.14.  Consequently, the default behavior of Perl::Critic is to only
load the most "severe" Policy modules, rather than loading all of
them.  This decision was based on user-feedback suggesting that
Perl-Critic should be less critical for new users, and should steer
them toward gradually increasing the strictness as they progressively
adopt better coding practices.


=head2 VERSION 0.11

Starting in version 0.11, the internal mechanics of Perl-Critic were
rewritten so that only one traversal of the PPI document tree is
required.  Unfortunately, this will break any custom Policy modules
that you might have written for earlier versions.  Converting your
policies to work with the new version is pretty easy and actually
results in cleaner code.  See L<Perl::Critic::DEVELOPER> for an
up-to-date guide on creating Policy modules.

=head1 THE L<Perl::Critic> PHILOSOPHY

  Coding standards are deeply personal and highly subjective.  The
  goal of Perl::Critic is to help you write code that conforms with a
  set of best practices.  Our primary goal is not to dictate what
  those practices are, but rather, to implement the practices
  discovered by others.  Ultimately, you make the rules --
  Perl::Critic is merely a tool for encouraging consistency.  If there
  is a policy that you think is important or that we have overlooked,
  we would be very grateful for contributions, or you can simply load
  your own private set of policies into Perl::Critic.

=head1 EXTENDING THE CRITIC

The modular design of Perl::Critic is intended to facilitate the
addition of new Policies.  You'll need to have some understanding of
L<PPI>, but most Policy modules are pretty straightforward and only
require about 20 lines of code.  Please see the
L<Perl::Critic::DEVELOPER> file included in this distribution for a
step-by-step demonstration of how to create new Policy modules.

If you develop any new Policy modules, feel free to send them to
C<thaljef@cpan.org> and I'll be happy to put them into the Perl::Critic
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

L<Scalar::Util>

L<String::Format>

The following modules are optional, but recommended for complete
testing:

L<Test::Pod>

L<Test::Pod::Coverage>

=head1 BUGS

Scrutinizing Perl code is hard for humans, let alone machines.  If you
find any bugs, particularly false-positives or false-negatives from a
Perl::Critic::Policy, please submit them to
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Perl-Critic>.  Thanks.

=head1 CREDITS

Adam Kennedy - For creating L<PPI>, the heart and soul of L<Perl::Critic>.

Damian Conway - For writing B<Perl Best Practices>, finally :)

Chris Dolan - For contributing the best features and Policy modules.

Giuseppe Maxia - For all the great ideas and positive encouragement.

and Sharon, my wife - For putting up with my all-night code sessions.

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
# ex: set ts=8 sts=4 sw=4 expandtab
