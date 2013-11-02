#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

## There's too much use of source code in strings.
## no critic (RequireInterpolationOfMetachars)

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;

use File::Temp qw< >;
use PPI::Document qw< >;
use PPI::Document::File qw< >;

use Perl::Critic::PolicyFactory;
use Perl::Critic::TestUtils qw(bundled_policy_names);
use Perl::Critic::Utils;

use Test::More tests => 124;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

test_export();
test_find_keywords();
test_is_hash_key();
test_is_script();
test_is_script_with_PL_files();
test_is_perl_builtin();
test_is_perl_global();
test_precedence_of();
test_is_subroutine_name();
test_policy_long_name_and_policy_short_name();
test_interpolate();
test_is_perl_and_shebang_line();
test_is_backup();
test_first_arg();
test_parse_arg_list();
test_is_function_call();
test_find_bundled_policies();
test_is_unchecked_call();

#-----------------------------------------------------------------------------

sub test_export {
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
    can_ok('main', 'shebang_line');
    can_ok('main', 'verbosity_to_format');
    can_ok('main', 'is_unchecked_call');

    is($SPACE, q< >, 'character constants');
    is($SEVERITY_LOWEST, 1, 'severity constants');
    is($POLICY_NAMESPACE, 'Perl::Critic::Policy', 'Policy namespace');

    return;
}

#-----------------------------------------------------------------------------

sub count_matches { my $val = shift; return defined $val ? scalar @{$val} : 0; }
sub make_doc {
    my $code = shift;
    return
        Perl::Critic::Document->new('-source' => ref $code ? $code : \$code);
}

sub test_find_keywords {
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

    return;
}

#-----------------------------------------------------------------------------

sub test_is_hash_key {
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

    for my $i (0 .. $#expect) {
        is($words[$i], $expect[$i][0], 'is_hash_key word');
        is( !!is_hash_key($words[$i]), !!$expect[$i][1], 'is_hash_key boolean' );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_is_script {
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

    no warnings qw< deprecated >;   ## no critic (TestingAndDebugging::ProhibitNoWarnings)

    for my $code (@good) {
        my $doc = PPI::Document->new(\$code) or confess;
        $doc->index_locations();
        ok(is_script($doc), 'is_script, true');
    }

    for my $code (@bad) {
        my $doc = PPI::Document->new(\$code) or confess;
        $doc->index_locations();
        ok(!is_script($doc), 'is_script, false');
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_is_script_with_PL_files { ## no critic (NamingConventions::Capitalization)

    # Testing for .PL files (e.g. Makefile.PL, Build.PL)
    # See http://rt.cpan.org/Ticket/Display.html?id=20481
    my $temp_file = File::Temp->new(SUFFIX => '.PL');

    # The file must have content, or PPI will barf...
    print {$temp_file} "some code\n";
    # Just to flush the buffer.
    close $temp_file or confess "Couldn't close $temp_file: $OS_ERROR";

    my $doc = PPI::Document::File->new($temp_file->filename());

    no warnings qw< deprecated >;   ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    ok(is_script($doc), 'is_script, false for .PL files');

    return;
}

#-----------------------------------------------------------------------------

sub test_is_perl_builtin {
    ok(  is_perl_builtin('print'),  'Is perl builtin function'     );
    ok( !is_perl_builtin('foobar'), 'Is not perl builtin function' );

    my $code = 'sub print {}';
    my $doc = make_doc( $code );
    my $sub = $doc->find_first('Statement::Sub');
    ok( is_perl_builtin($sub), 'Is perl builtin function (PPI)' );

    $code = 'sub foobar {}';
    $doc = make_doc( $code );
    $sub = $doc->find_first('Statement::Sub');
    ok( !is_perl_builtin($sub), 'Is not perl builtin function (PPI)' );

    return;
}

#-----------------------------------------------------------------------------

sub test_is_perl_global {
    ok(  is_perl_global('$OSNAME'), '$OSNAME is a perl global var'     );
    ok(  is_perl_global('*STDOUT'), '*STDOUT is a perl global var'     );
    ok( !is_perl_global('%FOOBAR'), '%FOOBAR is a not perl global var' );

    my $code = '$OSNAME';
    my $doc  = make_doc($code);
    my $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), '$OSNAME is perl a global var (PPI)' );

    $code = '*STDOUT';
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), '*STDOUT is perl a global var (PPI)' );

    $code = '%FOOBAR';
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( !is_perl_global($var), '%FOOBAR is not a perl global var (PPI)' );

    $code = q[$\\];
    $doc  = make_doc($code);
    $var  = $doc->find_first('Token::Symbol');
    ok( is_perl_global($var), "$code is a perl global var (PPI)" );

    return;
}

