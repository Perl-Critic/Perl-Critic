#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;

use File::Spec;
use List::MoreUtils qw(all any);

use Perl::Critic::Exception::AggregateConfiguration;
use Perl::Critic::Config qw<>;
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::TestUtils qw<
    bundled_policy_names
    names_of_policies_willing_to_work
>;
use Perl::Critic::Utils qw< :booleans :characters :severities >;
use Perl::Critic::Utils::Constants qw< :color_severity >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

my @names_of_policies_willing_to_work =
    names_of_policies_willing_to_work(
        -severity   => $SEVERITY_LOWEST,
        -theme      => 'core',
    );
my @native_policy_names  = bundled_policy_names();
my $total_policies   = scalar @names_of_policies_willing_to_work;

#-----------------------------------------------------------------------------

{
    my $all_policy_count =
        scalar
            Perl::Critic::Config
                ->new(
                    -severity   => $SEVERITY_LOWEST,
                    -theme      => 'core',
                )
                ->all_policies_enabled_or_not();

    plan tests => 93 + $all_policy_count;
}

#-----------------------------------------------------------------------------
# Test default config.  Increasing the severity should yield
# fewer and fewer policies.  The exact number will fluctuate
# as we introduce new polices and/or change their severity.

{
    my $last_policy_count = $total_policies + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my $configuration =
            Perl::Critic::Config->new(
                -severity   => $severity,
                -theme      => 'core',
            );
        my $policy_count = scalar $configuration->policies();
        my $test_name = "Count native policies, severity: $severity";
        cmp_ok($policy_count, '<', $last_policy_count, $test_name);
        $last_policy_count = $policy_count;
    }
}


#-----------------------------------------------------------------------------
# Same tests as above, but using a generated config

{
    my %profile = map { $_ => {} } @native_policy_names;
    my $last_policy_count = $total_policies + 1;
    for my $severity ($SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
        my %pc_args = (
            -profile    => \%profile,
            -severity   => $severity,
            -theme      => 'core',
        );
        my $critic = Perl::Critic::Config->new( %pc_args );
        my $policy_count = scalar $critic->policies();
        my $test_name = "Count all policies, severity: $severity";
        cmp_ok($policy_count, '<', $last_policy_count, $test_name);
        $last_policy_count = $policy_count;
    }
}

#-----------------------------------------------------------------------------

{
    my $configuration =
        Perl::Critic::Config->new(
            -severity   => $SEVERITY_LOWEST,
            -theme      => 'core',
        );
    my %policies_by_name =
        map { $_->get_short_name() => $_ } $configuration->policies();

    foreach my $policy ( $configuration->all_policies_enabled_or_not() ) {
        my $enabled = $policy->is_enabled();
        if ( delete $policies_by_name{ $policy->get_short_name() } ) {
            ok(
                $enabled,
                $policy->get_short_name() . ' is enabled.',
            );
        }
        else {
            ok(
                ! $enabled && defined $enabled,
                $policy->get_short_name() . ' is not enabled.',
            );
        }
    }

}


#-----------------------------------------------------------------------------
# Test all-off config w/ various severity levels.  In this case, the
# severity level should not affect the number of polices because we've
# turned them all off in the profile.

#{
#    my %profile = map { '-' . $_ => {} } @native_policy_names;
#    for my $severity (undef, $SEVERITY_LOWEST .. $SEVERITY_HIGHEST) {
#        my $severity_string = $severity ? $severity : '<undef>';
#        my %pc_args = (
#            -profile    => \%profile,
#            -severity   => $severity,
#            -theme      => 'core',
#        );
#
#        eval {
#            Perl::Critic::Config->new( %pc_args )->policies();
#        };
#        my $exception = Perl::Critic::Exception::AggregateConfiguration->caught();
#        ok(
#            defined $exception,
#            "got exception when no policies were enabled at severity $severity_string.",
#        );
#        like(
#            $exception,
#            qr<There are no enabled policies>,
#            "got correct exception message when no policies were enabled at severity $severity_string.",
#        );
#    }
#}

#-----------------------------------------------------------------------------
# Test config w/ multiple severity levels.  In this profile, we
# define an arbitrary severity for each Policy so that severity
# levels 5 through 2 each have 10 Policies.  All remaining Policies
# are in the 1st severity level.


