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

# omit the "## Please see file perltidy.ERR" warning
local $SIG{__WARN__} = sub {$_[0] =~ m/\A \#\# [ ] Please [ ] see [ ] file/xms || warn @_};

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

\t\t\t;

END_PERL

$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!
print "\t  \t  foobar  \t";
END_PERL

$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code), 1, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code, \%config), 3, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
;\tfor(1){
\t\tdo_something();
;\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code, \%config), 3, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
open ($foo, $bar);
open($foo, $bar);
uc();
lc();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open $foo, $bar;
uc $foo;
lc $foo;
my $foo;
my ($foo, $bar);
our ($foo, $bar);
local ($foo $bar);
return ($foo, $bar);
return ();
my_subroutine($foo $bar);
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $obj = SomeClass->new();
$obj->open();
$obj->close();
$obj->prototype();
$obj->delete();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = int( 0.5 ) + 1.5;
$foo = int( 0.5 ) - 1.5;
$foo = int( 0.5 ) * 1.5;
$foo = int( 0.5 ) / 1.5;
$foo = int( 0.5 ) ** 1.5;

$foo = oct( $foo ) + 1;
$foo = ord( $foo ) - 1;
$foo = sin( $foo ) * 2;
$foo = uc( $foo ) . $bar;
$foo = lc( $foo ) . $bar;
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, 'parens w/ unary ops');

#----------------------------------------------------------------

$code = <<'END_PERL';
substr join( $delim, @list), $offset, $length;
print reverse( $foo, $bar, $baz), $nuts;
sort map( {some_func($_)} @list1 ), @list2;
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, 'parens w/ greedy funcs');

#----------------------------------------------------------------

$code = <<'END_PERL';
chomp( my $foo = <STDIN> );
defined( my $child = shift @free_children )
return ( $start_time + $elapsed_hours ) % $hours_in_day;
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, 'test cases from RT');

#----------------------------------------------------------------

$code = <<'END_PERL';
grep( { do_something($_) }, @list ) + 3;
join( $delim, @list ) . "\n";
pack( $template, $foo, $bar ) . $suffix;
chown( $file1, $file2 ) || die q{Couldn't chown};
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, 'high operator after parens');

#----------------------------------------------------------------

$code = <<'END_PERL';
grep( { do_something($_) }, $foo, $bar) and do_something();
chown( $file1, $file2 ) or die q{Couldn't chown};
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 2, 'low operator after parens');

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, $bar, $baz);
@list = some_function($foo, $bar, $baz);
@list = ($baz);
@list = ();

@list = ($baz
);

@list = ($baz
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz);

@list = ($foo, 
	 $bar, 
	 $baz
	);

@list = ($foo, 
	 $bar, 
	 $baz
);


END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz,);

@list = ($foo, 
	 $bar, 
	 $baz,
);

@list = ($foo, 
	 $bar, 
	 $baz,
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = ( 1 > 2 ?
         $baz  :
         $nuts );

$bar = ( $condition1
         && (    $condition2
              || $condition3 )
       );


# These were reported as false-positives.
# See http://rt.cpan.org/Ticket/Display.html?id=18297

$median = ( $times[ int $array_size / 2 ] +
            $times[(int $array_size / 2) - 1 ]) / 2;

$median = ( $times[ int $array_size / 2 ] +
            $times[ int $array_size / 2  - 1 ]) / 2;



END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
$foo= 42;
$bar   =56;
$baz   =   67;
END_PERL

$policy = 'CodeLayout::RequireTidyCode';
my $has_perltidy = eval {require Perl::Tidy};
my $expected_result = $has_perltidy ? 1 : 0;
is( pcritique($policy, \$code), $expected_result, 'Untidy code' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Only one trailing newline
$foo = 42;
$bar = 56;
END_PERL

$policy = 'CodeLayout::RequireTidyCode';
is( pcritique($policy, \$code), 0, 'Tidy with one trailing newline' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Two trailing newlines
$foo = 42;
$bar = 56;

END_PERL

$policy = 'CodeLayout::RequireTidyCode';
is( pcritique($policy, \$code), 0, 'Tidy with two trailing newlines' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Several trailing newlines
$foo = 42;
$bar = 56;

   


    
  
END_PERL



$policy = 'CodeLayout::RequireTidyCode';
is( pcritique($policy, \$code), 0, 'Tidy with several trailing newlines' );

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'baz');

@list = ('foo',
	 'bar',
	 'baz');

END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'bee baz');
@list = ('foo, 'bar');
@list = ($foo, 'bar', 'baz');
%hash = ('foo' => 'bar', 'fo' => 'fum');
my_function('foo', 'bar', 'fudge');
foreach ('foo', 'bar', 'nuts'){ do_something($_) }
END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar, 'baz');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'baz', 'nuts');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 1, $policy);
