#!perl

use strict;
use warnings;
use Test::More tests => 52;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

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
    "$policy: floating-point 0 is allowed anywhere"
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
$Green_elf = 0e1;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: exponential zero isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $sasquatch => 0e1;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: readonly exponential zero is allowed"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Orion = 0e0;
END_PERL

is(
    pcritique($policy, \$code),
    0,
    "$policy: special 0e0 is allowed anywhere"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
$Uruk_hai = 1e1;
END_PERL

is(
    pcritique($policy, \$code),
    1,
    "$policy: exponential one isn't allowed in regular statements"
);

#----------------------------------------------------------------

# TEST
$code = <<'END_PERL';
Readonly $leather_golem => 1e1;
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
