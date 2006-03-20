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
    my @exclude = qw(Rcs Tidy PodSections);
    Test::Perl::Critic->import( -severity => 1, -exclude => \@exclude);
};

plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok('lib', 'bin');
