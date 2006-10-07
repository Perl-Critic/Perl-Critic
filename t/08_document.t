#!perl

#############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 18;

#-----------------------------------------------------------------------------

use_ok('Perl::Critic::Document');
can_ok('Perl::Critic::Document', 'new');
can_ok('Perl::Critic::Document', 'find');
can_ok('Perl::Critic::Document', 'find_first');
can_ok('Perl::Critic::Document', 'find_any');

{
    my $code = q{'print 'Hello World';};  #Has 6 PPI::Element
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::Critic::Document->new( $ppi_doc );
    isa_ok($pc_doc, 'Perl::Critic::Document');


    my $nodes_ref = $pc_doc->find('PPI::Element');
    is( scalar @{ $nodes_ref }, 6, 'find by class name');

    $nodes_ref = $pc_doc->find( sub{ return 1 } );
    is( scalar @{ $nodes_ref }, 6, 'find by wanted() handler');

    $nodes_ref = $pc_doc->find( q{Element} );
    is( scalar @{ $nodes_ref }, 6, 'find by shortened class name');

    #---------------------------

    my $node = $pc_doc->find_first('PPI::Element');
    is( ref $node, 'PPI::Statement', 'find_first by class name');

    $node = $pc_doc->find_first( sub{ return 1 } );
    is( ref $node, 'PPI::Statement', 'find_first by wanted() handler');

    $node = $pc_doc->find_first( q{Element} );
    is( ref $node, 'PPI::Statement', 'find_first by shortened class name');

    #---------------------------

    my $found = $pc_doc->find_any('PPI::Element');
    is( $found, 1, 'find_any by class name');

    $found = $pc_doc->find_any( sub{ return 1 } );
    is( $found, 1, 'find_any by wanted() handler');

    $found = $pc_doc->find_any( q{Element} );
    is( $found, 1, 'find_any by shortened class name');

    #-------------------------------------------------------------------------

    {
        # Ignore "Cannot create search condition for 'PPI::': Not a PPI::Element"
        local $SIG{__WARN__} = sub {
            $_[0] =~ m/\QCannot create search condition for\E/ || warn @_
        };
        $nodes_ref = $pc_doc->find( q{} );
        is( $nodes_ref, undef, 'find by empty class name');

        $node = $pc_doc->find_first( q{} );
        is( $node, undef, 'find_first by empty class name');

        $found = $pc_doc->find_any( q{} );
        is( $found, undef, 'find_any by empty class name');

    }
}