#-----------------------------------------------------------------------------

sub test_precedence_of {
    cmp_ok( precedence_of(q<*>), q[<], precedence_of(q<+>), 'Precedence' );

    my $code1 = '8 + 5';
    my $doc1  = make_doc($code1);
    my $op1   = $doc1->find_first('Token::Operator');

    my $code2 = '7 * 5';
    my $doc2  = make_doc($code2);
    my $op2   = $doc2->find_first('Token::Operator');

    cmp_ok( precedence_of($op2), '<', precedence_of($op1), 'Precedence (PPI)' );

    return;
}

#-----------------------------------------------------------------------------

sub test_is_subroutine_name {
    my $code = 'sub foo {}';
    my $doc  = make_doc( $code );
    my $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    ok( is_subroutine_name( $word ), 'Is a subroutine name');

    $code = '$bar = foo()';
    $doc  = make_doc( $code );
    $word = $doc->find_first( sub { $_[1] eq 'foo' } );
    ok( !is_subroutine_name( $word ), 'Is not a subroutine name');

    return;
}

#-----------------------------------------------------------------------------

sub test_policy_long_name_and_policy_short_name {
    my $short_name = 'Baz::Nuts';
    my $long_name  = "${POLICY_NAMESPACE}::$short_name";
    is( policy_long_name(  $short_name ), $long_name,  'policy_long_name'  );
    is( policy_long_name(  $long_name  ), $long_name,  'policy_long_name'  );
    is( policy_short_name( $short_name ), $short_name, 'policy_short_name' );
    is( policy_short_name( $long_name  ), $short_name, 'policy_short_name' );

    return;
}

#-----------------------------------------------------------------------------

sub test_interpolate {
    is( interpolate( '\r%l\t%c\n' ), "\r%l\t%c\n", 'Interpolation' );
    is( interpolate( 'literal'    ), 'literal',    'Interpolation' );

    return;
}

#-----------------------------------------------------------------------------

