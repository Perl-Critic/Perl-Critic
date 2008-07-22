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

use Test::More tests => 67;

#-----------------------------------------------------------------------------

our $VERSION = '1.089';

#-----------------------------------------------------------------------------

my @PPI_STATEMENT_CLASSES;

BEGIN {
    @PPI_STATEMENT_CLASSES = qw{
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

    use_ok('PPI::Token::Word');
    foreach my $class (@PPI_STATEMENT_CLASSES) {
        use_ok($class);
    }

    use_ok('Perl::Critic::Utils::PPI', qw{ :all } );
}

my %INSTANCES = map { $_ => $_->new() } @PPI_STATEMENT_CLASSES;
$INSTANCES{'PPI::Token::Word'} = PPI::Token::Word->new('foo');

#-----------------------------------------------------------------------------
#  export tests

can_ok('main', 'is_ppi_expression_or_generic_statement');
can_ok('main', 'is_ppi_generic_statement');
can_ok('main', 'is_ppi_statement_subclass');

#-----------------------------------------------------------------------------
#  is_ppi_expression_or_generic_statement tests

{
    ok(
        ! is_ppi_expression_or_generic_statement( undef ),
        'is_ppi_expression_or_generic_statement( undef )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Token::Word'} ),
        'is_ppi_expression_or_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Package'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Include'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Sub'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Scheduled'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Compound'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Break'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Data'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::End'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::End )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Expression'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Variable'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Null'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_expression_or_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_expression_or_generic_statement( $INSTANCES{'PPI::Statement::Unknown'} ),
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
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Token::Word'} ),
        'is_ppi_generic_statement( PPI::Token::Word )',
    );
    ok(
        is_ppi_generic_statement( $INSTANCES{'PPI::Statement'} ),
        'is_ppi_generic_statement( PPI::Statement )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Package'} ),
        'is_ppi_generic_statement( PPI::Statement::Package )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Include'} ),
        'is_ppi_generic_statement( PPI::Statement::Include )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Sub'} ),
        'is_ppi_generic_statement( PPI::Statement::Sub )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Scheduled'} ),
        'is_ppi_generic_statement( PPI::Statement::Scheduled )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Compound'} ),
        'is_ppi_generic_statement( PPI::Statement::Compound )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Break'} ),
        'is_ppi_generic_statement( PPI::Statement::Break )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Data'} ),
        'is_ppi_generic_statement( PPI::Statement::Data )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::End'} ),
        'is_ppi_generic_statement( PPI::Statement::End )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Expression'} ),
        'is_ppi_generic_statement( PPI::Statement::Expression )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Variable'} ),
        'is_ppi_generic_statement( PPI::Statement::Variable )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Null'} ),
        'is_ppi_generic_statement( PPI::Statement::Null )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_generic_statement( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        ! is_ppi_generic_statement( $INSTANCES{'PPI::Statement::Unknown'} ),
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
        ! is_ppi_statement_subclass( $INSTANCES{'PPI::Token::Word'} ),
        'is_ppi_statement_subclass( PPI::Token::Word )',
    );
    ok(
        ! is_ppi_statement_subclass( $INSTANCES{'PPI::Statement'} ),
        'is_ppi_statement_subclass( PPI::Statement )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Package'} ),
        'is_ppi_statement_subclass( PPI::Statement::Package )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Include'} ),
        'is_ppi_statement_subclass( PPI::Statement::Include )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Sub'} ),
        'is_ppi_statement_subclass( PPI::Statement::Sub )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Scheduled'} ),
        'is_ppi_statement_subclass( PPI::Statement::Scheduled )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Compound'} ),
        'is_ppi_statement_subclass( PPI::Statement::Compound )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Break'} ),
        'is_ppi_statement_subclass( PPI::Statement::Break )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Data'} ),
        'is_ppi_statement_subclass( PPI::Statement::Data )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::End'} ),
        'is_ppi_statement_subclass( PPI::Statement::End )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Expression'} ),
        'is_ppi_statement_subclass( PPI::Statement::Expression )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Variable'} ),
        'is_ppi_statement_subclass( PPI::Statement::Variable )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Null'} ),
        'is_ppi_statement_subclass( PPI::Statement::Null )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::UnmatchedBrace'} ),
        'is_ppi_statement_subclass( PPI::Statement::UnmatchedBrace )',
    );
    ok(
        is_ppi_statement_subclass( $INSTANCES{'PPI::Statement::Unknown'} ),
        'is_ppi_statement_subclass( PPI::Statement::Unknown )',
    );
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
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
