#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use PPI::Document;
use Test::More;
use Perl::Critic::TestUtils qw(bundled_policy_names);
use English qw(-no_match_vars);

#-----------------------------------------------------------------------------

our $VERSION = 1.075_001;

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my @bundled_policy_names = bundled_policy_names();
plan tests => 113 + 14 * scalar @bundled_policy_names;

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test Perl::Critic module interface

use_ok('Perl::Critic');
can_ok('Perl::Critic', 'new');
can_ok('Perl::Critic', 'add_policy');
can_ok('Perl::Critic', 'config');
can_ok('Perl::Critic', 'critique');
can_ok('Perl::Critic', 'policies');

#Set -profile to avoid messing with .perlcriticrc
my $critic = Perl::Critic->new( -profile => 'NONE' );
isa_ok($critic, 'Perl::Critic');
is($critic->VERSION(), $version_string, 'Perl::Critic version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Config module interface

use_ok('Perl::Critic::Config');
can_ok('Perl::Critic::Config', 'new');
can_ok('Perl::Critic::Config', 'add_policy');
can_ok('Perl::Critic::Config', 'policies');
can_ok('Perl::Critic::Config', 'exclude');
can_ok('Perl::Critic::Config', 'force');
can_ok('Perl::Critic::Config', 'include');
can_ok('Perl::Critic::Config', 'only');
can_ok('Perl::Critic::Config', 'profile_strictness');
can_ok('Perl::Critic::Config', 'severity');
can_ok('Perl::Critic::Config', 'single_policy');
can_ok('Perl::Critic::Config', 'theme');
can_ok('Perl::Critic::Config', 'top');
can_ok('Perl::Critic::Config', 'verbose');
can_ok('Perl::Critic::Config', 'color');
can_ok('Perl::Critic::Config', 'site_policy_names');

#Set -profile to avoid messing with .perlcriticrc
my $config = Perl::Critic::Config->new( -profile => 'NONE');
isa_ok($config, 'Perl::Critic::Config');
is($config->VERSION(), $version_string, 'Perl::Critic::Config version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::ConfigErrors module interface

use_ok('Perl::Critic::ConfigErrors');
can_ok('Perl::Critic::ConfigErrors', 'new');
can_ok('Perl::Critic::ConfigErrors', 'messages');
can_ok('Perl::Critic::ConfigErrors', 'add_message');
can_ok('Perl::Critic::ConfigErrors', 'add_bad_option_message');

my $errors = Perl::Critic::ConfigErrors->new();
isa_ok($errors, 'Perl::Critic::ConfigErrors');
is($errors->VERSION(), $version_string, 'Perl::Critic::ConfigErrors version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Config::Defaults module interface

use_ok('Perl::Critic::Defaults');
can_ok('Perl::Critic::Defaults', 'new');
can_ok('Perl::Critic::Defaults', 'exclude');
can_ok('Perl::Critic::Defaults', 'include');
can_ok('Perl::Critic::Defaults', 'force');
can_ok('Perl::Critic::Defaults', 'only');
can_ok('Perl::Critic::Defaults', 'profile_strictness');
can_ok('Perl::Critic::Defaults', 'single_policy');
can_ok('Perl::Critic::Defaults', 'severity');
can_ok('Perl::Critic::Defaults', 'theme');
can_ok('Perl::Critic::Defaults', 'top');
can_ok('Perl::Critic::Defaults', 'verbose');
can_ok('Perl::Critic::Defaults', 'color');

my $defaults = Perl::Critic::Defaults->new();
isa_ok($defaults, 'Perl::Critic::Defaults');
is($defaults->VERSION(), $version_string, 'Perl::Critic::Defaults version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Policy module interface

use_ok('Perl::Critic::Policy');
can_ok('Perl::Critic::Policy', 'add_themes');
can_ok('Perl::Critic::Policy', 'applies_to');
can_ok('Perl::Critic::Policy', 'default_severity');
can_ok('Perl::Critic::Policy', 'default_themes');
can_ok('Perl::Critic::Policy', 'get_severity');
can_ok('Perl::Critic::Policy', 'get_themes');
can_ok('Perl::Critic::Policy', 'new');
can_ok('Perl::Critic::Policy', 'set_severity');
can_ok('Perl::Critic::Policy', 'set_themes');
can_ok('Perl::Critic::Policy', 'violates');
can_ok('Perl::Critic::Policy', 'violation');


my $policy = Perl::Critic::Policy->new();
isa_ok($policy, 'Perl::Critic::Policy');
is($policy->VERSION(), $version_string, 'Perl::Critic::Policy version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Violation module interface

use_ok('Perl::Critic::Violation');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'diagnostics');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'get_format');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'set_format');
can_ok('Perl::Critic::Violation', 'severity');
can_ok('Perl::Critic::Violation', 'sort_by_location');
can_ok('Perl::Critic::Violation', 'sort_by_severity');
can_ok('Perl::Critic::Violation', 'source');
can_ok('Perl::Critic::Violation', 'to_string');

my $code = q{print 'Hello World';};
my $doc = PPI::Document->new(\$code);
my $viol = Perl::Critic::Violation->new(undef, undef, $doc, undef);
isa_ok($viol, 'Perl::Critic::Violation');
is($viol->VERSION(), $version_string, 'Perl::Critic::Violation version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::UserProfile module interface

use_ok('Perl::Critic::UserProfile');
can_ok('Perl::Critic::UserProfile', 'defaults');
can_ok('Perl::Critic::UserProfile', 'new');
can_ok('Perl::Critic::UserProfile', 'policy_is_disabled');
can_ok('Perl::Critic::UserProfile', 'policy_is_enabled');

my $up = Perl::Critic::UserProfile->new();
isa_ok($up, 'Perl::Critic::UserProfile');
is($up->VERSION(), $version_string, 'Perl::Critic::UserProfile version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::PolicyFactory module interface

use_ok('Perl::Critic::PolicyFactory');
can_ok('Perl::Critic::PolicyFactory', 'create_policy');
can_ok('Perl::Critic::PolicyFactory', 'new');
can_ok('Perl::Critic::PolicyFactory', 'site_policy_names');


my $profile = Perl::Critic::UserProfile->new();
my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
isa_ok($factory, 'Perl::Critic::PolicyFactory');
is($factory->VERSION(), $version_string, 'Perl::Critic::PolicyFactory version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Theme module interface

use_ok('Perl::Critic::Theme');
can_ok('Perl::Critic::Theme', 'new');
can_ok('Perl::Critic::Theme', 'rule');
can_ok('Perl::Critic::Theme', 'policy_is_thematic');


my $theme = Perl::Critic::Theme->new( -rule => 'foo' );
isa_ok($theme, 'Perl::Critic::Theme');
is($theme->VERSION(), $version_string, 'Perl::Critic::Theme version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::PolicyListing module interface

use_ok('Perl::Critic::PolicyListing');
can_ok('Perl::Critic::PolicyListing', 'new');
can_ok('Perl::Critic::PolicyListing', 'to_string');

my $listing = Perl::Critic::PolicyListing->new();
isa_ok($listing, 'Perl::Critic::PolicyListing');
is($listing->VERSION(), $version_string, 'Perl::Critic::PolicyListing version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::ProfilePrototype module interface

use_ok('Perl::Critic::ProfilePrototype');
can_ok('Perl::Critic::ProfilePrototype', 'new');
can_ok('Perl::Critic::ProfilePrototype', 'to_string');

my $prototype = Perl::Critic::ProfilePrototype->new();
isa_ok($prototype, 'Perl::Critic::ProfilePrototype');
is($listing->VERSION(), $version_string, 'Perl::Critic::ProfilePrototype version');

#-----------------------------------------------------------------------------
# Test module interface for each Policy subclass

{
    for my $mod ( @bundled_policy_names ) {

        use_ok($mod);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'violates');
        can_ok($mod, 'violation');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::Critic::Policy');
        is($policy->VERSION(), $version_string, "Version of $mod");
    }
}

#-----------------------------------------------------------------------------
# Test functional interface to Perl::Critic

Perl::Critic->import( qw(critique) );
can_ok('main', 'critique');  #Export test

# TODO: These tests are weak. They just verify that it doesn't
# blow up, and that at least one violation is returned.
ok( critique( \$code ), 'Functional style, no config' );
ok( critique( {}, \$code ), 'Functional style, empty config' );
ok( critique( {severity => 1}, \$code ), 'Functional style, with config');
ok( !critique(), 'Functional style, no args at all');
ok( !critique(undef, undef), 'Functional style, undef args');

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
