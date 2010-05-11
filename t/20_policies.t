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

#-----------------------------------------------------------------------------

our $VERSION = '1.106';

#-----------------------------------------------------------------------------

use English qw< -no_match_vars >;
use Carp qw< confess >;

use Perl::Critic::Utils qw< :characters >;
use Perl::Critic::TestUtils qw<
    pcritique_with_violations
    fcritique_with_violations
    subtests_in_tree
>;
use Perl::Critic::Violation qw<>;

use Test::More;

Perl::Critic::TestUtils::block_perlcriticrc();

Perl::Critic::Violation::set_format(
    '%f: %m at line %l, column %c.  %e. (%r)\n' ## no critic (RequireInterpolationOfMetachars)
);

my $subtests_with_extras = subtests_in_tree( 't', 'include extras' );

# Check for cmdline limit on policies.  Example:
#   perl -Ilib t/20_policies.t BuiltinFunctions::ProhibitLvalueSubstr
# or
#   perl -Ilib t/20_policies.t t/BuiltinFunctions/ProhibitLvalueSubstr.run
if (@ARGV) {
    my @policies = keys %{$subtests_with_extras}; # get a list of all tests
    # This is inefficient, but who cares...
    for (@ARGV) {
        next if m/::/xms;
        if (not s<\A t[\\/] (\w+) [\\/] (\w+) [.]run \z><$1\::$2>xms) {
            confess 'Unknown argument ' . $_;
        }
    }
    for my $p (@policies) {
        if (0 == grep {$_ eq $p} @ARGV) {
            delete $subtests_with_extras->{$p};
        }
    }
}

# count how many tests there will be
my $nsubtests = 0;
for my $subtest_with_extras ( values %{$subtests_with_extras} ) {
    # one [pf]critique() test per subtest
    $nsubtests += @{ $subtest_with_extras->{subtests} };
}
my $npolicies = scalar keys %{$subtests_with_extras}; # one can() test per policy

plan tests => $nsubtests + $npolicies;

for my $policy ( sort keys %{$subtests_with_extras} ) {
    can_ok( "Perl::Critic::Policy::$policy", 'violates' );
    for my $subtest ( @{ $subtests_with_extras->{$policy}{subtests} } ) {
        local $TODO = $subtest->{TODO}; # Is NOT a TODO if it's not set

        my $description =
            join ' - ', $policy, "line $subtest->{lineno}", $subtest->{name};

        my ($error, @violations) = run_subtest($policy, $subtest);

        my $test_passed =
            evaluate_test_results(
                $subtest, $description, $error, \@violations,
            );

        if (not $test_passed) {
            foreach my $violation (@violations) {
                diag("Violation found: $violation");
            }
        }
    }
}

sub run_subtest {
    my ($policy, $subtest) = @_;

    my @violations;
    my $error;
    if ( $subtest->{filename} ) {
        eval {
            @violations =
                fcritique_with_violations(
                    $policy,
                    \$subtest->{code},
                    $subtest->{filename},
                    $subtest->{parms},
                );
            1;
        } or do {
            $error = $EVAL_ERROR || 'An unknown problem occurred.';
        };
    }
    else {
        eval {
            @violations =
                pcritique_with_violations(
                    $policy,
                    \$subtest->{code},
                    $subtest->{parms},
                );
            1;
        } or do {
            $error = $EVAL_ERROR || 'An unknown problem occurred.';
        };
    }

    return $error, @violations;
}

sub evaluate_test_results {
    my ($subtest, $description, $error, $violations) = @_;

    my $test_passed;
    if ($subtest->{error}) {
        if ( 'Regexp' eq ref $subtest->{error} ) {
            $test_passed = like($error, $subtest->{error}, $description);
        }
        else {
            $test_passed = ok($error, $description);
        }
    }
    elsif ($error) {
        if ($error =~ m/\A Unable [ ] to [ ] create [ ] policy [ ] [']/xms) {
            # We most likely hit a configuration that a parameter didn't like.
            fail($description);
            diag($error);
            $test_passed = 0;
        }
        else {
            confess $error;
        }
    }
    else {
        my $expected_failures = $subtest->{failures};

        # If any optional modules are NOT installed, then there should be no failures.
        if ($subtest->{optional_modules}) {
            MODULE:
            for my $module (split m/,\s*/xms, $subtest->{optional_modules}) {
                eval "require $module; 1;"
                    or do {
                        $expected_failures = 0;
                        last MODULE;
                    };
            }
        }

        $test_passed =
            is(scalar @{$violations}, $expected_failures, $description);
    }

    return $test_passed;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# 20_policies.t_without_optional_dependencies.t
1;

#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
