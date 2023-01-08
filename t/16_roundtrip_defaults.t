#!perl

use 5.010001;
use strict;
use warnings;

use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Config;
use Perl::Critic::ProfilePrototype;
use Perl::Critic::Utils qw{ :characters :severities };

use Test::More;

our $VERSION = '1.148';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

my $default_configuration =
    Perl::Critic::Config->new(
        -profile => $EMPTY,
        -severity => 1,
        -theme => 'core',
    );
my @default_policies = $default_configuration->policies();

my $policy_test_count;

$policy_test_count = 4 * @default_policies;
foreach my $policy (@default_policies) {
    if (
            $policy->parameter_metadata_available()
        and not $policy->isa('Perl::Critic::Policy::CodeLayout::RequireTidyCode')
    ) {
        $policy_test_count += scalar @{$policy->get_parameters()};
    }
}
my $test_count = 18 + $policy_test_count;
plan tests => $test_count;

#-----------------------------------------------------------------------------

my $profile_generator =
    Perl::Critic::ProfilePrototype->new(
        -policies                   => \@default_policies,
        '-comment-out-parameters'   => 0,
        -config                     => $default_configuration,
    );
my $profile = $profile_generator->to_string();

my $derived_configuration =
    Perl::Critic::Config->new( -profile => \$profile );

#-----------------------------------------------------------------------------

my @cmp_ok_methods = qw(
    verbose
    top
    severity
);

for my $method ( @cmp_ok_methods ) {
    cmp_ok(
        $derived_configuration->$method,
        q<==>,
        $default_configuration->$method,
        $method,
    );
}

#-----------------------------------------------------------------------------

my @is_deeply_array_methods = qw(
    exclude
    include
    program_extensions
    single_policy
);

for my $method ( @is_deeply_array_methods ) {
    is_deeply(
        [ $derived_configuration->$method ],
        [ $default_configuration->$method ],
        $method,
    );
}

#-----------------------------------------------------------------------------

my @is_deeply_arrayref_methods = qw(
    theme
);

for my $method ( @is_deeply_arrayref_methods ) {
    is_deeply(
        $derived_configuration->$method,
        $default_configuration->$method,
        $method,
    );
}

#-----------------------------------------------------------------------------

my @str_methods = qw(
    force
    profile_strictness
    only
    color
    color_severity_highest
    color_severity_high
    color_severity_medium
    color_severity_low
    color_severity_lowest
);

for my $method ( @str_methods ) {
    is(
        $derived_configuration->$method,
        $default_configuration->$method,
        $method
    );
}

#-----------------------------------------------------------------------------

my @derived_policies = $derived_configuration->policies();

my $policy_counts_match =
    is(
        scalar @derived_policies,
        scalar @default_policies,
        'same policy count'
    );

SKIP: {
    skip
        q{because there weren't the same number of policies},
            $policy_test_count
        if not $policy_counts_match;

    for (my $x = 0; $x < @default_policies; $x++) { ## no critic (ProhibitCStyleForLoops)
        my $derived_policy = $derived_policies[$x];
        my $default_policy = $default_policies[$x];

        is(
            $derived_policy->get_short_name(),
            $default_policy->get_short_name(),
            'policy names match',
        );
        is(
            $derived_policy->get_maximum_violations_per_document(),
            $default_policy->get_maximum_violations_per_document(),
            $default_policy->get_short_name() . ' maximum violations per document match',
        );
        is(
            $derived_policy->get_severity(),
            $default_policy->get_severity(),
            $default_policy->get_short_name() . ' severities match',
        );
        is(
            $derived_policy->get_themes(),
            $default_policy->get_themes(),
            $default_policy->get_short_name() . ' themes match',
        );

        if (
                $default_policy->parameter_metadata_available()
            and not $default_policy->isa('Perl::Critic::Policy::CodeLayout::RequireTidyCode')
        ) {
            # Encapsulation violation alert!
            foreach my $parameter ( @{$default_policy->get_parameters()} ) {
                my $parameter_name =
                    $default_policy->__get_parameter_name( $parameter );

                is_deeply(
                    $derived_policy->{$parameter_name},
                    $default_policy->{$parameter_name},
                    $default_policy->get_short_name()
                        . $SPACE
                        . $parameter_name
                        . ' match',
                );
            }
        }
    }
}


#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
