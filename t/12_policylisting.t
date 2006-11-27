#!perl

##############################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/11_policyfactory.t $
#    $Date: 2006-11-18 15:48:03 -0800 (Sat, 18 Nov 2006) $
#   $Author: clonezone $
# $Revision: 878 $
##############################################################################

use strict;
use warnings;
use English qw(-no_mactch_vars);
use Test::More;
use Perl::Critic::UserProfile;
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::PolicyListing;

#-----------------------------------------------------------------------------

my $prof = Perl::Critic::UserProfile->new( -profile => 'NONE' );
my @pols = Perl::Critic::PolicyFactory->new( -profile => $prof )->policies();
my $list = Perl::Critic::PolicyListing->new( -policies => \@pols );
my $count = scalar @pols;
plan( tests => ($count * 2) + 2);

#-----------------------------------------------------------------------------

is( scalar $list->short_listing(), $count, 'Short listing has all policies');
is( scalar $list->long_listing(), $count, 'Long listing has all policies');

#-----------------------------------------------------------------------------

my $short_pattern = qr{^\d [\w:]+ \[[\w\s]+\]$};
for my $policy ( $list->short_listing() ) {
    like($policy, $short_pattern, 'Short listing format');
}

#-----------------------------------------------------------------------------

my $pname        = qr{\[[\w:]+\]};
my $set_theme    = qr{set_themes = [\w\s]+};
my $severity     = qr{severity   = \d};
my $long_pattern = qr{$pname\n$set_theme\n$severity\n\n};
for my $policy ( $list->long_listing() ) {
    like($policy, $long_pattern, 'Long listing format');
}


#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
