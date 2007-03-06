#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use Test::More; #plan set below

use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::Document;
use Perl::Critic;

use PPI::Document;

use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

eval 'use Test::Memory::Cycle'; ## no critic
plan( skip_all => 'Test::Memory::Cycle requried to test memory leaks') if $@;

#-----------------------------------------------------------------------------
{

    # We have to create and test Perl::Critic::Document for memory leaks
    # separately because it is not a persistent attribute of the Perl::Critic
    # object.  The current API requires us to creeate the P::C::Document from
    # an instance of an existing PPI::Document.  In the future, I hope to make
    # that interface a little more opaque.  But this works for now.

    # Coincidentally, I've discovered that PPI::Documents may or many not
    # contain circular references, depending on the input code.  On some
    # level, I'm sure this makes perfect sense, but I haven't stopped to think
    # about it.  The particular input we use here does not seem to create
    # circular references.

    my $code    = q{print foo(); split /this/, $that;};
    my $ppi_doc = PPI::Document->new( \$code );
    my $pc_doc  = Perl::Critic::Document->new( $ppi_doc );
    my $critic  = Perl::Critic->new( -severity => 1 );
    my @violations = $critic->critique( $pc_doc );
    die "No violations were created" if not @violations;

    # One test for each violation, plus one each for Critic and Document.
    plan( tests => scalar @violations + 2 );

    memory_cycle_ok( $pc_doc );
    memory_cycle_ok( $critic );
    memory_cycle_ok($_) for @violations;
}

#-----------------------------------------------------------------------------


###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
