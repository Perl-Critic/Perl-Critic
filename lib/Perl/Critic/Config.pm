##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Config;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;

use List::MoreUtils qw(any none apply);
use Scalar::Util qw(blessed);

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Exception::Configuration;
use Perl::Critic::Exception::Configuration::Option::Global::ParameterValue;
use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::PolicyFactory;
use Perl::Critic::Theme qw( $RULE_INVALID_CHARACTER_REGEX cook_rule );
use Perl::Critic::UserProfile qw();
use Perl::Critic::Utils qw{
    :booleans :characters :severities :internal_lookup :classification
};
use Perl::Critic::Utils::Constants qw{ :profile_strictness };
use Perl::Critic::Utils::DataConversion qw{ boolean_to_number dor };

#-----------------------------------------------------------------------------

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $SINGLE_POLICY_CONFIG_KEY => 'single-policy';

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

    # -top or -theme imply that -severity is 1, unless it is already defined
    if ( defined $args{-top} || defined $args{-theme} ) {
        $args{-severity} ||= $SEVERITY_LOWEST;
    }

    my $errors = Perl::Critic::Exception::AggregateConfiguration->new();

    # Construct the UserProfile to get default options.
    my $profile_source  = $args{-profile}; #Can be file path or data struct
    my $profile =
        Perl::Critic::UserProfile->new( -profile => $profile_source );
    my $options_processor = $profile->options_processor();
    $self->{_profile} = $profile;

    $self->_validate_and_save_profile_strictness(
        $args{'-profile-strictness'},
        $errors,
    );

    # If given, these options should always have a true value.
    $self->_validate_and_save_regex(
        'include', $args{-include}, $options_processor->include(), $errors
    );
    $self->_validate_and_save_regex(
        'exclude', $args{-exclude}, $options_processor->exclude(), $errors
    );
    $self->_validate_and_save_regex(
        $SINGLE_POLICY_CONFIG_KEY,
        $args{ qq/-$SINGLE_POLICY_CONFIG_KEY/ },
        $options_processor->single_policy(),
        $errors,
    );

    $self->_validate_and_save_verbosity($args{-verbose}, $errors);
    $self->_validate_and_save_severity($args{-severity}, $errors);
    $self->_validate_and_save_top($args{-top}, $errors);

    # If given, these options can be true or false (but defined)
    # We normalize these to numeric values by multiplying them by 1;
    {
        $self->{_force} = boolean_to_number( dor( $args{-force}, $options_processor->force() ) );
        $self->{_only}  = boolean_to_number( dor( $args{-only},  $options_processor->only()  ) );
        $self->{_color} = boolean_to_number( dor( $args{-color}, $options_processor->color() ) );
        $self->{_criticism_fatal} =
          boolean_to_number(dor( $args{'-criticism-fatal'}, $options_processor->criticism_fatal() ) );
    }

    $self->_validate_and_save_theme($args{-theme}, $errors);
    $self->_validate_and_save_pager($args{-pager}, $errors);

    # Construct a Factory with the Profile
    my $factory =
        Perl::Critic::PolicyFactory->new(
            -profile              => $profile,
            -errors               => $errors,
            '-profile-strictness' => $self->profile_strictness(),
        );
    $self->{_factory} = $factory;

    # Initialize internal storage for Policies
    $self->{_policies} = [];

    # "NONE" means don't load any policies
    if ( not defined $profile_source or $profile_source ne 'NONE' ) {
        # Heavy lifting here...
        $self->_load_policies($errors);
    }

    if ( $errors->has_exceptions() ) {
        $errors->rethrow();
    }

    return $self;
}

#-----------------------------------------------------------------------------

sub add_policy {

    my ( $self, %args ) = @_;

    if ( not $args{-policy} ) {
        throw_internal q{The -policy argument is required};
    }

    my $policy  = $args{-policy};

    # If the -policy is already a blessed object, then just add it directly.
    if ( blessed $policy ) {
        $self->_add_policy_if_enabled($policy);
        return $self;
    }

    # NOTE: The "-config" option is supported for backward compatibility.
    my $params = $args{-params} || $args{-config};

    my $factory       = $self->{_factory};
    my $policy_object =
        $factory->create_policy(-name=>$policy, -params=>$params);
    $self->_add_policy_if_enabled($policy_object);

    return $self;
}

