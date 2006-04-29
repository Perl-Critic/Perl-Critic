use strict;
use warnings;
use PPI::Document;
use Test::More tests => 66;

#---------------------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Utils');
}

#---------------------------------------------------------------------------
#  export tests

can_ok('main', 'find_keywords');
can_ok('main', 'is_hash_key');
can_ok('main', 'is_method_call');
can_ok('main', 'parse_arg_list');
can_ok('main', 'is_perl_global');
can_ok('main', 'is_perl_builtin');
can_ok('main', 'is_subroutine_name');
can_ok('main', 'precedence_of');
can_ok('main', 'is_script');
can_ok('main', 'all_perl_files');

is($SPACE, ' ', 'character constants');
is($SEVERITY_LOWEST, 1, 'severity constants');

# These globals are deprecated.  Use function instead
is((scalar grep {$_ eq 'grep'} @BUILTINS), 1, 'perl builtins');
is((scalar grep {$_ eq 'OSNAME'} @GLOBALS), 1, 'perl globals');

#---------------------------------------------------------------------------
#  find_keywords tests

sub count_matches { my $val = shift; return defined $val ? scalar @$val : 0; }
sub make_doc { my $code = shift; return PPI::Document->new( ref $code ? $code : \$code); }

{
    my $doc = PPI::Document->new(); #Empty doc
    is( count_matches( find_keywords($doc, 'return') ), 0, 'find_keywords, no doc' );

    my $code = 'return;';
    $doc = make_doc( $code );
    is( count_matches( find_keywords($doc, 'return') ), 1, 'find_keywords, find 1');

    $code = 'sub foo { }';
    $doc = make_doc( $code );
    is( count_matches( find_keywords($doc, 'return') ), 0, 'find_keywords, find 0');

    $code = 'sub foo { return 1; }';
    $doc = make_doc( $code );
    is( count_matches( find_keywords($doc, 'return') ), 1, 'find_keywords, find 1');

    $code = 'sub foo { return 0 if @_; return 1; }';
    $doc = make_doc( $code );
    is( count_matches( find_keywords($doc, 'return') ), 2, 'find_keywords, find 2');
}

#---------------------------------------------------------------------------
#  is_hash_key tests

{
   my $code = 'sub foo { return $hash1{bar}, $hash2->{baz}; }';
   my $doc = PPI::Document->new(\$code);
   my @words = @{$doc->find('PPI::Token::Word')};
   my @expect = (
      ['sub', 0],
      ['foo', 0],
      ['return', 0],
      ['bar', 1],
      ['baz', 1],
   );
   is(scalar @words, scalar @expect, 'is_hash_key count');
   for my $i (0 .. $#expect)
   {
      is($words[$i], $expect[$i][0], 'is_hash_key word');
      is(is_hash_key($words[$i]), $expect[$i][1], 'is_hash_key boolean');
   }
}

#---------------------------------------------------------------------------
#  is_script tests

my @good = (
    "#!perl\n",
    "#! perl\n",
    "#!/usr/bin/perl -w\n",
    "#!C:\\Perl\\bin\\perl\n",
    "#!/bin/sh\n",
);

my @bad = (
    "package Foo;\n",
    "\n#!perl\n",
);

for my $code (@good) {
    my $doc = PPI::Document->new(\$code) || die;
    $doc->index_locations();
    ok(is_script($doc), 'is_script, true');
}

for my $code (@bad) {
    my $doc = PPI::Document->new(\$code) || die;
    $doc->index_locations();
    ok(!is_script($doc), 'is_script, false');
}

#---------------------------------------------------------------------------
# is_perl_builtin tests

{
    is(   is_perl_builtin('print'),  1, 'Is perl builtin function'     );
    isnt( is_perl_builtin('foobar'), 1, 'Is not perl builtin function' );

    my $code = 'sub print {}';
    my $doc = make_doc( $code );
    my $sub = $doc->find_first('Statement::Sub');
    is( is_perl_builtin($sub), 1, 'Is perl builtin function (PPI)' );

    $code = 'sub foobar {}';
    $doc = make_doc( $code );
    $sub = $doc->find_first('Statement::Sub');
    isnt( is_perl_builtin($sub), 1, 'Is not perl builtin function (PPI)' );

}

#---------------------------------------------------------------------------
# is_perl_global tests

{
    is(   is_perl_global('$OSNAME'),  1, 'Is perl global var'     );
    isnt( is_perl_global('%FOOBAR'),  1, 'Is not perl global var' );

    my $code = '$OSNAME';
    my $doc  = make_doc($code);
    my $var  = $doc->find_first('Token::Symbol');
    is( is_perl_global($var), 1, 'Is perl global var (PPI)' );

    $code = '%FOOBAR';
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    isnt( is_perl_global($var), 1, 'Is not perl global var (PPI)' );

}

#---------------------------------------------------------------------------
# precedence_of tests

{

    cmp_ok( precedence_of('*'), '<', precedence_of('+'), 'Precedence' );

    my $code1 = '8 + 5';
    my $doc1  = make_doc($code1);
    my $op1   = $doc1->find_first('Token::Operator');

    my $code2 = '7 * 5';
    my $doc2  = make_doc($code2);
    my $op2   = $doc2->find_first('Token::Operator');

    cmp_ok( precedence_of($op2), '<', precedence_of($op1), 'Precedence (PPI)' );

}

#---------------------------------------------------------------------------
# is_subroutine_name tests

{

    my $code = 'sub foo {}';
    my $doc  = make_doc( $code );
    my $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    is( is_subroutine_name( $word ), 1, 'Is a subroutine name');

    $code = '$bar = foo()';
    $doc  = make_doc( $code );
    $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    isnt( is_subroutine_name( $word ), 1, 'Is not a subroutine name');

}


#-----------------------------------------------------------------------------
# Test _is_perl() subroutine.  This used to be part of `perlcritic` but I
# moved it into the Utils module so it could be shared with Test::P::C

{
    for ( qw(foo.t foo.pm foo.pl foo.PL) ) {
        ok( Perl::Critic::Utils::_is_perl($_), qq{Is perl: '$_'} );
    }

    for ( qw(foo.doc foo.txt foo.conf foo) ) {
        ok( ! Perl::Critic::Utils::_is_perl($_), qq{Is not perl: '$_'} );
    }
}

#-----------------------------------------------------------------------------
# _is_backup() tests

{
    for ( qw( foo.swp foo.bak foo~ ), '#foo#' ) {
        ok( Perl::Critic::Utils::_is_backup($_), qq{Is backup: '$_'} );
    }

    for ( qw( swp.pm Bak ~foo ) ) {
        ok( ! Perl::Critic::Utils::_is_backup($_), qq{Is not backup: '$_'} );
    }
}

#-----------------------------------------------------------------------------

use lib qw(t/tlib);
use Perl::Critic::Config;
use PerlCriticTestUtils qw();
PerlCriticTestUtils::block_perlcriticrc();


my @native_policies = Perl::Critic::Config::native_policies();
my @found_policies  = all_perl_files( 'lib/Perl/Critic/Policy' );
is( scalar @found_policies, scalar @native_policies, 'Find all perl code');
