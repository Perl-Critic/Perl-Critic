#!perl

use 5.006001;
use strict;
use warnings;

use Perl::Critic::UserProfile;
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::ThemeListing;

use Test::More tests => 1;

our $VERSION = '1.140';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

my $profile = Perl::Critic::UserProfile->new( -profile => 'NONE' );
my @policy_names = Perl::Critic::PolicyFactory::site_policy_names();
my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
my @policies = map { $factory->create_policy( -name => $_ ) } @policy_names;
my $listing = Perl::Critic::ThemeListing->new( -policies => \@policies );

my $expected = <<'END_EXPECTED';
bugs
certrec
certrule
complexity
core
cosmetic
maintenance
pbp
performance
portability
readability
security
tests
unicode
END_EXPECTED

my $listing_as_string = "$listing";
is( $listing_as_string, $expected, 'Theme list matched.' );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
