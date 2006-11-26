#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 40;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;


#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, 0.25 );
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, $policy.' sleep, as list' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, $time );
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, $policy.' sleep, as list w/var' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, undef, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 1, $policy.' sleep, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select $vec, undef, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 0, $policy.' select on read' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, $vec, undef, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 0, $policy.' select on write' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select undef, undef, $vec, 0.25;
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 0, $policy.' select on error' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo{select};
END_PERL

$policy = 'BuiltinFunctions::ProhibitSleepViaSelect';
is( pcritique($policy, \$code), 0, $policy.' select as word' );

#----------------------------------------------------------------

$code = <<'END_PERL';
eval "$some_code";
eval( "$some_code" );
eval( 'sub {'.$some_code.'}' );
END_PERL

$policy = 'BuiltinFunctions::ProhibitStringyEval';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
eval { some_code() };
eval( {some_code() } );
eval();
{eval}; # for Devel::Cover
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
{grep}; # for Devel::Cover
grelp $_ eq 'foo', @list; # deliberately misspell grep
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
{map}; # for Devel::Cover
malp $_++, @list; # deliberately misspell map
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
is( pcritique($policy, \$code), 1, $policy.' glob via <...>' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
foreach my $file (<*.pl>) {
    print $file;
}
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 1, $policy.' glob via <...> in foreach' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
@files = (<*.pl>, <*.pm>);
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 1, $policy.' multiple globs via <...>' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
while (<$fh>) {
    print $_;
}
END_PERL

$policy = 'BuiltinFunctions::RequireGlobFunction';
is( pcritique($policy, \$code), 0, $policy.' I/O' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
isa($foo, $pkg);
UNIVERSAL::isa($foo, $pkg);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalIsa';
is( pcritique($policy, \$code), 2, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use UNIVERSAL::isa;
require UNIVERSAL::isa;
$foo->isa($pkg);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalIsa';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
can($foo, $funcname);
UNIVERSAL::can($foo, $funcname);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalCan';
is( pcritique($policy, \$code), 2, $policy );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use UNIVERSAL::can;
require UNIVERSAL::can;
$foo->can($funcname);
END_PERL

$policy = 'BuiltinFunctions::ProhibitUniversalCan';
is( pcritique($policy, \$code), 0, $policy );

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
sort 'func', @list;

sort(@list);
sort({$a cmp $b;} @list);
sort({$a->[0] <=> $b->[0] && $a->[1] <=> $b->[1]} @list);
sort({bar($a,$b)} @list);
sort('func', @list);

$foo{sort}; # for Devel::Cover
{sort}; # for Devel::Cover
sort();

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

#----------------------------------------------------------------

$code = <<'END_PERL';

# Single quote
split 'pattern';
split 'pattern', $string;
split 'pattern', $string, 3;

# Double quote
split "pattern";
split "pattern", $string;
split "pattern", $string, 3;

# Single quote, w/ parens
split('pattern');
split('pattern'), $string;
split('pattern'), $string, 3;

# Double quote, w/ parens
split("pattern");
split("pattern"), $string;
split("pattern"), $string, 3;

END_PERL

$policy = 'BuiltinFunctions::ProhibitStringySplit';
is( pcritique($policy, \$code), 12, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';

# Scalar arg
split $pattern;
split $pattern, $string;
split $pattern, $string, 3;

# Scalar arg, w/ parens
split($pattern);
split($pattern), $string;
split($pattern), $string, 3;

# Regex arg
split //;
split //, $string;
split //, $string, 3;

# Regex arg, w/ parens
split( // );
split( // ), $string;
split( // ), $string, 3;

$foo{split}; # for Devel::Cover
{split}; # for Devel::Cover

END_PERL

$policy = 'BuiltinFunctions::ProhibitStringySplit';
is( pcritique($policy, \$code), 0, $policy.' Non-stringy splits' );

#----------------------------------------------------------------

$code = <<'END_PERL';

split ' ';
split ' ', $string;
split ' ', $string, 3;

split( " " );
split( " " ), $string;
split( " " ), $string, 3;

split( q{ }  );
split( q{ }  ), $string;
split( q{ }  ), $string, 3;

END_PERL

$policy = 'BuiltinFunctions::ProhibitStringySplit';
is( pcritique($policy, \$code), 0, $policy.' Special split on space' );

#----------------------------------------------------------------

$code = <<'END_PERL';

# These might be technically legal, but they are so hard
# to understand that they might as well be outlawed.

split @list;
split( @list );

END_PERL

$policy = 'BuiltinFunctions::ProhibitStringySplit';
is( pcritique($policy, \$code), 0, $policy.' Split oddities' );

#----------------------------------------------------------------

$code = <<'END_PERL';
sort {$b <=> $a} @list;
sort {$alpha{$b} <=> $beta{$a}} @list;
sort {$b->[0] <=> $a->[0] && $b->[1] <=> $a->[1]} @list;
END_PERL

$policy = 'BuiltinFunctions::ProhibitReverseSortBlock';
is( pcritique($policy, \$code), 3, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
reverse sort {$a <=> $b} @list;
reverse sort {$a->[0] <=> $b->[0] && $a->[1] <=> $b->[1]} @list;
sort {$beta{$a} <=> $alpha{$b}} @list;
reverse sort({$a <=> $b} @list);
reverse sort({$a->[0] <=> $b->[0] && $a->[1] <=> $b->[1]} @list);
sort({$beta{$a} <=> $alpha{$b}} @list);

sort{ $isopen{$a}->[0] <=> $isopen{$b}->[0] } @list;
END_PERL

$policy = 'BuiltinFunctions::ProhibitReverseSortBlock';
is( pcritique($policy, \$code), 0, $policy );


#----------------------------------------------------------------

$code = <<'END_PERL';
$hash1{sort} = { $b <=> $a };
%hash2 = (sort => { $b <=> $a });
$foo->sort({ $b <=> $a });
sub sort { $b <=> $a }
sort 'some_sort_func', @list;
sort('some_sort_func', @list);
sort();

{sort}; # for Devel::Cover
END_PERL

$policy = 'BuiltinFunctions::ProhibitReverseSortBlock';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
grep "$foo", @list;
grep("$foo", @list);
grep { foo($_) } @list;
grep({ foo($_) } @list);

if( $condition ){ grep { foo($_) } @list }
while( $condition ){ grep { foo($_) } @list }
for( @list ){ grep { foo($_) } @list }
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidGrep';
is( pcritique($policy, \$code), 7, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$baz, grep "$foo", @list;
print grep("$foo", @list);
print ( grep "$foo", @list );
@list = ( grep "$foo", @list );
$aref = [ grep "$foo", @list ];
$href = { grep "$foo", @list };

if( grep { foo($_) } @list ) {}
for( grep { foo($_) } @list ) {}
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidGrep';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
map "$foo", @list;
map("$foo", @list);
map { foo($_) } @list;
map({ foo($_) } @list);

if( $condition ){ map { foo($_) } @list }
while( $condition ){ map { foo($_) } @list }
for( @list ){ map { foo($_) } @list }
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidMap';
is( pcritique($policy, \$code), 7, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$baz, map "$foo", @list;
print map("$foo", @list);
print ( map "$foo", @list );
@list = ( map $foo, @list );
$aref = [ map $foo, @list ];
$href = { map $foo, @list };

if( map { foo($_) } @list ) {}
for( map { foo($_) } @list ) {}
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidMap';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
grep { foo($_) }
  grep { bar($_) }
    grep { baz($_) } @list;
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidGrep';
is( pcritique($policy, \$code), 1, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
map { foo($_) }
  map { bar($_) }
    map { baz($_) } @list;
END_PERL

$policy = 'BuiltinFunctions::ProhibitVoidMap';
is( pcritique($policy, \$code), 1, $policy );

#----------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
