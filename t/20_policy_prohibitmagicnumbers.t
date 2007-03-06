#!perl

use strict;
use warnings;
use Test::More tests => 110;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

# The variables in this test suite have been brought to you by the
# wonders of Acme::Metasyntactic, in the guise of the currently
# unreleased Nethack theme.

my $policy = 'ValuesAndExpressions::ProhibitMagicNumbers';
my $code;

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use 5.8.1;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: version numbers allowed in use statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
require 5.8.1;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: version numbers allowed in require statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Aleax = 5.8.1;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: version numbers not allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use Test::More plan => 57;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: all numbers are allowed on any use statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$tangle_tree = 0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal zero is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xiron_golem = 0.0
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: floating-point zero is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal one is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: floating-point one is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$gold_golem = 2;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal two is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$lich = 2.0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: floating-point two is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$soldier = 2.5;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: fractional numbers not allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$giant_pigmy = -1;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: negative one is not allowed by default"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$frobnication_factor = 42;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: the answer to life, the universe, and everything is not allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use constant FROBNICATION_FACTOR => 42;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: the answer to life, the universe, and everything is allowed as a constant"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use constant FROBNICATION_FACTOR => 1_234.567_89;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: fractional numbers are allowed as a constant"
);

#----------------------------------------------------------------

# TEST
# "5" is a magic number...
$code = <<'END_PERL';
foreach my $solid (1..5) {
    frobnicate($solid);
}
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: magic numbers not allowed in ranges"
);

#----------------------------------------------------------------

# TEST
# ... until it's given a name describing its significance.
$code = <<'END_PERL';
use Readonly;

Readonly my $REGULAR_GEOMETRIC_SOLIDS => 5;

foreach my $solid (1..$REGULAR_GEOMETRIC_SOLIDS) {
    frobnicate($solid);
}
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly numbers allowed in ranges"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$battlemech = 0b0;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: binary zero isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $giant_eel => 0b0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly binary zero is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xeroc = 0b1;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: binary one isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $creeping_coins => 0b1;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly binary one is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$basilisk = 000;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: octal zero isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $dwarf_lord => 000;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly octal zero is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$brown_mold = 001;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: octal one isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $kobold_zombie => 001;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly octal one is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$yeti = 0x00;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: hexadecimal zero isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $newt => 0x00;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly hexadecimal zero is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$piranha = 0x01;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: hexadecimal one isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $Lord_Surtur => 0x01;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly hexadecimal one is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Green_elf = 0e0;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: exponential zero isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $sasquatch => 0e0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly exponential zero is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Uruk_hai = 1e0;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: exponential one isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $leather_golem => 1e0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly exponential one is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use Some::Module [ 1, 2, 3, 4 ];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in array references in use statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
require Some::Other::Module [ 1, 2, 3, 4 ];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in array references in require statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $Totoro => [ 1, 2, 3, 4 ];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in array references in readonly statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Evil_Iggy = [ 1, 2, 3, 4 ];
END_PERL