{
    my %profile = ();
    my $severity = $SEVERITY_HIGHEST;
    for my $index ( 0 .. $#names_of_policies_willing_to_work ) {
        if ($index and $index % 10 == 0) {
            $severity--;
        }
        if ($severity < $SEVERITY_LOWEST) {
            $severity = $SEVERITY_LOWEST;
        }

        $profile{$names_of_policies_willing_to_work[$index]} =
            {severity => $severity};
    }

    for my $severity ( reverse $SEVERITY_LOWEST+1 .. $SEVERITY_HIGHEST ) {
        my %pc_args = (
            -profile    => \%profile,
            -severity   => $severity,
            -theme      => 'core',
        );
        my $critic = Perl::Critic::Config->new( %pc_args );
        my $policy_count = scalar $critic->policies();
        my $expected_count = ($SEVERITY_HIGHEST - $severity + 1) * 10;
        my $test_name = "user-defined severity level: $severity";
        is( $policy_count, $expected_count, $test_name );
    }

    # All remaining policies should be at the lowest severity
    my %pc_args = (-profile => \%profile, -severity => $SEVERITY_LOWEST);
    my $critic = Perl::Critic::Config->new( %pc_args );
    my $policy_count = scalar $critic->policies();
    my $expected_count = $SEVERITY_HIGHEST * 10;
    my $test_name = 'user-defined severity, all remaining policies';
    cmp_ok( $policy_count, '>=', $expected_count, $test_name);
}

#-----------------------------------------------------------------------------
# Test config with defaults

{
    my $examples_dir = 'examples';
    my $profile = File::Spec->catfile( $examples_dir, 'perlcriticrc' );
    my $c = Perl::Critic::Config->new( -profile => $profile );

    is_deeply([$c->exclude()], [ qw(Documentation Naming) ],
              'user default exclude from file' );

    is_deeply([$c->include()], [ qw(CodeLayout Modules) ],
              'user default include from file' );

    is($c->force(),    1,  'user default force from file'     );
    is($c->only(),     1,  'user default only from file'      );
    is($c->severity(), 3,  'user default severity from file'  );
    is($c->theme()->rule(),    'danger || risky && ! pbp',  'user default theme from file');
    is($c->top(),      50, 'user default top from file'       );
    is($c->verbose(),  5,  'user default verbose from file'   );

    is($c->color_severity_highest(), 'bold red underline',
                        'user default color-severity-highest from file');
    is($c->color_severity_high(), 'bold magenta',
                        'user default color-severity-high from file');
    is($c->color_severity_medium(), 'blue',
                        'user default color-severity-medium from file');
    is($c->color_severity_low(), $EMPTY,
                        'user default color-severity-low from file');
    is($c->color_severity_lowest(), $EMPTY,
                        'user default color-severity-lowest from file');

    is_deeply([$c->program_extensions], [],
        'user default program-extensions from file');
    is_deeply([$c->program_extensions_as_regexes],
        [qr< @{[ quotemeta '.PL' ]} \z >smx ],
        'user default program-extensions from file, as regexes');
}

#-----------------------------------------------------------------------------
#Test pattern matching


{
    # In this test, we'll use a cusotm profile to deactivate some
    # policies, and then use the -include option to re-activate them.  So
    # the net result is that we should still end up with the all the
    # policies.

    my %profile = (
        '-NamingConventions::Capitalization' => {},
        '-CodeLayout::ProhibitQuotedWordLists' => {},
    );

    my @include = qw(capital quoted);
    my %pc_args = (
        -profile    => \%profile,
        -severity   => 1,
        -include    => \@include,
        -theme      => 'core',
    );
    my @policies = Perl::Critic::Config->new( %pc_args )->policies();
    is(scalar @policies, $total_policies, 'include pattern matching');
}

#-----------------------------------------------------------------------------

{
    # For this test, we'll load the default config, but deactivate some of
    # the policies using the -exclude option.  Then we make sure that none
    # of the remaining policies match the -exclude patterns.

    my @exclude = qw(quote mixed VALUES); #Some assorted pattterns
    my %pc_args = (
        -severity   => 1,
        -exclude    => \@exclude,
    );
    my @policies = Perl::Critic::Config->new( %pc_args )->policies();
    my $matches = grep { my $pol = ref $_; grep { $pol !~ /$_/ixms} @exclude } @policies;
    is(scalar @policies, $matches, 'exclude pattern matching');
}

#-----------------------------------------------------------------------------

{
    # In this test, we set -include and -exclude patterns to both match
    # some of the same policies.  The -exclude option should have
    # precendece.

    my @include = qw(builtinfunc); #Include BuiltinFunctions::*
    my @exclude = qw(block);       #Exclude RequireBlockGrep, RequireBlockMap
    my %pc_args = (
        -severity   => 1,
        -include    => \@include,
        -exclude    => \@exclude,
    );
    my @policies = Perl::Critic::Config->new( %pc_args )->policies();
    my @pol_names = map {ref $_} @policies;
    is_deeply(
        [grep {/block/ixms} @pol_names],
        [],
        'include/exclude pattern match had no "block" policies',
    );
    # This odd construct arises because "any" can't be used with parens without syntax error(!)
    ok(
        @{[any {/builtinfunc/ixms} @pol_names]},
        'include/exclude pattern match had "builtinfunc" policies',
    );
}

