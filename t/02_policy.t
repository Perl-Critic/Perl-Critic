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

use English qw<-no_match_vars>;

use Test::More tests => 29;


#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

# Perl::Critic::Policy is an abstract class, so it can't be instantiated
# directly.  So we test it by declaring test classes that inherit from it.

## no critic (ProhibitMultiplePackages, RequireFilenameMatchesPackage)
package PolicyTest;
use base 'Perl::Critic::Policy';

package PolicyTestOverriddenDefaultMaximumViolations;
use base 'Perl::Critic::Policy';

sub default_maximum_violations_per_document { return 31; }

#-----------------------------------------------------------------------------

package main;
## use critic

my $p = PolicyTest->new();
isa_ok($p, 'PolicyTest');


local $EVAL_ERROR = undef;
eval { $p->violates(); 1 };
ok($EVAL_ERROR, 'abstract violates() throws exception');


is(
    $p->is_enabled(),
    undef,
    'is_enabled() initially returns undef',
);


ok( !! $p->is_safe(), 'is_safe() returns a true value by default.' );


# Test default application...
is($p->applies_to(), 'PPI::Element', 'applies_to()');


# Test default maximum violations per document...
is(
    $p->default_maximum_violations_per_document(),
    undef,
    'default_maximum_violations_per_document()',
);
is(
    $p->get_maximum_violations_per_document(),
    undef,
    'get_maximum_violations_per_document()',
);

# Change maximum violations level...
$p->set_maximum_violations_per_document(3);

# Test maximum violations again...
is(
    $p->default_maximum_violations_per_document(),
    undef,
    q<default_maximum_violations_per_document() hasn't changed>,
);
is(
    $p->get_maximum_violations_per_document(),
    3,
    q<get_maximum_violations_per_document() returns new value>,
);


my $overridden_default = PolicyTestOverriddenDefaultMaximumViolations->new();
isa_ok($overridden_default, 'PolicyTestOverriddenDefaultMaximumViolations');

is(
    $overridden_default->is_enabled(),
    undef,
    'is_enabled() initially returns undef',
);

# Test default maximum violations per document...
is(
    $overridden_default->default_maximum_violations_per_document(),
    31,
    'default_maximum_violations_per_document() overridden',
);
is(
    $overridden_default->get_maximum_violations_per_document(),
    31,
    'get_maximum_violations_per_document() overridden',
);

# Change maximum violations level...
$overridden_default->set_maximum_violations_per_document(undef);

# Test maximum violations again...
is(
    $overridden_default->default_maximum_violations_per_document(),
    31,
    q<default_maximum_violations_per_document() overridden hasn't changed>,
);
is(
    $overridden_default->get_maximum_violations_per_document(),
    undef,
    q<get_maximum_violations_per_document() overridden returns new undefined value>,
);


# Test default severity...
is( $p->default_severity(), 1, 'default_severity()');
is( $p->get_severity(), 1, 'get_severity()' );

# Change severity level...
$p->set_severity(3);

# Test severity again...
is( $p->default_severity(), 1, q<default_severity() hasn't changed.>);
is( $p->get_severity(), 3, q<get_severity() returns the new value.> );


# Test default theme...
is_deeply( [$p->default_themes()], [], 'default_themes()');
is_deeply( [$p->get_themes()], [], 'get_themes()');

# Change theme
$p->set_themes( qw(c b a) ); # unsorted

# Test theme again...
is_deeply( [$p->default_themes()], [], q<default_themes() hasn't changed.>);
is_deeply(
    [$p->get_themes()],
    [qw(a b c)],
    'get_themes() returns the new value, sorted.',
);

# Append theme
$p->add_themes( qw(f e d) ); # unsorted

# Test theme again...
is_deeply( [$p->default_themes()], [], q<default_themes() hasn't changed.>);
is_deeply(
    [$p->get_themes()],
    [ qw(a b c d e f) ],
    'get_themes() returns the new value, sorted.',
);


# Test format getter/setters
is( Perl::Critic::Policy::get_format, "%p\n", 'Default policy format');

my $new_format = '%p %s [%t]';
Perl::Critic::Policy::set_format( $new_format ); # Set format
is( Perl::Critic::Policy::get_format, $new_format, 'Changed policy format');

my $expected_string = 'PolicyTest 3 [a b c d e f]';
is( $p->to_string(), $expected_string, 'Stringification by to_string()');
is( "$p", $expected_string, 'Stringification by overloading');


#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/02_policy.t_without_optional_dependencies.t
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
