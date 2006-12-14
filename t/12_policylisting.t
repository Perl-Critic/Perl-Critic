#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
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
my $listing = Perl::Critic::PolicyListing->new( -policies => \@pols );
my $policy_count = scalar @pols;
plan( tests => $policy_count + 1);

#-----------------------------------------------------------------------------
# These tests verify that the listing has the right number of lines (one per
# policy) and that each line matches the expected pattern.  This indirectly
# verifies that each core policy declares at least one theme.

my $listing_as_string = "$listing";
my @listing_lines = split /\n/, $listing_as_string;
my $line_count = scalar @listing_lines;
is( $line_count, $policy_count, qq{Listing has all $policy_count policies} );


my $listing_pattern = qr{\A\d [\w:]+ \[[\w\s]+\]\z};
for my $line ( @listing_lines ) {
    like($line, $listing_pattern, 'Listing format matches expected pattern');
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