#-----------------------------------------------------------------------------
# Test the switch behavior

{
    my @switches = qw(
        -top
        -verbose
        -theme
        -severity
        -only
        -force
        -color
        -pager
        -allow-unsafe
        -criticism-fatal
        -color-severity-highest
        -color-severity-high
        -color-severity-medium
        -color-severity-low
        -color-severity-lowest
    );

    # Can't use IO::Interactive here because we /don't/ want to check STDIN.
    my $color = -t *STDOUT ? $TRUE : $FALSE; ## no critic (ProhibitInteractiveTest)

    my %undef_args = map { $_ => undef } @switches;
    my $c = Perl::Critic::Config->new( %undef_args );
    $c = Perl::Critic::Config->new( %undef_args );
    is( $c->force(),            0,      'Undefined -force');
    is( $c->only(),             0,      'Undefined -only');
    is( $c->severity(),         5,      'Undefined -severity');
    is( $c->theme()->rule(),    q{},    'Undefined -theme');
    is( $c->top(),              0,      'Undefined -top');
    is( $c->color(),            $color, 'Undefined -color');
    is( $c->pager(),            q{},    'Undefined -pager');
    is( $c->unsafe_allowed(),   0,      'Undefined -allow-unsafe');
    is( $c->verbose(),          4,      'Undefined -verbose');
    is( $c->criticism_fatal(),  0,      'Undefined -criticism-fatal');
    is( $c->color_severity_highest(),
        $PROFILE_COLOR_SEVERITY_HIGHEST_DEFAULT,
        'Undefined -color-severity-highest'
    );
    is( $c->color_severity_high(),
        $PROFILE_COLOR_SEVERITY_HIGH_DEFAULT,
        'Undefined -color-severity-high'
    );
    is( $c->color_severity_medium(),
        $PROFILE_COLOR_SEVERITY_MEDIUM_DEFAULT,
        'Undefined -color-severity-medium'
    );
    is( $c->color_severity_low(),
        $PROFILE_COLOR_SEVERITY_LOW_DEFAULT,
        'Undefined -color-severity-low'
    );
    is( $c->color_severity_lowest(),
        $PROFILE_COLOR_SEVERITY_LOWEST_DEFAULT,
        'Undefined -color-severity-lowest'
    );

    my %zero_args = map { $_ => 0 }
        # Zero is an invalid Term::ANSIColor value.
        grep { $_ !~ m/ \A-color-severity- /smx } @switches;
    $c = Perl::Critic::Config->new( %zero_args );
    is( $c->force(),     0,       'zero -force');
    is( $c->only(),      0,       'zero -only');
    is( $c->severity(),  1,       'zero -severity');
    is( $c->theme()->rule(),     q{},     'zero -theme');
    is( $c->top(),       0,       'zero -top');
    is( $c->color(),     $FALSE,  'zero -color');
    is( $c->pager(),     $EMPTY,  'zero -pager');
    is( $c->unsafe_allowed(),    0,       'zero -allow-unsafe');
    is( $c->verbose(),   4,       'zero -verbose');
    is( $c->criticism_fatal(), 0, 'zero -criticism-fatal');

    my %empty_args = map { $_ => q{} } @switches;
    $c = Perl::Critic::Config->new( %empty_args );
    is( $c->force(),     0,       'empty -force');
    is( $c->only(),      0,       'empty -only');
    is( $c->severity(),  1,       'empty -severity');
    is( $c->theme->rule(),     q{},     'empty -theme');
    is( $c->top(),       0,       'empty -top');
    is( $c->color(),     $FALSE,  'empty -color');
    is( $c->pager(),     q{},     'empty -pager');
    is( $c->unsafe_allowed(),    0,       'empty -allow-unsafe');
    is( $c->verbose(),   4,       'empty -verbose');
    is( $c->criticism_fatal(), 0, 'empty -criticism-fatal');
    is( $c->color_severity_highest(), $EMPTY, 'empty -color-severity-highest');
    is( $c->color_severity_high(),   $EMPTY, 'empty -color-severity-high');
    is( $c->color_severity_medium(), $EMPTY, 'empty -color-severity-medium');
    is( $c->color_severity_low(),    $EMPTY, 'empty -color-severity-low');
    is( $c->color_severity_lowest(), $EMPTY, 'empty -color-severity-lowest');
}

#-----------------------------------------------------------------------------
# Test the -only switch

