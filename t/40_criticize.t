##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import( -severity => 3 );
};

plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok('lib', 'bin');
