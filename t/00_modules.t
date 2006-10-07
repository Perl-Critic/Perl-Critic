#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use PPI::Document;
use Test::More tests => 1145;  # Add 13 for each new policy created
use English qw(-no_match_vars);

our $VERSION = 0.20;
my $obj = undef;

#---------------------------------------------------------------
# Test Perl::Critic module interface

use_ok('Perl::Critic');
can_ok('Perl::Critic', 'new');
can_ok('Perl::Critic', 'critique');
can_ok('Perl::Critic', 'policies');
can_ok('Perl::Critic', 'add_policy');

#Set -profile to avoid messing with .perlcriticrc
$obj = Perl::Critic->new( -profile => 'NONE' );
isa_ok($obj, 'Perl::Critic');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------
# Test Perl::Critic::Config module interface

use_ok('Perl::Critic::Config');
can_ok('Perl::Critic::Config', 'new');
can_ok('Perl::Critic::Config', 'policies');
can_ok('Perl::Critic::Config', 'add_policy');
can_ok('Perl::Critic::Config', 'find_profile_path');
can_ok('Perl::Critic::Config', 'site_policies');
can_ok('Perl::Critic::Config', 'native_policies');

#Set -profile to avoid messing with .perlcriticrc
$obj = Perl::Critic::Config->new( -profile => 'NONE');
isa_ok($obj, 'Perl::Critic::Config');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------
# Test Perl::Critic::Config::Defaults module interface

use_ok('Perl::Critic::Config::Defaults');
can_ok('Perl::Critic::Config::Defaults', 'new');
can_ok('Perl::Critic::Config::Defaults', 'default_severity');
can_ok('Perl::Critic::Config::Defaults', 'default_include');
can_ok('Perl::Critic::Config::Defaults', 'default_exclude');
can_ok('Perl::Critic::Config::Defaults', 'default_themes');

$obj = Perl::Critic::Config::Defaults->new();
isa_ok($obj, 'Perl::Critic::Config::Defaults');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------
# Test Perl::Critic::Policy module interface

use_ok('Perl::Critic::Policy');
can_ok('Perl::Critic::Policy', 'new');
can_ok('Perl::Critic::Policy', 'violates');
can_ok('Perl::Critic::Policy', 'applies_to');
can_ok('Perl::Critic::Policy', 'default_severity');
can_ok('Perl::Critic::Policy', 'get_severity');
can_ok('Perl::Critic::Policy', 'set_severity');
can_ok('Perl::Critic::Policy', 'default_themes');
can_ok('Perl::Critic::Policy', 'get_themes');
can_ok('Perl::Critic::Policy', 'set_themes');
can_ok('Perl::Critic::Policy', 'add_themes');


$obj = Perl::Critic::Policy->new();
isa_ok($obj, 'Perl::Critic::Policy');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------
# Test Perl::Critic::Violation module interface

use_ok('Perl::Critic::Violation');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'source');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'to_string');

my $code = q{print 'Hello World';};
my $doc = PPI::Document->new(\$code);
$obj = Perl::Critic::Violation->new(undef, undef, $doc, undef);
isa_ok($obj, 'Perl::Critic::Violation');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------
# Test module interface for each Policy subclass

for my $mod ( Perl::Critic::Config::native_policies() ) {

    use_ok($mod);
    can_ok($mod, 'new');
    can_ok($mod, 'violates');
    can_ok($mod, 'applies_to');
    can_ok($mod, 'default_severity');
    can_ok($mod, 'get_severity');
    can_ok($mod, 'set_severity');
    can_ok($mod, 'default_themes');
    can_ok($mod, 'get_themes');
    can_ok($mod, 'set_themes');
    can_ok($mod, 'set_themes');

    $obj = $mod->new();
    isa_ok($obj, 'Perl::Critic::Policy');
    is($obj->VERSION(), $VERSION, "Version of $mod");
}

#---------------------------------------------------------------
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
