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

use English qw(-no_match_vars);

use PPI::Document;

use Perl::Critic::TestUtils qw(bundled_policy_names);

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my @bundled_policy_names = bundled_policy_names();

my @concrete_exceptions = qw{
    AggregateConfiguration
    Configuration::Generic
    Configuration::NonExistentPolicy
    Configuration::Option::Global::ExtraParameter
    Configuration::Option::Global::ParameterValue
    Configuration::Option::Policy::ExtraParameter
    Configuration::Option::Policy::ParameterValue
    Fatal::Generic
    Fatal::Internal
    Fatal::PolicyDefinition
    IO
};

plan tests =>
        144
    +   (  9 * scalar @concrete_exceptions  )
    +   ( 17 * scalar @bundled_policy_names );

# pre-compute for version comparisons
my $version_string = __PACKAGE__->VERSION;

#-----------------------------------------------------------------------------
# Test Perl::Critic module interface

use_ok('Perl::Critic') or BAIL_OUT(q<Can't continue.>);
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

use_ok('Perl::Critic::Config') or BAIL_OUT(q<Can't continue.>);
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
can_ok('Perl::Critic::Config', 'unsafe_allowed');
can_ok('Perl::Critic::Config', 'criticism_fatal');
can_ok('Perl::Critic::Config', 'site_policy_names');
can_ok('Perl::Critic::Config', 'color_severity_highest');
can_ok('Perl::Critic::Config', 'color_severity_high');
can_ok('Perl::Critic::Config', 'color_severity_medium');
can_ok('Perl::Critic::Config', 'color_severity_low');
can_ok('Perl::Critic::Config', 'color_severity_lowest');
can_ok('Perl::Critic::Config', 'program_extensions');
can_ok('Perl::Critic::Config', 'program_extensions_as_regexes');

#Set -profile to avoid messing with .perlcriticrc
my $config = Perl::Critic::Config->new( -profile => 'NONE');
isa_ok($config, 'Perl::Critic::Config');
is($config->VERSION(), $version_string, 'Perl::Critic::Config version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Config::OptionsProcessor module interface

use_ok('Perl::Critic::OptionsProcessor') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::OptionsProcessor', 'new');
can_ok('Perl::Critic::OptionsProcessor', 'exclude');
can_ok('Perl::Critic::OptionsProcessor', 'include');
can_ok('Perl::Critic::OptionsProcessor', 'force');
can_ok('Perl::Critic::OptionsProcessor', 'only');
can_ok('Perl::Critic::OptionsProcessor', 'profile_strictness');
can_ok('Perl::Critic::OptionsProcessor', 'single_policy');
can_ok('Perl::Critic::OptionsProcessor', 'severity');
can_ok('Perl::Critic::OptionsProcessor', 'theme');
can_ok('Perl::Critic::OptionsProcessor', 'top');
can_ok('Perl::Critic::OptionsProcessor', 'verbose');
can_ok('Perl::Critic::OptionsProcessor', 'color');
can_ok('Perl::Critic::OptionsProcessor', 'allow_unsafe');
can_ok('Perl::Critic::OptionsProcessor', 'criticism_fatal');
can_ok('Perl::Critic::OptionsProcessor', 'color_severity_highest');
can_ok('Perl::Critic::OptionsProcessor', 'color_severity_high');
can_ok('Perl::Critic::OptionsProcessor', 'color_severity_medium');
can_ok('Perl::Critic::OptionsProcessor', 'color_severity_low');
can_ok('Perl::Critic::OptionsProcessor', 'color_severity_lowest');
can_ok('Perl::Critic::OptionsProcessor', 'program_extensions');

my $processor = Perl::Critic::OptionsProcessor->new();
isa_ok($processor, 'Perl::Critic::OptionsProcessor');
is($processor->VERSION(), $version_string, 'Perl::Critic::OptionsProcessor version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Policy module interface

use_ok('Perl::Critic::Policy') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::Policy', 'add_themes');
can_ok('Perl::Critic::Policy', 'applies_to');
can_ok('Perl::Critic::Policy', 'default_maximum_violations_per_document');
can_ok('Perl::Critic::Policy', 'default_severity');
can_ok('Perl::Critic::Policy', 'default_themes');
can_ok('Perl::Critic::Policy', 'get_abstract');
can_ok('Perl::Critic::Policy', 'get_format');
can_ok('Perl::Critic::Policy', 'get_long_name');
can_ok('Perl::Critic::Policy', 'get_maximum_violations_per_document');
can_ok('Perl::Critic::Policy', 'get_parameters');
can_ok('Perl::Critic::Policy', 'get_raw_abstract');
can_ok('Perl::Critic::Policy', 'get_severity');
can_ok('Perl::Critic::Policy', 'get_short_name');
can_ok('Perl::Critic::Policy', 'get_themes');
can_ok('Perl::Critic::Policy', 'initialize_if_enabled');
can_ok('Perl::Critic::Policy', 'is_enabled');
can_ok('Perl::Critic::Policy', 'is_safe');
can_ok('Perl::Critic::Policy', 'new');
can_ok('Perl::Critic::Policy', 'new_parameter_value_exception');
can_ok('Perl::Critic::Policy', 'parameter_metadata_available');
can_ok('Perl::Critic::Policy', 'prepare_to_scan_document');
can_ok('Perl::Critic::Policy', 'set_format');
can_ok('Perl::Critic::Policy', 'set_maximum_violations_per_document');
can_ok('Perl::Critic::Policy', 'set_severity');
can_ok('Perl::Critic::Policy', 'set_themes');
can_ok('Perl::Critic::Policy', 'throw_parameter_value_exception');
can_ok('Perl::Critic::Policy', 'to_string');
can_ok('Perl::Critic::Policy', 'violates');
can_ok('Perl::Critic::Policy', 'violation');
can_ok('Perl::Critic::Policy', 'is_safe');

{
    my $policy = Perl::Critic::Policy->new();
    isa_ok($policy, 'Perl::Critic::Policy');
    is($policy->VERSION(), $version_string, 'Perl::Critic::Policy version');
}

#-----------------------------------------------------------------------------
# Test Perl::Critic::Violation module interface

use_ok('Perl::Critic::Violation') or BAIL_OUT(q<Can't continue.>);
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

use_ok('Perl::Critic::UserProfile') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::UserProfile', 'options_processor');
can_ok('Perl::Critic::UserProfile', 'new');
can_ok('Perl::Critic::UserProfile', 'policy_is_disabled');
can_ok('Perl::Critic::UserProfile', 'policy_is_enabled');

my $up = Perl::Critic::UserProfile->new();
isa_ok($up, 'Perl::Critic::UserProfile');
is($up->VERSION(), $version_string, 'Perl::Critic::UserProfile version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::PolicyFactory module interface

use_ok('Perl::Critic::PolicyFactory') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::PolicyFactory', 'create_policy');
can_ok('Perl::Critic::PolicyFactory', 'new');
can_ok('Perl::Critic::PolicyFactory', 'site_policy_names');


my $profile = Perl::Critic::UserProfile->new();
my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
isa_ok($factory, 'Perl::Critic::PolicyFactory');
is($factory->VERSION(), $version_string, 'Perl::Critic::PolicyFactory version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Theme module interface

use_ok('Perl::Critic::Theme') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::Theme', 'new');
can_ok('Perl::Critic::Theme', 'rule');
can_ok('Perl::Critic::Theme', 'policy_is_thematic');


my $theme = Perl::Critic::Theme->new( -rule => 'foo' );
isa_ok($theme, 'Perl::Critic::Theme');
is($theme->VERSION(), $version_string, 'Perl::Critic::Theme version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::PolicyListing module interface

use_ok('Perl::Critic::PolicyListing') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::PolicyListing', 'new');
can_ok('Perl::Critic::PolicyListing', 'to_string');

my $listing = Perl::Critic::PolicyListing->new();
isa_ok($listing, 'Perl::Critic::PolicyListing');
is($listing->VERSION(), $version_string, 'Perl::Critic::PolicyListing version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::ProfilePrototype module interface

use_ok('Perl::Critic::ProfilePrototype') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::ProfilePrototype', 'new');
can_ok('Perl::Critic::ProfilePrototype', 'to_string');

my $prototype = Perl::Critic::ProfilePrototype->new();
isa_ok($prototype, 'Perl::Critic::ProfilePrototype');
is($prototype->VERSION(), $version_string, 'Perl::Critic::ProfilePrototype version');

#-----------------------------------------------------------------------------
# Test Perl::Critic::Command module interface

use_ok('Perl::Critic::Command') or BAIL_OUT(q<Can't continue.>);
can_ok('Perl::Critic::Command', 'run');

#-----------------------------------------------------------------------------
# Test module interface for exceptions

{
    foreach my $class (
        map { "Perl::Critic::Exception::$_" } @concrete_exceptions
    ) {
        use_ok($class) or BAIL_OUT(q<Can't continue.>);
        can_ok($class, 'new');
        can_ok($class, 'throw');
        can_ok($class, 'message');
        can_ok($class, 'error');
        can_ok($class, 'full_message');
        can_ok($class, 'as_string');

        my $exception = $class->new();
        isa_ok($exception, $class);
        is($exception->VERSION(), $version_string, "$class version");
    }
}

#-----------------------------------------------------------------------------
# Test module interface for each Policy subclass

{
    for my $mod ( @bundled_policy_names ) {

        use_ok($mod) or BAIL_OUT(q<Can't continue.>);
        can_ok($mod, 'applies_to');
        can_ok($mod, 'default_severity');
        can_ok($mod, 'default_themes');
        can_ok($mod, 'get_severity');
        can_ok($mod, 'get_themes');
        can_ok($mod, 'is_enabled');
        can_ok($mod, 'new');
        can_ok($mod, 'set_severity');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'set_themes');
        can_ok($mod, 'violates');
        can_ok($mod, 'violation');
        can_ok($mod, 'is_safe');

        my $policy = $mod->new();
        isa_ok($policy, 'Perl::Critic::Policy');
        is($policy->VERSION(), $version_string, "Version of $mod");
        ok($policy->is_safe(), "CORE policy $mod is marked safe");
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

# ensure we return true if this test is loaded by
# t/00_modules.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
