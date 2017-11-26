#!perl

use 5.006001;
use strict;
use warnings;

use Test::More;

our $VERSION = '1.131_01';
use lib 't/bad_module';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

plan( tests => 1 );

use Perl::Critic::PolicyFactory (-test => 1);

my @policy_names = Perl::Critic::PolicyFactory::site_policy_names();

my $badpolicy = grep { $_ eq 'Perl::Critic::Policy::BogusPolicyNoNew' } @policy_names;
is($badpolicy, 0, 'site_policy_names excludes modules without new() function');


#-----------------------------------------------------------------------------
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
