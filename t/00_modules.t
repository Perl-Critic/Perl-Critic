##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 344;
use English qw(-no_match_vars);

our $VERSION = '0.13';
$VERSION = eval $VERSION;  ## pc:skip

my $obj = undef;

#---------------------------------------------------------------

use_ok('Perl::Critic');
can_ok('Perl::Critic', 'new');
can_ok('Perl::Critic', 'critique');

#Set -profile to avoid messing with .perlcriticrc
$obj = Perl::Critic->new( -profile => 'NONE' );
isa_ok($obj, 'Perl::Critic');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------

use_ok('Perl::Critic::Config');
can_ok('Perl::Critic::Config', 'new');
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
can_ok('Perl::Critic::Policy', 'priority');

$obj = Perl::Critic::Policy->new();
isa_ok($obj, 'Perl::Critic::Policy');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------

use_ok('Perl::Critic::Violation');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'to_string');

$obj = Perl::Critic::Violation->new(undef, undef, []);
isa_ok($obj, 'Perl::Critic::Violation');
is($obj->VERSION(), $VERSION);

#---------------------------------------------------------------

for my $mod ( Perl::Critic::Config::native_policies() ) {

    use_ok($mod);
    can_ok($mod, 'new');
    can_ok($mod, 'violates');
    can_ok($mod, 'applies_to');
    can_ok($mod, 'priority');

    $obj = $mod->new();
    isa_ok($obj, 'Perl::Critic::Policy');
    is($obj->VERSION(), $VERSION, "Version of $mod");
}

