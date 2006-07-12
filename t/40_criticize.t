##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More;
use Perl::Critic::Config (-test => 1);

eval {
    require Test::Perl::Critic;
    my @exclude = qw(RcsKeywords TidyCode PodSections);
    my %config = (-severity => 1, -exclude => \@exclude, -profile => q{} );
    Test::Perl::Critic->import( %config );
};

plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
