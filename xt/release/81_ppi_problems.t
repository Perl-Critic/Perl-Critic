#!/usr/bin/perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use PPI::Document;

use Test::More tests => 4;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

# Things we're looking for from PPI.

{
    local $TODO = q<Clean up code in Modules::ProhibitUnusedImports once this is released.>;

    can_ok 'PPI::Statement::Include', 'arguments';
}

{
    local $TODO = q<Clean up code in Modules::ProhibitUnusedImports once this is released.>;

    can_ok 'PPI::Token::QuoteLike::Words', 'literal';
}

{
    local $TODO = q<Clean up code in P::C::Utils::PPI once PPI can handle these.>;

    my $document = PPI::Document->new(\'sub { }');

    # Since we don't know what a correctly parsing PPI would do, simply test
    # that it doesn't like it does when it doesn't correctly parse.
    my @children = $document->schildren();
    if (
            @children == 1
        and ( my $statement = $children[0] )->isa('PPI::Statement')
    ) {
        @children = $statement->schildren();
        if (@children == 2) {
            my ($maybe_sub, $maybe_block) = @children;

            if (
                    $maybe_sub->isa('PPI::Token::Word')
                and $maybe_sub->content() eq 'sub'
                and $maybe_block->isa('PPI::Structure::Block')
                and $maybe_block->schildren() == 0
            ) {
                fail(q<PPI doesn't parse anonymous subroutines.>);
            }
            else {
                pass(q<PPI might be parsing anonymous subroutines.>);
            }
        }
        else {
            pass(q<PPI might be parsing anonymous subroutines.>);
        }
    }
    else {
        pass(q<PPI might be parsing anonymous subroutines.>);
    }
}

{

    # PPI 1.206 correctly parses 'use constant { ONE => 1, TWO => 2 }' as a
    # PPI::Statement::Include consisting of two words followed by a
    # constructor. But it incorrectly parses 'use constant 1.16 { ONE => 1,
    # TWO => 2} as two words and a float followed by a block. We can remove
    # the test for 'PPI::Structure::Block' from
    # _constant_names_from_constant_pragma() in
    # Perl::Critic::PPIx::Utilities::Statement once this is fixed.

    my $code = 'use constant 1.16 { ONE => 1, TWO => 2 }';
    local $TODO = q<Clean up code in P::C::PPIx::Utilities::Statement::_constant_names_from_constant_pragma() once this test passes.>;

    my $doc = PPI::Document->new(\$code);

    my $stmt = $doc->schild(0);
    _test_class($stmt, 'PPI::Statement::Include') or last;

    my @kids = $stmt->schildren();
    _test_class($kids[-1], 'PPI::Structure::Constructor') or last;

    pass( qq<PPI returned a PPI::Structure::Constructor from '$code'> );

}

sub _test_class {
    my ($elem, $want) = @_;
    $elem->isa($want) and return 1;
    my $class = ref $elem;
    fail( qq<PPI returned a $class, not a $want> );
    return;
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