is(
    pcritique($policy, \$code),
    2,
    "$policy: magic numbers not allowed in array references in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$titanothere = [ 1, 0, 1, 0 ];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: array references containing only good numbers are allowed (by this policy)"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use Some::Module { 1 => 2, 3 => 4 };
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in hash references in use statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
require Some::Other::Module { 1 => 2, 3 => 4 };
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in hash references in require statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $Vlad_the_Impaler => { 1 => 2, 3 => 4 };
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in hash references in readonly statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$gnome_lord = { 1 => 2, 3 => 4 };
END_PERL

is(
    pcritique($policy, \$code),
    2,
    "$policy: magic numbers not allowed in hash references in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$aardvark = { 1 => 0, 0 => 1 };
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: hash references containing only good numbers are allowed (by this policy)"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use Some::Module ( 1, 2, 3, 4 );
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in lists in use statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
require Some::Other::Module ( 1, 2, 3, 4 );
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in lists in require statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly @elf_mummy => ( 1, 2, 3, 4 );
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: any numbers allowed in lists in readonly statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@kitten = ( 1, 2, 3, 4 );
END_PERL

is(
    pcritique($policy, \$code),
    2,
    "$policy: magic numbers not allowed in lists in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@purple_worm = ( 1, 0, 1, 0 );
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: lists containing only good numbers are allowed (by this policy)"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@quivering_blob = ( 1, ( 2, 3, 4 ) );
END_PERL

is(
    pcritique($policy, \$code),
    2,
    "$policy: magic numbers not allowed in nested lists in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@green_slime = ( 1, [ 2, 3, 4 ] );
END_PERL

is(
    pcritique($policy, \$code),
    2,
    "$policy: magic numbers not allowed in nested array references in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@fire_elemental = ( 1, { 2 => 4 } );
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: magic numbers not allowed in nested hash references in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@Y2K_bug = ( 1, { 0 => 1 } );
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: good numbers allowed in nested hash references anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@fog_cloud = [ 1, { 0 => { 1 => [ 1, 1, [ \382 ] ] } } ];
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: magic numbers not allowed in deep datastructures in regular statement"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
@fog_cloud = [ 1, { 0 => { 1 => [ 1, 1, [ 1 ] ] } } ];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: good numbers allowed in deep datastructures anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
our $VERSION = 0.21;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: \$VERSION variables get a special exemption"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Invid = $nalfeshnee[-1];
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: last element of an array gets a special exemption"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$warhorse = $Cerberus[-1 * 1];
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: last element exemption does not work if there is anything else within the subscript"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$scorpion = $shadow[-2];
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: penultimate element of an array does not get a special exemption"
);

#----------------------------------------------------------------


#----------------------------------------------------------------
my %config;

# TEST
$code = <<'END_PERL';
use 5.8.1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: code that passes without configuration should pass with empty configuration"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: code that passes without configuration should pass with empty configuration"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: code that passes without configuration should pass with empty configuration"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$soldier = 2.5;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: code that doesn't pass without configuration should also not pass with empty configuration"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$frobnication_factor = 42;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: code that doesn't pass without configuration should also not pass with empty configuration"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
use constant FROBNICATION_FACTOR => 42;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: code that passes without configuration should pass with empty configuration"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '' );

# TEST
$code = <<'END_PERL';
$tangle_tree = 0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal zero is allowed even if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xiron_golem = 0.0
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point zero is allowed even if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal one is allowed even if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point one is allowed even if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$gold_golem = 2;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: decimal two is not allowed if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$lich = 2.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: floating-point two is not allowed if the configuration specifies that there aren't any allowed literals"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '3 -5' );

# TEST
$code = <<'END_PERL';
$tangle_tree = 0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal zero is allowed even if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xiron_golem = 0.0
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point zero is allowed even if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal one is allowed even if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point one is allowed even if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$gold_golem = 2;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: decimal two is not allowed if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$lich = 2.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: floating-point two is not allowed if the configuration doesn't include it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$ghoul = 3;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal three is allowed if the configuration includes it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$water_elemental = 3.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point three is allowed if the configuration includes it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$glass_piercer = -5;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal negative five is allowed if the configuration includes it in the allowed literals"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$clay_golem = -5.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point negative five is allowed if the configuration includes it in the allowed literals"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => '' );

# TEST
$code = <<'END_PERL';
$tangle_tree = 0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal zero is allowed even if the configuration specifies that there aren't any allowed types"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xiron_golem = 0.0
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: floating-point zero is not allowed if the configuration specifies that there aren't any allowed types"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal one is allowed even if the configuration specifies that there aren't any allowed types"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    1,
    "$policy: floating-point one is not allowed if the configuration specifies that there aren't any allowed types"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => 'Float' );

# TEST
$code = <<'END_PERL';
$tangle_tree = 0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: decimal zero is allowed if the configuration specifies that there are any allowed types"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xiron_golem = 0.0
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point zero is allowed if the configuration specifies that the Float type is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$killer_tomato = 1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: decimal one is allowed if the configuration specifies that there are any allowed types"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$witch_doctor = 1.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: floating-point one is allowed if the configuration specifies that the Float type is allowed"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => 'Binary' );

# TEST
$code = <<'END_PERL';
$battlemech = 0b0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: binary zero is allowed if the configuration specifies that the Binary type is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$xeroc = 0b1;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: binary one is allowed if the configuration specifies that the Binary type is allowed"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => 'Exp' );

# TEST
$code = <<'END_PERL';
$Green_elf = 0e0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: exponential zero is allowed if the configuration specifies that the Exp type is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Uruk_hai = 1e0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: exponential one is allowed if the configuration specifies that the Exp type is allowed"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => 'Hex' );

# TEST
$code = <<'END_PERL';
$yeti = 0x00;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: hexadecimal zero is allowed if the configuration specifies that the Hex type is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$piranha = 0x01;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: hexadecimal one is allowed if the configuration specifies that the Hex type is allowed"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_types => 'Octal' );

# TEST
$code = <<'END_PERL';
$basilisk = 000;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: octal zero is allowed if the configuration specifies that the Octal type is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$brown_mold = 001;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: octal one is allowed if the configuration specifies that the Octal type is allowed"
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => 'all_integers' );

# TEST
$code = <<'END_PERL';
$brogmoid = 356_634_627;
$rat_ant  =     -29_422;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: any integer value should pass if the allowed values contains 'all_integers'."
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$human = 102_938.0;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: any floating-point value without a fractional portion should pass if the allowed values contains 'all_integers'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => 'all_integers 429.73902' );