#-----------------------------------------------------------------------------

sub _add_policy_if_enabled {
    my ( $self, $policy_object ) = @_;

    my $config = $policy_object->__get_config()
        or throw_internal
            q{Policy was not set up properly because it does not have }
                . q{a value for its config attribute.};

    if ( $policy_object->initialize_if_enabled( $config ) ) {
        push @{ $self->{_policies} }, $policy_object;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _load_policies {

    my ( $self, $errors ) = @_;
    my $factory  = $self->{_factory};
    my @policies = $factory->create_all_policies( $errors );

    return if $errors->has_exceptions();

    for my $policy ( @policies ) {

        # If -single-policy is true, only load policies that match it
        if ( $self->single_policy() ) {
            if ( $self->_policy_is_single_policy( $policy ) ) {
                $self->add_policy( -policy => $policy );
            }
            next;
        }

        # To load, or not to load -- that is the question.
        my $load_me = $self->only() ? $FALSE : $TRUE;

        ## no critic (ProhibitPostfixControls)
        $load_me = $FALSE if     $self->_policy_is_disabled( $policy );
        $load_me = $TRUE  if     $self->_policy_is_enabled( $policy );
        $load_me = $FALSE if     $self->_policy_is_unimportant( $policy );
        $load_me = $FALSE if not $self->_policy_is_thematic( $policy );
        $load_me = $TRUE  if     $self->_policy_is_included( $policy );
        $load_me = $FALSE if     $self->_policy_is_excluded( $policy );


        next if not $load_me;
        $self->add_policy( -policy => $policy );
    }

    # When using -single-policy, only one policy should ever be loaded.
    if ($self->single_policy() && scalar $self->policies() != 1) {
        $self->_add_single_policy_exception_to($errors);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _policy_is_disabled {
    my ($self, $policy) = @_;
    my $profile = $self->_profile();
    return $profile->policy_is_disabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_enabled {
    my ($self, $policy) = @_;
    my $profile = $self->_profile();
    return $profile->policy_is_enabled( $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_thematic {
    my ($self, $policy) = @_;
    my $theme = $self->theme();
    return $theme->policy_is_thematic( -policy => $policy );
}

#-----------------------------------------------------------------------------

sub _policy_is_unimportant {
    my ($self, $policy) = @_;
    my $policy_severity = $policy->get_severity();
    my $min_severity    = $self->{_severity};
    return $policy_severity < $min_severity;
}

#-----------------------------------------------------------------------------

sub _policy_is_included {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @inclusions  = $self->include();
    return any { $policy_long_name =~ m/$_/ixms } @inclusions;
}

#-----------------------------------------------------------------------------

sub _policy_is_excluded {
    my ($self, $policy) = @_;
    my $policy_long_name = ref $policy;
    my @exclusions  = $self->exclude();
    return any { $policy_long_name =~ m/$_/ixms } @exclusions;
}

#-----------------------------------------------------------------------------

sub _policy_is_single_policy {
    my ($self, $policy) = @_;

    my @patterns = $self->single_policy();
    return if not @patterns;

    my $policy_long_name = ref $policy;
    return any { $policy_long_name =~ m/$_/ixms } @patterns;
}

#-----------------------------------------------------------------------------

sub _new_global_value_exception {
    my ($self, @args) = @_;

    return
        Perl::Critic::Exception::Configuration::Option::Global::ParameterValue
            ->new(@args);
}

#-----------------------------------------------------------------------------

sub _add_single_policy_exception_to {
    my ($self, $errors) = @_;

    my $message_suffix = $EMPTY;
    my $patterns = join q{", "}, $self->single_policy();

    if (scalar $self->policies() == 0) {
        $message_suffix =
            q{did not match any policies (in combination with }
                . q{other policy restrictions).};
    }
    else {
        $message_suffix  = qq{matched multiple policies:\n\t};
        $message_suffix .= join qq{,\n\t}, apply { chomp } sort $self->policies();
    }

    $errors->add_exception(
        $self->_new_global_value_exception(
            option_name     => $SINGLE_POLICY_CONFIG_KEY,
            option_value    => $patterns,
            message_suffix  => $message_suffix,
        )
    );

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_regex {
    my ($self, $option_name, $args_value, $default_value, $errors) = @_;

    my $full_option_name;
    my $source;
    my @regexes;

    if ($args_value) {
        $full_option_name = "-$option_name";

        if (ref $args_value) {
            @regexes = @{ $args_value };
        }
        else {
            @regexes = ( $args_value );
        }
    }

    if (not @regexes) {
        $full_option_name = $option_name;
        $source = $self->_profile()->source();

        if (ref $default_value) {
            @regexes = @{ $default_value };
        }
        elsif ($default_value) {
            @regexes = ( $default_value );
        }
    }

    my $found_errors;
    foreach my $regex (@regexes) {
        eval { my $test = qr/$regex/ixms; }
            or do {
                my $cleaned_error = $EVAL_ERROR || '<unknown reason>';
                $cleaned_error =~
                    s/ [ ] at [ ] .* Config [.] pm [ ] line [ ] \d+ [.] \n? \z/./xms;

                $errors->add_exception(
                    $self->_new_global_value_exception(
                        option_name     => $option_name,
                        option_value    => $regex,
                        source          => $source,
                        message_suffix  => qq{is not valid: $cleaned_error},
                    )
                );

                $found_errors = 1;
            }
    }

    if (not $found_errors) {
        my $option_key = $option_name;
        $option_key =~ s/ - /_/xmsg;

        $self->{"_$option_key"} = \@regexes;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_profile_strictness {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $profile_strictness;

    if ($args_value) {
        $option_name = '-profile-strictness';
        $profile_strictness = $args_value;
    }
    else {
        $option_name = 'profile-strictness';

        my $profile = $self->_profile();
        $source = $profile->source();
        $profile_strictness = $profile->options_processor()->profile_strictness();
    }

    if ( not $PROFILE_STRICTNESSES{$profile_strictness} ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $profile_strictness,
                source          => $source,
                message_suffix  => q{is not one of "}
                    . join ( q{", "}, (sort keys %PROFILE_STRICTNESSES) )
                    . q{".},
            )
        );

        $profile_strictness = $PROFILE_STRICTNESS_FATAL;
    }

    $self->{_profile_strictness} = $profile_strictness;

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_verbosity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $verbosity;

    if ($args_value) {
        $option_name = '-verbose';
        $verbosity = $args_value;
    }
    else {
        $option_name = 'verbose';

        my $profile = $self->_profile();
        $source = $profile->source();
        $verbosity = $profile->options_processor()->verbose();
    }

    if (
            is_integer($verbosity)
        and not is_valid_numeric_verbosity($verbosity)
    ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $verbosity,
                source          => $source,
                message_suffix  =>
                    'is not the number of one of the pre-defined verbosity formats.',
            )
        );
    }
    else {
        $self->{_verbose} = $verbosity;
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_severity {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $severity;

    if ($args_value) {
        $option_name = '-severity';
        $severity = $args_value;
    }
    else {
        $option_name = 'severity';

        my $profile = $self->_profile();
        $source = $profile->source();
        $severity = $profile->options_processor()->severity();
    }

    if ( is_integer($severity) ) {
        if (
            $severity >= $SEVERITY_LOWEST and $severity <= $SEVERITY_HIGHEST
        ) {
            $self->{_severity} = $severity;
        }
        else {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $severity,
                    source          => $source,
                    message_suffix  =>
                        "is not between $SEVERITY_LOWEST (low) and $SEVERITY_HIGHEST (high).",
                )
            );
        }
    }
    elsif ( not any { $_ eq lc $severity } @SEVERITY_NAMES ) {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $severity,
                source          => $source,
                message_suffix  =>
                    q{is not one of the valid severity names: "}
                        . join (q{", "}, @SEVERITY_NAMES)
                        . q{".},
            )
        );
    }
    else {
        $self->{_severity} = severity_to_number($severity);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_top {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $top;

    if (defined $args_value and $args_value ne q{}) {
        $option_name = '-top';
        $top = $args_value;
    }
    else {
        $option_name = 'top';

        my $profile = $self->_profile();
        $source = $profile->source();
        $top = $profile->options_processor()->top();
    }

    if ( is_integer($top) and $top >= 0 ) {
        $self->{_top} = $top;
    }
    else {
        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $top,
                source          => $source,
                message_suffix  => q{is not a non-negative integer.},
            )
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_theme {
    my ($self, $args_value, $errors) = @_;

    my $option_name;
    my $source;
    my $theme_rule;

    if ($args_value) {
        $option_name = '-theme';
        $theme_rule = $args_value;
    }
    else {
        $option_name = 'theme';

        my $profile = $self->_profile();
        $source = $profile->source();
        $theme_rule = $profile->options_processor()->theme();
    }

    if ( $theme_rule =~ m/$RULE_INVALID_CHARACTER_REGEX/xms ) {
        my $bad_character = $1;

        $errors->add_exception(
            $self->_new_global_value_exception(
                option_name     => $option_name,
                option_value    => $theme_rule,
                source          => $source,
                message_suffix  =>
                    qq{contains an illegal character ("$bad_character").},
            )
        );
    }
    else {
        my $rule_as_code = cook_rule($theme_rule);
        $rule_as_code =~ s/ [\w\d]+ / 1 /gxms;

        # eval of an empty string does not reset $@ in Perl 5.6.
        local $EVAL_ERROR = $EMPTY;
        eval $rule_as_code; ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)

        if ($EVAL_ERROR) {
            $errors->add_exception(
                $self->_new_global_value_exception(
                    option_name     => $option_name,
                    option_value    => $theme_rule,
                    source          => $source,
                    message_suffix  => q{is not syntactically valid.},
                )
            );
        }
        else {
            eval {
                $self->{_theme} =
                    Perl::Critic::Theme->new( -rule => $theme_rule );
            }
                or do {
                    $errors->add_exception_or_rethrow( $EVAL_ERROR );
                };
        }
    }

    return;
}

#-----------------------------------------------------------------------------

sub _validate_and_save_pager {
    my ($self, $args_value, $errors) = @_;

    my $pager;
    if ( $args_value ) {
        $pager = defined $args_value ? $args_value : $EMPTY;
    }
    elsif ( $ENV{PERLCRITIC_PAGER} ) {
        $pager = $ENV{PERLCRITIC_PAGER};
    }
    else {
        my $profile = $self->_profile();
        $pager = $profile->options_processor()->pager();
    }

    if ($pager eq '$PAGER') {   ## no critic (RequireInterpolationOfMetachars)
        $pager = $ENV{PAGER};
    }
    $pager ||= $EMPTY;

    $self->{_pager} = $pager;

    return;
}

#-----------------------------------------------------------------------------
# Begin ACCESSSOR methods

sub _profile {
    my $self = shift;
    return $self->{_profile};
}

#-----------------------------------------------------------------------------

sub policies {
    my $self = shift;
    return @{ $self->{_policies} };
}

#-----------------------------------------------------------------------------

sub exclude {
    my $self = shift;
    return @{ $self->{_exclude} };
}

#-----------------------------------------------------------------------------

sub force {
    my $self = shift;
    return $self->{_force};
}

#-----------------------------------------------------------------------------

sub include {
    my $self = shift;
    return @{ $self->{_include} };
}

#-----------------------------------------------------------------------------

sub only {
    my $self = shift;
    return $self->{_only};
}

#-----------------------------------------------------------------------------

sub profile_strictness {
    my $self = shift;
    return $self->{_profile_strictness};
}

#-----------------------------------------------------------------------------

sub severity {
    my $self = shift;
    return $self->{_severity};
}

#-----------------------------------------------------------------------------

sub single_policy {
    my $self = shift;
    return @{ $self->{_single_policy} };
}

#-----------------------------------------------------------------------------

sub theme {
    my $self = shift;
    return $self->{_theme};
}

#-----------------------------------------------------------------------------

sub top {
    my $self = shift;
    return $self->{_top};
}

#-----------------------------------------------------------------------------

sub verbose {
    my $self = shift;
    return $self->{_verbose};
}

#-----------------------------------------------------------------------------

sub color {
    my $self = shift;
    return $self->{_color};
}

#-----------------------------------------------------------------------------

sub pager  {
    my $self = shift;
    return $self->{_pager};
}

#-----------------------------------------------------------------------------

sub criticism_fatal {
    my $self = shift;
    return $self->{_criticism_fatal};
}

#-----------------------------------------------------------------------------

sub site_policy_names {
    return Perl::Critic::PolicyFactory::site_policy_names();
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords -params INI-style

=head1 NAME

Perl::Critic::Config - The final derived Perl::Critic configuration, combined from any profile file and command-line parameters.

=head1 DESCRIPTION

Perl::Critic::Config takes care of finding and processing
user-preferences for L<Perl::Critic|Perl::Critic>.  The Config object
defines which Policy modules will be loaded into the Perl::Critic
engine and how they should be configured.  You should never really
need to instantiate Perl::Critic::Config directly because the
Perl::Critic constructor will do it for you.

=head1 CONSTRUCTOR

=over 8

=item C<< new( [ -profile => $FILE, -severity => $N, -theme => $string, -include => \@PATTERNS, -exclude => \@PATTERNS, -single-policy => $PATTERN, -top => $N, -only => $B, -profile-strictness => $PROFILE_STRICTNESS_{WARN|FATAL|QUIET}, -force => $B, -verbose => $N, -color => $B, -criticism-fatal => $B] ) >>

=item C<< new() >>

Returns a reference to a new Perl::Critic::Config object.  The default
value for all arguments can be defined in your F<.perlcriticrc> file.
See the L<"CONFIGURATION"> section for more information about that.
All arguments are optional key-value pairs as follows:

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

B<-theme> is special string that defines a set of Policies based on
their respective themes.  If C<-theme> is given, only policies that
are members of that set will be loaded.  See the L<"POLICY THEMES">
section for more information about themes.  Unless the C<-severity>
option is explicitly given, setting C<-theme> causes the C<-severity>
to be set to 1.

B<-include> is a reference to a list of string C<@PATTERNS>.  Policies
that match at least one C<m/$PATTERN/ixms> will be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-exclude> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

B<-exclude> is a reference to a list of string C<@PATTERNS>.  Polices
that match at least one C<m/$PATTERN/ixms> will not be loaded into this
Config, irrespective of the severity settings.  You can use it in
conjunction with the C<-include> option.  Note that C<-exclude> takes
precedence over C<-include> when a Policy matches both patterns.

B<-single-policy> is a string C<PATTERN>.  Only the policy that
matches C<m/$PATTERN/ixms> will be used.  This value overrides the
C<-severity>, C<-theme>, C<-include>, C<-exclude>, and C<-only>
options.

B<-top> is the maximum number of Violations to return when ranked by
their severity levels.  This must be a positive integer.  Violations
are still returned in the order that they occur within the file.
Unless the C<-severity> option is explicitly given, setting C<-top>
silently causes the C<-severity> to be set to 1.

B<-only> is a boolean value.  If set to a true value, Perl::Critic
will only choose from Policies that are mentioned in the user's
profile.  If set to a false value (which is the default), then
Perl::Critic chooses from all the Policies that it finds at your site.

B<-profile-strictness> is an enumerated value, one of
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_WARN"> (the
default),
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">, and
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_QUIET">.  If set
to L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_FATAL">,
Perl::Critic will make certain warnings about problems found in a
F<.perlcriticrc> or file specified via the B<-profile> option fatal.
For example, Perl::Critic normally only C<warn>s about profiles
referring to non-existent Policies, but this value makes this
situation fatal.  Correspondingly,
L<Perl::Critic::Utils::Constants/"$PROFILE_STRICTNESS_QUIET"> makes
Perl::Critic shut up about these things.

B<-force> controls whether Perl::Critic observes the magical C<"## no
critic"> pseudo-pragmas in your code.  If set to a true value,
Perl::Critic will analyze all code.  If set to a false value (which is
the default) Perl::Critic will ignore code that is tagged with these
comments.  See L<Perl::Critic/"BENDING THE RULES"> for more
information.

B<-verbose> can be a positive integer (from 1 to 10), or a literal
format specification.  See
L<Perl::Critic::Violations|Perl::Critic::Violations> for an
explanation of format specifications.

B<-color> and B<-pager> are not used by Perl::Critic but is provided
for the benefit of L<perlcritic|perlcritic>.

B<-criticism-fatal> is not used by Perl::Critic but is provided for
the benefit of L<criticism|criticism>.



=back

=head1 METHODS

=over 8

=item C<< add_policy( -policy => $policy_name, -params => \%param_hash ) >>

Creates a Policy object and loads it into this Config.  If the object
cannot be instantiated, it will throw a fatal exception.  Otherwise,
it returns a reference to this Critic.

B<-policy> is the name of a
L<Perl::Critic::Policy|Perl::Critic::Policy> subclass module.  The
C<'Perl::Critic::Policy'> portion of the name can be omitted for
brevity.  This argument is required.

B<-params> is an optional reference to a hash of Policy parameters.
The contents of this hash reference will be passed into to the
constructor of the Policy module.  See the documentation in the
relevant Policy module for a description of the arguments it supports.

=item C< policies() >

Returns a list containing references to all the Policy objects that
have been loaded into this Config.  Objects will be in the order that
they were loaded.

=item C< exclude() >

Returns the value of the C<-exclude> attribute for this Config.

=item C< include() >

Returns the value of the C<-include> attribute for this Config.

=item C< force() >

Returns the value of the C<-force> attribute for this Config.

=item C< only() >

Returns the value of the C<-only> attribute for this Config.

=item C< profile_strictness() >

Returns the value of the C<-profile-strictness> attribute for this
Config.

=item C< severity() >

Returns the value of the C<-severity> attribute for this Config.

=item C< single_policy() >

Returns the value of the C<-single-policy> attribute for this Config.

=item C< theme() >

Returns the L<Perl::Critic::Theme|Perl::Critic::Theme> object that was
created for this Config.

=item C< top() >

Returns the value of the C<-top> attribute for this Config.

=item C< verbose() >

Returns the value of the C<-verbose> attribute for this Config.

=item C< color() >

Returns the value of the C<-color> attribute for this Config.

=item C< pager() >

Returns the value of the C<-pager> attribute for this Config.

=item C< criticism_fatal() >

Returns the value of the C<-criticsm-fatal> attribute for this Config.

=back

=head1 SUBROUTINES

Perl::Critic::Config has a few static subroutines that are used
internally, but may be useful to you in some way.

=over 8

=item C<site_policy_names()>

Returns a list of all the Policy modules that are currently installed
in the Perl::Critic:Policy namespace.  These will include modules that
are distributed with Perl::Critic plus any third-party modules that
have been installed.

=back

=head1 CONFIGURATION

Most of the settings for Perl::Critic and each of the Policy modules
can be controlled by a configuration file.  The default configuration
file is called F<.perlcriticrc>.
L<Perl::Critic::Config|Perl::Critic::Config> will look for this file
in the current directory first, and then in your home directory.
Alternatively, you can set the C<PERLCRITIC> environment variable to
explicitly point to a different file in another location.  If none of
these files exist, and the C<-profile> option is not given to the
constructor, then all Policies will be loaded with their default
configuration.

The format of the configuration file is a series of INI-style blocks
that contain key-value pairs separated by '='. Comments should start
with '#' and can be placed on a separate line or after the name-value
pairs if you desire.

Default settings for Perl::Critic itself can be set B<before the first
named block.>  For example, putting any or all of these at the top of
your configuration file will set the default value for the
corresponding Perl::Critic constructor argument.

    severity  = 3                                     #Integer from 1 to 5
    only      = 1                                     #Zero or One
    force     = 0                                     #Zero or One
    verbose   = 4                                     #Integer or format spec
    top       = 50                                    #A positive integer
    theme     = risky + (pbp * security) - cosmetic   #A theme expression
    include   = NamingConventions ClassHierarchies    #Space-delimited list
    exclude   = Variables  Modules::RequirePackage    #Space-delimited list
    color     = 1                                     #Zero or One

The remainder of the configuration file is a series of blocks like
this:

    [Perl::Critic::Policy::Category::PolicyName]
    severity = 1
    set_themes = foo bar
    add_themes = baz
    arg1 = value1
    arg2 = value2

C<Perl::Critic::Policy::Category::PolicyName> is the full name of a
module that implements the policy.  The Policy modules distributed
with Perl::Critic have been grouped into categories according to the
table of contents in Damian Conway's book B<Perl Best Practices>. For
brevity, you can omit the C<'Perl::Critic::Policy'> part of the module
name.

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
    allow = if unless  #My custom configuration
    severity = 2

    #--------------------------------------------------------------
    # Give these policies a custom theme.  I can activate just
    # these policies by saying (-theme => 'larry + curly')

    [Modules::RequireFilenameMatchesPackage]
    add_themes = larry

    [TestingAndDebugging::RequireTestLables]
    add_themes = curly moe

    #--------------------------------------------------------------
    # I do not agree with these at all, so never load them

    [-NamingConventions::ProhibitMixedCaseVars]
    [-NamingConventions::ProhibitMixedCaseSubs]

    #--------------------------------------------------------------
    # For all other Policies, I accept the default severity, theme
    # and other parameters, so no additional configuration is
    # required for them.

For additional configuration examples, see the F<perlcriticrc> file
that is included in this F<t/examples> directory of this distribution.

=head1 THE POLICIES

A large number of Policy modules are distributed with Perl::Critic.
They are described briefly in the companion document
L<Perl::Critic::PolicySummary|Perl::Critic::PolicySummary> and in more
detail in the individual modules themselves.

=head1 POLICY THEMES

Each Policy is defined with one or more "themes".  Themes can be used
to create arbitrary groups of Policies.  They are intended to provide
an alternative mechanism for selecting your preferred set of Policies.
For example, you may wish disable a certain subset of Policies when
analyzing test scripts.  Conversely, you may wish to enable only a
specific subset of Policies when analyzing modules.

The Policies that ship with Perl::Critic are have been broken into the
following themes.  This is just our attempt to provide some basic
logical groupings.  You are free to invent new themes that suit your
needs.

    THEME             DESCRIPTION
    --------------------------------------------------------------------------
    core              All policies that ship with Perl::Critic
    pbp               Policies that come directly from "Perl Best Practices"
    bugs              Policies that that prevent or reveal bugs
    maintenance       Policies that affect the long-term health of the code
    cosmetic          Policies that only have a superficial effect
    complexity        Policies that specificaly relate to code complexity
    security          Policies that relate to security issues
    tests             Policies that are specific to test scripts


Say C<`perlcritic -list`> to get a listing of all available policies
and the themes that are associated with each one.  You can also change
the theme for any Policy in your F<.perlcriticrc> file.  See the
L<"CONFIGURATION"> section for more information about that.

Using the C<-theme> option, you can combine theme names with
mathematical and boolean operators to create an arbitrarily complex
expression that represents a custom "set" of Policies.  The following
operators are supported

   Operator       Alternative         Meaning
   ----------------------------------------------------------------------------
   *              and                 Intersection
   -              not                 Difference
   +              or                  Union

Operator precedence is the same as that of normal mathematics.  You
can also use parenthesis to enforce precedence.  Here are some
examples:

   Expression                  Meaning
   ----------------------------------------------------------------------------
   pbp * bugs                  All policies that are "pbp" AND "bugs"
   pbp and bugs                Ditto

   bugs + cosmetic             All policies that are "bugs" OR "cosmetic"
   bugs or cosmetic            Ditto

   pbp - cosmetic              All policies that are "pbp" BUT NOT "cosmetic"
   pbp not cosmetic            Ditto

   -maintenance                All policies that are NOT "maintenance"
   not maintenance             Ditto

   (pbp - bugs) * complexity     All policies that are "pbp" BUT NOT "bugs",
                                    AND "complexity"
   (pbp not bugs) and complexity  Ditto

Theme names are case-insensitive.  If C<-theme> is set to an empty
string, then it is equivalent to the set of all Policies.  A theme
name that doesn't exist is equivalent to an empty set.  Please See
L<http://en.wikipedia.org/wiki/Set> for a discussion on set theory.

=head1 SEE ALSO

L<Perl::Critic::OptionsProcessor|Perl::Critic::OptionsProcessor>,
L<Perl::Critic::UserProfile|Perl::Critic::UserProfile>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

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