sub test_is_perl_and_shebang_line {
    for ( qw(foo.t foo.pm foo.pl foo.PL) ) {
        ok( Perl::Critic::Utils::_is_perl($_), qq{Is perl: '$_'} );
    }

    for ( qw(foo.doc foo.txt foo.conf foo) ) {
        ok( ! Perl::Critic::Utils::_is_perl($_), qq{Is not perl: '$_'} );
    }

    my @perl_shebangs = (
        '#!perl',
        '#!/usr/local/bin/perl',
        '#!/usr/local/bin/perl-5.8',
        '#!/bin/env perl',
        '#!perl ## no critic',
        '#!perl ## no critic (foo)',
    );

    for my $shebang (@perl_shebangs) {
        my $temp_file =
            File::Temp->new( TEMPLATE => 'Perl-Critic.05_utils.t.XXXXX' );
        my $filename = $temp_file->filename();
        print {$temp_file} "$shebang\n";
        # Must close to flush buffer
        close $temp_file or confess "Couldn't close $temp_file: $OS_ERROR";

        ok( Perl::Critic::Utils::_is_perl($filename), qq{Is perl: '$shebang'} );

        my $document = PPI::Document->new(\$shebang);
        is(
            Perl::Critic::Utils::shebang_line($document),
            $shebang,
            qq<shebang_line($shebang)>,
        );
    }

    my @not_perl_shebangs = (
        'shazbot',
        '#!/usr/bin/ruby',
        '#!/bin/env python',
    );

    for my $shebang (@not_perl_shebangs) {
        my $temp_file =
            File::Temp->new( TEMPLATE => 'Perl-Critic.05_utils.t.XXXXX' );
        my $filename = $temp_file->filename();
        print {$temp_file} "$shebang\n";
        # Must close to flush buffer
        close $temp_file or confess "Couldn't close $temp_file: $OS_ERROR";

        ok( ! Perl::Critic::Utils::_is_perl($filename), qq{Is not perl: '$shebang'} );

        my $document = PPI::Document->new(\$shebang);
        is(
            Perl::Critic::Utils::shebang_line($document),
            ($shebang eq 'shazbot' ? undef : $shebang),
            qq<shebang_line($shebang)>,
        );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_is_backup {
    for ( qw( foo.swp foo.bak foo~ ), '#foo#' ) {
        ok( Perl::Critic::Utils::_is_backup($_), qq{Is backup: '$_'} );
    }

    for ( qw( swp.pm Bak ~foo ) ) {
        ok( ! Perl::Critic::Utils::_is_backup($_), qq{Is not backup: '$_'} );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_first_arg {
    my @tests = (
        q{eval { some_code() };}   => q{{ some_code() }},
        q{eval( {some_code() } );} => q{{some_code() }},
        q{eval();}                 => undef,
    );

    for (my $i = 0; $i < @tests; $i += 2) { ## no critic (ProhibitCStyleForLoops)
        my $code = $tests[$i];
        my $expect = $tests[$i+1];
        my $doc = PPI::Document->new(\$code);
        my $got = first_arg($doc->first_token());
        is($got ? "$got" : undef, $expect, 'first_arg - '.$code);
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_parse_arg_list {
    my @tests = (
        [ q/foo($bar, 'baz', 1)/ => [ [ q<$bar> ],  [ q<'baz'> ],  [ q<1> ], ] ],
        [
                q/foo( { bar => 1 }, { bar => 1 }, 'blah' )/
            =>  [
                    [ '{ bar => 1 }' ],
                    [ '{ bar => 1 }' ],
                    [ q<'blah'> ],
                ],
        ],
        [
                q/foo( { bar() }, {}, 'blah' )/
            =>  [
                    ' { bar() }',
                    [ qw< {} > ],
                    [ q<'blah'> ],
                ],
        ],
    );

    foreach my $test (@tests) {
        my ($code, $expected) = @{ $test };

        my $document = PPI::Document->new( \$code );
        my @got = parse_arg_list( $document->first_token() );
        is_deeply( \@got, $expected, "parse_arg_list: $code" );
    }

    return;
}

#-----------------------------------------------------------------------------

sub test_is_function_call {
    my $code = 'sub foo{}';
    my $doc = PPI::Document->new( \$code );
    my $words = $doc->find('PPI::Token::Word');
    is(scalar @{$words}, 2, 'count PPI::Token::Words');
    is((scalar grep {is_function_call($_)} @{$words}), 0, 'is_function_call');

    return;
}

#-----------------------------------------------------------------------------

sub test_find_bundled_policies {
    Perl::Critic::TestUtils::block_perlcriticrc();

    my @native_policies = bundled_policy_names();
    my $policy_dir = File::Spec->catfile( qw(lib Perl Critic Policy) );
    my @found_policies  = all_perl_files( $policy_dir );
    is( scalar @found_policies, scalar @native_policies, 'Find all perl code');

    return;
}

#-----------------------------------------------------------------------------
sub test_is_unchecked_call {
    my @trials = (
        # just an obvious failure to check the return value
        {
            code => q[ open( $fh, $mode, $filename ); ],
            pass => 1,
        },
        # check the value with a trailing conditional
        {
            code => q[ open( $fh, $mode, $filename ) or confess 'unable to open'; ],
            pass => 0,
        },
        # assign the return value to a variable (and assume that it's checked later)
        {
            code => q[ my $error = open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        # the system call is in a conditional
        {
            code => q[ return $EMPTY if not open my $fh, '<', $file; ],
            pass => 0,
        },
        # open call in list context, checked with 'not'
        {
            code => q[ return $EMPTY if not ( open my $fh, '<', $file ); ],
            pass => 0,
        },
        # just putting the system call in a list context doesn't mean the return value is checked
        {
            code => q[ ( open my $fh, '<', $file ); ],
            pass => 1,
        },

        # Check Fatal.
        {
            code => q[ use Fatal qw< open >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use Fatal qw< open >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },

        # Check Fatal::Exception.
        {
            code => q[ use Fatal::Exception 'Exception::System' => qw< open close >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use Fatal::Exception 'Exception::System' => qw< open close >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },

        # Check autodie.
        {
            code => q[ use autodie; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use autodie qw< :io >; open( $fh, $mode, $filename ); ],
            pass => 0,
        },
        {
            code => q[ use autodie qw< :system >; ( open my $fh, '<', $file ); ],
            pass => 1,
        },
        {
            code => q[ use autodie qw< :system :file >; ( open my $fh, '<', $file ); ],
            pass => 0,
        },
    );

    foreach my $trial ( @trials ) {
        my $code = $trial->{'code'};
        my $doc = make_doc( $code );
        my $statement = $doc->find_first( sub { $_[1] eq 'open' } );
        if ( $trial->{'pass'} ) {
            ok( is_unchecked_call( $statement ), qq<is_unchecked_call returns true for "$code".> );
        } else {
            ok( ! is_unchecked_call( $statement ), qq<is_unchecked_call returns false for "$code".> );
        }
    }

    return;
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/05_utils.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