# TEST
$code = <<'END_PERL';
$Norn = 429.73902;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: a non-integral value should pass if the allowed values contains it and 'all_integers'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => 'all_integers', allowed_types => 'Binary' );

# TEST
$code = <<'END_PERL';
$baby_blue_dragon = 0b01100101_01101010_01110011;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: any binary value should pass if the allowed values contains 'all_integers' and allowed types includes 'Binary'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => 'all_integers', allowed_types => 'Hex' );

# TEST
$code = <<'END_PERL';
$killer_bee = 0x656a73;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: any hexadecimal value should pass if the allowed values contains 'all_integers' and allowed types includes 'Hex'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => 'all_integers', allowed_types => 'Octal' );

# TEST
$code = <<'END_PERL';
$ettin_mummy = 0145_152_163;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: any octal value should pass if the allowed values contains 'all_integers' and allowed types includes 'Octal'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '3..5' );

# TEST
$code = <<'END_PERL';
$guide = 0;
$cuatl = 1;
$Master_Assassin = 3;
$orc = 4;
$trapper = 5;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: zero, one, three, four, and five decimal values should pass if the allowed values contains the '3..5' range."
);

#----------------------------------------------------------------

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Elvenking = -1;
$brown_pudding = 2;
$archeologist = 6;
$nurse = 4.5;
END_PERL

is(
    pcritique($policy, \$code, \%config),
    4,
    "$policy: negative one, two, and six decimal values and fractional values should not pass if the allowed values contains the '3..5' range."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '-1.5..3.5:by(0.5)' );

# TEST
$code = <<'END_PERL';
$owlbear = [ -1.5, -1, -.5, 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5 ];
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: -3/2, -2/2, -1/2 ... 7/5 should pass if the allowed values contains the '-1.5..3.5:by(0.5)' range."
);

#----------------------------------------------------------------

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$lurker_above = [ -2, 4 ];
END_PERL

is(
    pcritique($policy, \$code, \%config),
    2,
    "$policy: negative two and four should not pass if the allowed values contains the '-1.5..3.5:by(0.5)' range."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '-1.5..3.5' );

# TEST
$code = <<'END_PERL';
$long_worm = [ -1.5, -.5, 0, 0.5, 1, 1.5, 2.5, 3.5 ];
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: -3/2, -1/2, 1/2 ... 7/5, plus 0 and 1 should pass if the allowed values contains the '-1.5..3.5' range."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '-1.5..3.5 all_integers' );

