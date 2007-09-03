#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use PPI::Document;
use Test::More tests => 91;

#-----------------------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Utils', qw{ :all } );
}

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'all_perl_files');
can_ok('main', 'find_keywords');
can_ok('main', 'interpolate');
can_ok('main', 'is_hash_key');
can_ok('main', 'is_method_call');
can_ok('main', 'is_perl_builtin');
can_ok('main', 'is_perl_global');
can_ok('main', 'is_script');
can_ok('main', 'is_subroutine_name');
can_ok('main', 'first_arg');
can_ok('main', 'parse_arg_list');
can_ok('main', 'policy_long_name');
can_ok('main', 'policy_short_name');
can_ok('main', 'precedence_of');
can_ok('main', 'severity_to_number');
can_ok('main', 'verbosity_to_format');
can_ok('main', 'is_unchecked_call');

is($SPACE, ' ', 'character constants');
is($SEVERITY_LOWEST, 1, 'severity constants');
is($POLICY_NAMESPACE, 'Perl::Critic::Policy', 'Policy namespace');

#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
#  is_hash_key tests

{
   my $code = 'sub foo { return $h1{bar}, $h2->{baz}, $h3->{ nuts() } }';
   my $doc = PPI::Document->new(\$code);
   my @words = @{$doc->find('PPI::Token::Word')};
   my @expect = (
      ['sub', undef],
      ['foo', undef],
      ['return', undef],
      ['bar', 1],
      ['baz', 1],
      ['nuts', undef],
   );
   is(scalar @words, scalar @expect, 'is_hash_key count');
   for my $i (0 .. $#expect)
   {
      is($words[$i], $expect[$i][0], 'is_hash_key word');
      is(is_hash_key($words[$i]), $expect[$i][1], 'is_hash_key boolean');
   }
}

#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
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

#-----------------------------------------------------------------------------
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
# policy_long_name and policy_short_name tests

{
    my $short_name = 'Baz::Nuts';
    my $long_name  = "${POLICY_NAMESPACE}::$short_name";
    is( policy_long_name(  $short_name ), $long_name,  'policy_long_name'  );
    is( policy_long_name(  $long_name  ), $long_name,  'policy_long_name'  );
    is( policy_short_name( $short_name ), $short_name, 'policy_short_name' );
    is( policy_short_name( $long_name  ), $short_name, 'policy_short_name' );
}

#-----------------------------------------------------------------------------
# interpolate() tests

is( interpolate( '\r%l\t%c\n' ), "\r%l\t%c\n", 'Interpolation' );
is( interpolate( 'literal'    ), "literal",    'Interpolation' );


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
# first_arg tests

{
    my @tests = (
        q{eval { some_code() };}   => q{{ some_code() }},
        q{eval( {some_code() } );} => q{{some_code() }},
        q{eval();}                 => undef,
    );

    for (my $i = 0; $i < @tests; $i += 2) {
        my $code = $tests[$i];
        my $expect = $tests[$i+1];
        my $doc = PPI::Document->new(\$code);
        my $got = first_arg($doc->first_token());
        is($got ? "$got" : undef, $expect, 'first_arg - '.$code);
    }
}

#-----------------------------------------------------------------------------

{
    my $code = 'sub foo{}';
    my $doc = PPI::Document->new( \$code );
    my $words = $doc->find('PPI::Token::Word');
    is(scalar @{$words}, 2, 'count PPI::Token::Words');
    is((scalar grep {is_function_call($_)} @{$words}), 0, 'is_function_call');
}

#-----------------------------------------------------------------------------


use Perl::Critic::PolicyFactory;
use Perl::Critic::TestUtils qw(bundled_policy_names);
Perl::Critic::TestUtils::block_perlcriticrc();


my @native_policies = bundled_policy_names();
my $policy_dir = File::Spec->catfile( qw(lib Perl Critic Policy) );
my @found_policies  = all_perl_files( $policy_dir );
is( scalar @found_policies, scalar @native_policies, 'Find all perl code');

#-----------------------------------------------------------------------------
# is_unchecked_call tests
{
    my @trials = (
                  # just an obvious failure to check the return value
                  { code => q( open( $fh, $mode, $filename ); ),
                    pass => 1 },
                  # check the value with a trailing conditional
                  { code => q( open( $fh, $mode, $filename ) or die 'unable to open'; ),
                    pass => 0 },
                  # assign the return value to a variable (and assume that it's checked later)
                  { code => q( my $error = open( $fh, $mode, $filename ); ),
                    pass => 0 },
                  # the system call is in a conditional
                  { code => q( return $EMPTY if not open my $fh, '<', $file; ),
                    pass => 0 },
                  # open call in list context, checked with 'not'
                  { code => q( return $EMPTY if not ( open my $fh, '<', $file ); ),
                    pass => 0 },
                  # just putting the system call in a list context doesn't mean the return value is checked
                  { code => q( ( open my $fh, '<', $file ); ),
                    pass => 1 },
                 );

    foreach my $trial ( @trials ) {
        my $doc = make_doc( $trial->{'code'} );
        my $statement = $doc->find_first( sub { $_[1] eq 'open' } );
        if ( $trial->{'pass'} ) {
            ok( is_unchecked_call( $statement ), 'is_unchecked_call returns true' );
        } else {
            ok( ! is_unchecked_call( $statement ), 'is_unchecked_call returns false' );
        }
    }
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/05_utils.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
