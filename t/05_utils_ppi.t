#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Readonly;


use PPI::Document qw< >;
use PPI::Statement::Break qw< >;
use PPI::Statement::Compound qw< >;
use PPI::Statement::Data qw< >;
use PPI::Statement::End qw< >;
use PPI::Statement::Expression qw< >;
use PPI::Statement::Include qw< >;
use PPI::Statement::Null qw< >;
use PPI::Statement::Package qw< >;
use PPI::Statement::Scheduled qw< >;
use PPI::Statement::Sub qw< >;
use PPI::Statement::Unknown qw< >;
use PPI::Statement::UnmatchedBrace qw< >;
use PPI::Statement::Variable qw< >;
use PPI::Statement qw< >;
use PPI::Token::Word qw< >;

use Perl::Critic::Utils::PPI qw< :all >;

use Test::More tests => 64;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my @ppi_statement_classes = qw{
    PPI::Statement
        PPI::Statement::Package
        PPI::Statement::Include
        PPI::Statement::Sub
            PPI::Statement::Scheduled
        PPI::Statement::Compound
        PPI::Statement::Break
        PPI::Statement::Data
        PPI::Statement::End
        PPI::Statement::Expression
            PPI::Statement::Variable
        PPI::Statement::Null
        PPI::Statement::UnmatchedBrace
        PPI::Statement::Unknown
};

my %instances = map { $_ => $_->new() } @ppi_statement_classes;
$instances{'PPI::Token::Word'} = PPI::Token::Word->new('foo');

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'is_ppi_expression_or_generic_statement');
can_ok('main', 'is_ppi_generic_statement');
can_ok('main', 'is_ppi_statement_subclass');
can_ok('main', 'is_subroutine_declaration');
can_ok('main', 'is_in_subroutine');

#-----------------------------------------------------------------------------
#  is_ppi_expression_or_generic_statement tests

{
    ok(
        ! is_ppi_expression_or_generic_statement( undef ),
        'is_ppi_expression_or_generic_statement( undef )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_expression_or_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::End )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_generic_statement tests

{
    ok(
        ! is_ppi_generic_statement( undef ),
        'is_ppi_generic_statement( undef )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Token::Word'} ),
        'is_ppi_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_generic_statement( $instances{'PPI::Statement'} ),
        'is_ppi_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Package'} ),
        'is_ppi_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Include'} ),
        'is_ppi_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Break'} ),
        'is_ppi_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Data'} ),
        'is_ppi_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::End'} ),
        'is_ppi_generic_statement( PPI::Statement::End )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Null'} ),
        'is_ppi_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_generic_statement( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_generic_statement( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_ppi_statement_subclass tests

{
    ok(
        ! is_ppi_statement_subclass( undef ),
        'is_ppi_statement_subclass( undef )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Token::Word'} ),
        'is_ppi_statement_subclass( PPI::Token::Word )',
    );
    ok(
        ! is_ppi_statement_subclass( $instances{'PPI::Statement'} ),
        'is_ppi_statement_subclass( PPI::Statement )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Package'} ),
        'is_ppi_statement_subclass( PPI::Statement::Package )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Include'} ),
        'is_ppi_statement_subclass( PPI::Statement::Include )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Sub'} ),
        'is_ppi_statement_subclass( PPI::Statement::Sub )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Scheduled'} ),
        'is_ppi_statement_subclass( PPI::Statement::Scheduled )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Compound'} ),
        'is_ppi_statement_subclass( PPI::Statement::Compound )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Break'} ),
        'is_ppi_statement_subclass( PPI::Statement::Break )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Data'} ),
        'is_ppi_statement_subclass( PPI::Statement::Data )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::End'} ),
        'is_ppi_statement_subclass( PPI::Statement::End )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Expression'} ),
        'is_ppi_statement_subclass( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Variable'} ),
        'is_ppi_statement_subclass( PPI::Statement::Variable )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Null'} ),
        'is_ppi_statement_subclass( PPI::Statement::Null )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_statement_subclass( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        is_ppi_statement_subclass( $instances{'PPI::Statement::Unknown'} ),
        'is_ppi_statement_subclass( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------
#  is_subroutine_declaration() tests

{
    my $test = sub {
        my ($code, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $doc->first_element();
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic (Variables::ProhibitPackageVars)
        is(
            ! ! is_subroutine_declaration( $input ),
            ! ! $result,
            "is_subroutine_declaration(): $name"
        );

        return;
    };

    $test->('sub {};'        => 1);
    $test->('sub {}'         => 1);
    $test->('{}'             => 0);
    $test->(undef,              0);
    $test->('{ sub foo {} }' => 0);
    $test->('sub foo;'       => 1);
}

#-----------------------------------------------------------------------------
#  is_in_subroutine() tests

{
    my $test = sub {
        my ($code, $transform, $result) = @_;

        my $doc;
        my $input;

        if (defined $code) {
            $doc = PPI::Document->new(\$code, readonly => 1);
        }
        if (defined $doc) {
            $input = $transform->($doc);
        }

        my $name = defined $code ? $code : '<undef>';

        local $Test::Builder::Level = $Test::Builder::Level + 1; ## no critic (Variables::ProhibitPackageVars)
        is(
            ! ! is_in_subroutine( $input ),
            ! ! $result,
            "is_in_subroutine(): $name"
        );

        return;
    };

    $test->(undef, sub {}, 0);

    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    $test->('my $foo = 42', sub {}, 0);

    $test->(
        'sub foo { my $foo = 42 }',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        'sub { my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        1,
    );

    $test->(
        '{ my $foo = 42 };',
        sub {
            my ($doc) = @_;
            $doc->find_first('PPI::Statement::Variable');
        },
        0,
    );
    ## use critic
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/05_utils_ppi.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
