##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 30;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
substr( $foo, 2, 1 ) = 'XYZ';
END_PERL

$policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
is( pcritique($policy, \$code), 1, 'lvalue' );

#----------------------------------------------------------------

$code = <<'END_PERL';
substr $foo, 2, 1, 'XYZ';
END_PERL

$policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
isnt( pcritique($policy, \$code), 1, '4 arg substr' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$bar = substr( $foo, 2, 1 );
END_PERL

$policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
isnt( pcritique($policy, \$code), 1, 'rvalue' );

#----------------------------------------------------------------

$code = <<'END_PERL';
%bar = (
    'foobar'    => substr( $foo, 2, 1 ),
    );
END_PERL

$policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
isnt( pcritique($policy, \$code), 1, 'hash rvalue' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, 0.25 );
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, 'sleep, as list' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, $time );
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, 'sleep, as list w/var' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, undef, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, 'sleep, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select $vec, undef, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
isnt( pcritique($policy, \$code), 1, 'select on read' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, $vec, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
isnt( pcritique($policy, \$code), 1, 'select on write' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, undef, $vec, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
isnt( pcritique($policy, \$code), 1, 'select on error' );

#----------------------------------------------------------------

$code = <<'END_PERL';
eval "$some_code";
END_PERL

$policy = 'BuiltinFunctions::ProhibitStringyEval';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
eval { some_code() };
eval( {some_code() } );
eval();
END_PERL

$policy = 'BuiltinFunctions::ProhibitStringyEval';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$hash1{eval} = 1;
%hash2 = (eval => 1);
END_PERL

$policy = 'BuiltinFunctions::ProhibitStringyEval';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
grep $_ eq 'foo', @list;
@matches = grep $_ eq 'foo', @list;
END_PERL

$policy = 'BuiltinFunctions::RequireBlockGrep';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
grep {$_ eq 'foo'}  @list;
@matches = grep {$_ eq 'foo'}  @list;
grep( {$_ eq 'foo'}  @list );
@matches = grep( {$_ eq 'foo'}  @list )
grep();
@matches = grep();
END_PERL

$policy = 'BuiltinFunctions::RequireBlockGrep';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$hash1{grep} = 1;
%hash2 = (grep => 1);
END_PERL

$policy = 'BuiltinFunctions::RequireBlockGrep';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
map $_++, @list;
@foo = map $_++, @list;
END_PERL

$policy = 'BuiltinFunctions::RequireBlockMap';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
map {$_++}   @list;
@foo = map {$_++}   @list;
map( {$_++}   @list );
@foo = map( {$_++}   @list );
map();
@foo = map();
END_PERL

$policy = 'BuiltinFunctions::RequireBlockMap';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$hash1{map} = 1;
%hash2 = (map => 1);
END_PERL

$policy = 'BuiltinFunctions::RequireBlockMap';
is( pcritique($policy, \$code), 0, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
@files = <*.pl>;
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 1, 'glob via <...>' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
foreach my $file (<*.pl>) {
    print $file;
}
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 1, 'glob via <...> in foreach' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
@files = (<*.pl>, <*.pm>);
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 1, 'multiple globs via <...>' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
while (<$fh>) {
    print $_;
}
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
isnt( pcritique($policy, \$code), 1, 'I/O' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
isa($foo, $pkg);
UNIVERSAL::isa($foo, $pkg);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalIsa';
is( pcritique($policy, \$code), 2, 'UNIVERSAL::isa' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use UNIVERSAL::isa;
require UNIVERSAL::isa;
$foo->isa($pkg);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalIsa';
is( pcritique($policy, \$code), 0, 'UNIVERSAL::isa' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
can($foo, $funcname);
UNIVERSAL::can($foo, $funcname);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalCan';
is( pcritique($policy, \$code), 2, 'UNIVERSAL::can' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use UNIVERSAL::can;
require UNIVERSAL::can;
$foo->can($funcname);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalCan';
is( pcritique($policy, \$code), 0, 'UNIVERSAL::can' );

#----------------------------------------------------------------

$code = <<'END_PERL';
sort {my $aa = $foo{$a};my $b = $foo{$b};$a cmp $b} @list;
END_PERL

$policy = 'BuiltinFunctions::RequireSimpleSortBlock';
is( pcritique($policy, \$code), 1, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
sort @list;
sort {$a cmp $b;} @list;
sort {$a->[0] <=> $b->[0] && $a->[1] <=> $b->[1]} @list;
sort {bar($a,$b)} @list;
END_PERL

$policy = 'BuiltinFunctions::RequireSimpleSortBlock';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------
# These are things I found in my Perl that caused some false-
# positives because they have some extra whitespace in the block.

$code = <<'END_PERL';
sort { $a->[2] cmp $b->[2] } @dl;
sort { $a->[0] <=> $b->[0] } @failed;
sort{ $isopen{$a}->[0] <=> $isopen{$b}->[0] } @list;
sort { -M $b <=> -M $a} @entries;
END_PERL

$policy = 'BuiltinFunctions::RequireSimpleSortBlock';
is( pcritique($policy, \$code), 0, $policy );
