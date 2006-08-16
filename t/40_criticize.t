##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More;
use Perl::Critic::Config (-test => 1);

if ($ENV{PERL_CRITIC_CACHE}) {
    require File::Spec;
    require PPI::Cache;
    my $cache_path
        = File::Spec->catdir(File::Spec->tmpdir,
                             'test-perl-critic-cache-'.$ENV{USER});
    if ( ! -d $cache_path)
    {
        mkdir $cache_path, oct 700;
    }
    PPI::Cache->import(path => $cache_path);
}

eval {
    require Test::Perl::Critic;
    my @exclude = qw(RcsKeywords TidyCode PodSections);
    my $profile = {
        'CodeLayout::ProhibitHardTabs' => { allow_leading_tabs => 0 },
    };
    my %config = (-severity => 1, -exclude => \@exclude, -profile => $profile);
    Test::Perl::Critic->import( %config );
};

plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
