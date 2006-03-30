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
    my %config = (-severity => 1, -exclude => \@exclude, -profile => 'NONE');
    Test::Perl::Critic->import( %config );
};

plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok('lib', 'bin');
