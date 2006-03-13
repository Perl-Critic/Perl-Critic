##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use PPI::Document;
use Test::More tests => 629;  # Add 9 for each new policy created
use English qw(-no_match_vars);

our $VERSION = '0.14_02';
$VERSION = eval $VERSION;  ## no critic

my $obj = undef;

#---------------------------------------------------------------

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

use_ok('Perl::Critic::Policy');
can_ok('Perl::Critic::Policy', 'new');
can_ok('Perl::Critic::Policy', 'violates');
can_ok('Perl::Critic::Policy', 'applies_to');
can_ok('Perl::Critic::Policy', 'default_severity');
can_ok('Perl::Critic::Policy', 'get_severity');
can_ok('Perl::Critic::Policy', 'set_severity');

$obj = Perl::Critic::Policy->new();
isa_ok($obj, 'Perl::Critic::Policy');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------

use_ok('Perl::Critic::Violation');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'source');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'to_string');

my $code = 'Hello World;';
my $doc = PPI::Document->new(\$code);
$obj = Perl::Critic::Violation->new(undef, undef, $doc, undef);
isa_ok($obj, 'Perl::Critic::Violation');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------

for my $mod ( Perl::Critic::Config::native_policies() ) {

    use_ok($mod);
    can_ok($mod, 'new');
    can_ok($mod, 'violates');
    can_ok($mod, 'applies_to');
    can_ok($mod, 'default_severity');
    can_ok($mod, 'get_severity');
    can_ok($mod, 'set_severity');

    $obj = $mod->new();
    isa_ok($obj, 'Perl::Critic::Policy');
    is($obj->VERSION(), $VERSION, "Version of $mod");
}