{
    my %profile = (
        'NamingConventions::Capitalization' => {},
        'CodeLayout::ProhibitQuotedWordLists' => {},
    );

    my %pc_config = (-severity => 1, -only => 1, -profile => \%profile);
    my @policies = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @policies, 2, '-only switch');

#    %pc_config = ( -severity => 1, -only => 1, -profile => {} );
#    eval { Perl::Critic::Config->new( %pc_config )->policies() };
#    my $exception = Perl::Critic::Exception::AggregateConfiguration->caught();
#    ok(
#        defined $exception,
#        "got exception with -only switch, empty profile.",
#    );
#    like(
#        $exception,
#        qr<There are no enabled policies>,
#        "got correct exception message with -only switch, empty profile.",
#    );
}

#-----------------------------------------------------------------------------
# Test the -single-policy switch

{
    my %pc_config = ('-single-policy' => 'ProhibitMagicNumbers');
    my @policies = Perl::Critic::Config->new( %pc_config )->policies();
    is(scalar @policies, 1, '-single-policy switch');
}

#-----------------------------------------------------------------------------
# Test interaction between switches and defaults

{
    my %true_defaults = (
        force => 1, only  => 1, top => 10, 'allow-unsafe' => 1,
    );
    my %profile  = ( '__defaults__' => \%true_defaults );

    my %pc_config = (
        -force          => 0,
        -only           => 0,
        -top            => 0,
        '-allow-unsafe' => 0,
        -profile        => \%profile,
    );
    my $config = Perl::Critic::Config->new( %pc_config );
    is( $config->force, 0, '-force: default is true, arg is false');
    is( $config->only,  0, '-only: default is true, arg is false');
    is( $config->top,   0, '-top: default is true, arg is false');
    is( $config->unsafe_allowed, 0, '-allow-unsafe: default is true, arg is false');
}

#-----------------------------------------------------------------------------
# Test named severity levels

{
    my %severity_levels = (gentle=>5, stern=>4, harsh=>3, cruel=>2, brutal=>1);
    while (my ($name, $number) = each %severity_levels) {
        my $config = Perl::Critic::Config->new( -severity => $name );
        is( $config->severity(), $number, qq{Severity "$name" is "$number"});
    }
}


#-----------------------------------------------------------------------------
# Test exception handling

{
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    # Try adding a bogus policy
    eval{ $config->add_policy( -policy => 'Bogus::Policy') };
    like(
        $EVAL_ERROR,
        qr/Unable [ ] to [ ] create [ ] policy/xms,
        'add_policy w/ bad args',
    );

    # Try adding w/o policy
    eval { $config->add_policy() };
    like(
        $EVAL_ERROR,
        qr/The [ ] -policy [ ] argument [ ] is [ ] required/xms,
        'add_policy w/o args',
    );

    # Try using bogus named severity level
    eval{ Perl::Critic::Config->new( -severity => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/The value for the global "-severity" option [(]"bogus"[)] is not one of the valid severity names/ms, ## no critic (RequireExtendedFormatting)
        'invalid severity'
    );

    # Try using vague -single-policy option
    eval{ Perl::Critic::Config->new( '-single-policy' => q<.*> ) };
    like(
        $EVAL_ERROR,
        qr/matched [ ] multiple [ ] policies/xms,
        'vague -single-policy',
    );

    # Try using invalid -single-policy option
    eval{ Perl::Critic::Config->new( '-single-policy' => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/did [ ] not [ ] match [ ] any [ ] policies/xms,
        'invalid -single-policy',
    );
}

#-----------------------------------------------------------------------------
# Test the -allow-unsafe switch
{
    my %profile = (
        'NamingConventions::Capitalization' => {},
        'CodeLayout::ProhibitQuotedWordLists' => {},
    );

    # Pretend that ProhibitQuotedWordLists is actually unsafe
    no warnings qw(redefine once);  ## no critic qw(ProhibitNoWarnings)
    local *Perl::Critic::Policy::CodeLayout::ProhibitQuotedWordLists::is_safe = sub {return 0};

    my %safe_pc_config = (-severity => 1, -only => 1, -profile => \%profile);
    my @p = Perl::Critic::Config->new( %safe_pc_config )->policies();
    is(scalar @p, 1, 'Only loaded safe policies without -unsafe switch');

    my %unsafe_pc_config = (%safe_pc_config, '-allow-unsafe' => 1);
    @p = Perl::Critic::Config->new( %unsafe_pc_config )->policies();
    is(scalar @p, 2, 'Also loaded unsafe policies with -allow-unsafe switch');

    my %singular_pc_config = ('-single-policy' => 'QuotedWordLists');
    @p = Perl::Critic::Config->new( %singular_pc_config )->policies();
    is(scalar @p, 1, '-single-policy always loads Policy, even if unsafe');
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/01_config.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