# TEST
$code = <<'END_PERL';
$ice_devil = [ -1.5, -1, -.5, 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5 ];
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: -3/2, -2/2, -1/2 ... 7/5 should pass if the allowed values contains the '-1.5..3.5' range and 'all_integers'."
);

#----------------------------------------------------------------

#----------------------------------------------------------------
%config = ( allowed_values => '-5..-2 21..24' );

# TEST
$code = <<'END_PERL';
$newt = [ -5, -4, -3, -2, 0, 1, 21, 22, 23, 24 ];
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: -5, -4, -3, -2, 0, 1, 21, 22, 23, and 24 should pass if the allowed values contains the '-5..-2' and '21..24 ranges."
);

#----------------------------------------------------------------

#----------------------------------------------------------------

%config = ();

# TEST
$code = <<'END_PERL';
(our $VERSION = q$Revision$) =~ s/Revision //;
(our $VERSION) = '$Revision$' =~ /([\d.]+)/;
(our $VERSION) = sprintf "%d", q$Revision$ =~ /Revision:\s+(\S+)/;
our $VERSION : unique = "1.23";
our $VERSION : unique = '1.23';
our $VERSION = "$local_variable v1.23";
our $VERSION = "1." . sprintf "%d", q$Revision$ =~ /: (\d+)/;
our $VERSION = "1.2.3";
our $VERSION = "1.2.3.0";
our $VERSION = "1.2.3.blah";
our $VERSION = "1.23 (liblgrp version $local_variable)";
our $VERSION = "1.23 2005-05-20";
our $VERSION = "1.23";
our $VERSION = "1.23, 2004-12-07";
our $VERSION = "1.23_blah";
our $VERSION = "1.23blah";
our $VERSION = "1.2_3";
our $VERSION = "123";
our $VERSION = "INSERT";
our $VERSION = $SomeOtherModule::VERSION;
our $VERSION = $VERSION = (qw($Revision$))[1];
our $VERSION = $local_variable;
our $VERSION = '$Date$'; $VERSION =~ s|^\$Date:\s*([0-9]{4})/([0-9]{2})/([0-9]{2})\s.*|\1.\2.\3| ;
our $VERSION = '$Revision$' =~ /\$Revision:\s+([^\s]+)/;
our $VERSION = '$Revision$';
our $VERSION = '-123 blah';
our $VERSION = '1.' . qw $Revision$[1];
our $VERSION = '1.' . sprintf "%d", (qw($Revision$))[1];
our $VERSION = '1.' . sprintf("%d", (qw($Revision$))[1]);
our $VERSION = '1.2.3';
our $VERSION = '1.2.3.0';
our $VERSION = '1.2.3blah';
our $VERSION = '1.23';
our $VERSION = '1.23_blah';
our $VERSION = '1.23blah';
our $VERSION = '1.2_3';
our $VERSION = '1.23' || do { q $Revision$ =~ /(\d+)/; sprintf "%4.2f", $1 / 100 };
our $VERSION = '123';
our $VERSION = ('$Revision$' =~ /(\d+.\d+)/)[ 0];
our $VERSION = ('$Revision$' =~ /(\d+\.\d+)/);
our $VERSION = ('$Revision$' =~ m/(\d+)/)[0];
our $VERSION = ((require SomeOtherModule), $SomeOtherModule::VERSION)[1];
our $VERSION = (q$Revision$ =~ /([\d\.]+)/);
our $VERSION = (q$Revision$ =~ /(\d+)/g)[0];
our $VERSION = (qq$Revision$ =~ /(\d+)/)[0];
our $VERSION = (qw$Revision$)[-1];
our $VERSION = (qw$Revision$)[1];
our $VERSION = (qw($Revision$))[1];
our $VERSION = (split(/ /, '$Revision$'))[1];
our $VERSION = (split(/ /, '$Revision$'))[2];
our $VERSION = 1.2.3;
our $VERSION = 1.23;
our $VERSION = 1.2_3;
our $VERSION = 123;
our $VERSION = SomeOtherModule::RCSVersion('$Revision$');
our $VERSION = SomeOtherModule::VERSION;
our $VERSION = [ qw{ $Revision$ } ]->[1];
our $VERSION = do { (my $v = q%version: 1.23 %) =~ s/.*://; sprintf("%d.%d", split(/\./, $v), 0) };
our $VERSION = do { (my $v = q%version: 123 %) =~ s/.*://; sprintf("%d.%d", split(/\./, $v), 0) };
our $VERSION = do { q $Revision$ =~ /(\d+)/; sprintf "%4.2f", $1 / 100 };
our $VERSION = do { q$Revision$ =~ /Revision: (\d+)/; sprintf "1.%d", $1; };
our $VERSION = do { require mod_perl2; $mod_perl2::VERSION };
our $VERSION = do {(q$URL$=~ m$.*/(?:tags|branches)/([^/ \t]+)$)[0] || "0.0"};
our $VERSION = eval { require version; version::qv((qw$Revision$)[1] / 1000) };
our $VERSION = q$0.04$;
our $VERSION = q$Revision$;
our $VERSION = q(0.14);
our $VERSION = qv('1.2.3');
our $VERSION = qw(1.2.3);
our $VERSION = sprintf "%.02f", $local_variable/100 + 0.3;
our $VERSION = sprintf "%.3f", 123 + substr(q$Revision$, 4)/1000;
our $VERSION = sprintf "%d.%d", '$Revision$' =~ /(\d+)\.(\d+)/;
our $VERSION = sprintf "%d.%d", '$Revision$' =~ /(\d+)/g;
our $VERSION = sprintf "%d.%d", '$Revision$' =~ /(\d+)\.(\d+)/;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ /: (\d+)\.(\d+)/;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ /(\d+)/g;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ /(\d+)\.(\d+)/;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ /(\d+)\.(\d+)/g;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ /: (\d+)\.(\d+)/;
our $VERSION = sprintf "%d.%d", q$Revision$ =~ m/ (\d+) \. (\d+) /xg;
our $VERSION = sprintf "%d.%d", q$Revision$ ~~ m:P5:g/(\d+)/;
our $VERSION = sprintf "%d.%d%d", (split /\D+/, '$Name: beta0_1_1 $')[1..3];
our $VERSION = sprintf "%s.%s%s", q$Name: Rel-0_90 $ =~ /^Name: Rel-(\d+)_(\d+)(_\d+|)\s*$/, 999, "00", join "", (gmtime)[5] +1900, map {sprintf "%d", $_} (gmtime)[4]+1;
our $VERSION = sprintf "1.%d", '$Revision$' =~ /(\d+)/;
our $VERSION = sprintf "1.%d", q$Revision$ =~ /(\d+)/g;
our $VERSION = sprintf '%d.%d', (q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf '%d.%d', q$Revision$ =~ /(\d+)\.(\d+)/;
our $VERSION = sprintf '%d.%d', q$Revision$ =~ /(\d+)\.(\d+)/;
our $VERSION = sprintf '%s', 'q$Revision$' =~ /\S+\s+(\S+)\s+/ ;
our $VERSION = sprintf '%s', 'q$Revision$' =~ /\S+\s+(\S+)\s+/ ;
our $VERSION = sprintf '%s', q$Revision$ =~ /Revision:\s+(\S+)\s+/ ;
our $VERSION = sprintf '%s', q{$Revision$} =~ /\S+\s+(\S+)/ ;
our $VERSION = sprintf '1.%d', (q$Revision$ =~ /\D(\d+)\s*$/)[0] + 15;
our $VERSION = sprintf("%d", q$Id: SomeModule.pm,v 1.23 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);
our $VERSION = sprintf("%d", q$Id: SomeModule.pm,v 1.23 2006/04/10 22:39:39 matthew Exp $ =~ /\s(\d+)\s/);
our $VERSION = sprintf("%d.%d", "Revision: 2006.0626" =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d", '$Name: v0_018-2006-06-15b $' =~ /(\d+)_(\d+)/, 0, 0);
our $VERSION = sprintf("%d.%d", 0, q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d", q$Name: REL-0-13 $ =~ /(\d+)-(\d+)/, 999, 99);
our $VERSION = sprintf("%d.%d", q$Name: ical-parser-html-1-6 $ =~ /(\d+)-(\d+)/);
our $VERSION = sprintf("%d.%d", q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d", q$Revision$ =~ /(\d+)\.(\d+)/o);
our $VERSION = sprintf("%d.%d", q$Revision$ =~ m/(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d", q$Revision$=~/(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d", q'$Revision$' =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf("%d.%d.%d", 0, q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf("1.%d", q$Revision$ =~ / (\d+) /);
our $VERSION = sprintf("1.%d", q$Revision$ =~ /(\d+)/);
our $VERSION = sprintf("1.2%d%d", q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf('%d.%d', '$Revision$' =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf('%d.%d', q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = sprintf('%d.%d', q$Revision$ =~ /(\d+)\.(\d+)/);
our $VERSION = substr q$Revision$, 10;
our $VERSION = substr(q$Revision$, 10);
our $VERSION = v1.2.3.0;
our $VERSION = v1.2.3;
our $VERSION = v1.23;
our $VERSION = version->new('1.2.3');
our $VERSION = version->new(qw$Revision$);
our ($PACKAGE, $VERSION) = ('') x 2;
our ($VERSION) = "1.23";
our ($VERSION) = $SomeOtherModule::VERSION;
our ($VERSION) = '$Revision$' =~ /\$Revision:\s+([^\s]+)/;
our ($VERSION) = '$Revision$' =~ /\$Revision:\s+([^\s]+)/;
our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;
our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }xm;
our ($VERSION) = '$Revision$'=~/(\d+(\.\d+))/;
our ($VERSION) = '$Revision$' =~ m{ \$Revision: \s+ (\S+) }x;
our ($VERSION) = '1.23' =~ /([.,\d]+)/;
our ($VERSION) = '1.23';
our ($VERSION) = ($local_variable =~ /(\d+\.\d+)/);
our ($VERSION) = ('$Revision$' =~ /(\d+\.\d+)/) ;
our ($VERSION) = ('$Revision$' =~ /(\d+\.\d+)/);
our ($VERSION) = ('$Revision$' =~ m/([\.\d]+)/) ;
our ($VERSION) = (q$Revision$ =~ /([\d\.]+)/);
our ($VERSION) = (qq$Revision$ =~ /(\d+)/)[0];
our ($VERSION) = 1.23;
our ($VERSION) = q$Revision$ =~ /Revision:\s+(\S+)/ or $VERSION = "1.23";
our ($VERSION) = q$Revision$ =~ /Revision:\s+(\S+)/ or $VERSION = '1.23';
our ($VERSION) = q$Revision$ =~ /[\d.]+/g;
our ($VERSION) = q$Revision$ =~ /^Revision:\s+(\S+)/ or $VERSION = "1.23";
require SomeOtherModule; our $VERSION = $SomeOtherModule::VERSION;
use SomeOtherModule; our $VERSION = $SomeOtherModule::VERSION;
use SomeOtherModule; our $VERSION = SomeOtherModule::VERSION;
use base 'SomeOtherModule'; our $VERSION = $SomeOtherModule::VERSION;
use version; our $VERSION = 1.23;
use version; our $VERSION = qv("1.2.3");
use version; our $VERSION = qv('1.2.3');
use version; our $VERSION = qv('1.23');
use version; our $VERSION = qv((qw$Revision$)[1] / 1000);
use version; our $VERSION = version->new('1.23');
END_PERL

is(
    pcritique($policy, \$code, \%config),
    0,
    "$policy: should pass mini-CPAN accumulated \$VERSION declarations."
);

#----------------------------------------------------------------
