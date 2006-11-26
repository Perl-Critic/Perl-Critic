##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 24;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

# These are proxies for a compile test
can_ok('Perl::Critic::Policy::Variables::ProtectPrivateVars', 'violates');
can_ok('Perl::Critic::Policy::Variables::ProhibitConditionalDeclarations', 'violates');
can_ok('Perl::Critic::Policy::Variables::RequireInitializationForLocalVars', 'violates');
can_ok('Perl::Critic::Policy::Variables::RequireLexicalLoopIterators', 'violates');
can_ok('Perl::Critic::Policy::Variables::RequireNegativeIndices', 'violates');





$code = <<'END_PERL';
$Other::Package::_foo;
@Other::Package::_bar;
%Other::Package::_baz;
&Other::Package::_quux;
*Other::Package::_xyzzy;
\$Other::Package::_foo;
END_PERL

$policy = 'Variables::ProtectPrivateVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$_foo;
@_bar;
%_baz;
&_quux;
\$_foo;
$::_foo;
END_PERL

$policy = 'Variables::ProtectPrivateVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 if $bar;
local $foo = 1 if $bar;
our $foo = 1 if $bar;

my ($foo, $baz) = @list if $bar;
local ($foo, $baz) = @list if $bar;
our ($foo, $baz) = 1 if $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 unless $bar;
local $foo = 1 unless $bar;
our $foo = 1 unless $bar;

my ($foo, $baz) = @list unless $bar;
local ($foo, $baz) = @list unless $bar;
our ($foo, $baz) = 1 unless $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 while $bar;
local $foo = 1 while $bar;
our $foo = 1 while $bar;

my ($foo, $baz) = @list while $bar;
local ($foo, $baz) = @list while $bar;
our ($foo, $baz) = 1 while $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 for @bar;
local $foo = 1 for @bar;
our $foo = 1 for @bar;

my ($foo, $baz) = @list for @bar;
local ($foo, $baz) = @list for @bar;
our ($foo, $baz) = 1 for @bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 foreach @bar;
local $foo = 1 foreach @bar;
our $foo = 1 foreach @bar;

my ($foo, $baz) = @list foreach @bar;
local ($foo, $baz) = @list foreach @bar;
our ($foo, $baz) = 1 foreach @bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo (@list) { do_something() }
foreach my $foo (@list) { do_something() }
while (my $foo $condition) { do_something() }
until (my $foo = $condition) { do_something() }
unless (my $foo = $condition) { do_something() }

# these are terrible uses of "if" but do not violate the policy
my $foo = $hash{if};
my $foo = $obj->if();
END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

local $foo;
local ($foo, $bar);

local $|;
local ($|, $$);

local $OUTPUT_RECORD_SEPARATOR;
local ($OUTPUT_RECORD_SEPARATOR, $PROGRAM_NAME);

END_PERL

$policy = 'Variables::RequireInitializationForLocalVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

local $foo = 'foo';
local ($foo, $bar) = 'foo';       #Not right, but still passes
local ($foo, $bar) = qw(foo bar);

my $foo;
my ($foo, $bar);
our $bar
our ($foo, $bar);

END_PERL

$policy = 'Variables::RequireInitializationForLocalVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

$x->{local};

END_PERL

TODO: {
  local $TODO = "PPI bug prevents this from working";

  $policy = 'Variables::RequireInitializationForLocalVars';
  is( pcritique($policy, \$code), 0, $policy);
}

#----------------------------------------------------------------

$code = <<'END_PERL';
for $foo ( @list ) {}
foreach $foo ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 2, $policy.'non-lexical iterator' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo ( @list ) {}
foreach my $foo ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'lexical iterators' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for ( @list ) {}
foreach ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'$_ iterator' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for ( $i=0; $i<10; $i++ ) {}
while ( $condition ) {}
until ( $condition ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'Other compounds' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr[-1];
$arr[ -2 ];
$arr[$m-$n];
$arr[@foo-1];
$arr[$#foo-1];
$arr[@$arr-1];
$arr[$#$arr-1];
1+$arr[$#{$arr}-1];
$arr->[-1];
$arr->[ -2 ];
3+$arr->[@foo-1 ];
$arr->[@arr-1 ];
$arr->[ $#foo - 2 ];
$$arr[-1];
$$arr[ -2 ];
$$arr[@foo-1 ];
$$arr[@arr-1 ];
$$arr[ $#foo - 2 ];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr[$#arr];
$arr[$#arr-1];
$arr[ $#arr - 2 ];
$arr[@arr-1];
$arr[@arr - 2];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 5, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr_ref->[$#{$arr_ref}-1];
$arr_ref->[$#$arr_ref-1];
$arr_ref->[@{$arr_ref}-1];
$arr_ref->[@$arr_ref-1];
$$arr_ref[$#{$arr_ref}-1];
$$arr_ref[$#$arr_ref-1];
$$arr_ref[@{$arr_ref}-1];
$$arr_ref[@$arr_ref-1];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 8, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
# These ones are too hard to detect for now; FIXME??
$some->{complicated}->[$data_structure]->[$#{$some->{complicated}->[$data_structure]} -1];
my $ref = $some->{complicated}->[$data_structure];
$some->{complicated}->[$data_structure]->[$#{$ref} -1];
$ref->[$#{$some->{complicated}->[$data_structure]} -1];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 0, $policy.', fixme' );

#----------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab :
