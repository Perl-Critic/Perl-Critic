##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

#----------------------------------------------------------------#
# !!! WARNING: Do not distribute Perl::Critic with this file !!! #
#----------------------------------------------------------------#

use strict;
use warnings;
use Test::More;
use Test::Perl::Critic -profile => 't/samples/perlcriticrc';
all_critic_ok('lib', 'bin');