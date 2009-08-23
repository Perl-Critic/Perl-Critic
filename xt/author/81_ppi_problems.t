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

use Test::More tests => 3;

#-----------------------------------------------------------------------------

our $VERSION = '1.104';

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


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
