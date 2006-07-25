#############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 8;

#-----------------------------------------------------------------------------

use_ok('Perl::Critic::Document');
can_ok('Perl::Critic::Document', 'new');
can_ok('Perl::Critic::Document', 'find');

{
    my $code = q{'print 'Hello World';};  #Has 6 PPI::Element
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::Critic::Document->new( $ppi_doc );
    isa_ok($pc_doc, 'Perl::Critic::Document');


    my $nodes_ref = $pc_doc->find('PPI::Element');
    is( scalar @{ $nodes_ref }, 6, 'Search by class name');

    $nodes_ref = $pc_doc->find( sub{ return 1 } );
    is( scalar @{ $nodes_ref }, 6, 'Search by wanted() handler');

    $nodes_ref = $pc_doc->find( q{Element} );
    is( scalar @{ $nodes_ref }, 6, 'Search by shortened class name');

    {
        # Ignore "Cannot create search condition for 'PPI::': Not a PPI::Element"
        local $SIG{__WARN__} = sub {
            $_[0] =~ m/\QCannot create search condition for\E/ || warn @_
        };
        $nodes_ref = $pc_doc->find( q{} );
        is( $nodes_ref, undef, 'Search by empty class name');
    }
}
