#!perl

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################


use strict;
use warnings;
use File::Spec;
use Test::More;
use Perl::Critic::Config ( -test => 1 );

#-----------------------------------------------------------------------------

if (!$ENV{TEST_AUTHOR}) {
    plan skip_all => 'Author test';
}

plan tests => 1;

if (open my ($fh), '<', File::Spec->catfile(qw(lib Perl Critic PolicySummary.pod))) {
    my @policies = Perl::Critic::Config::site_policies();
    local $/ = undef;
    my @summaries = <$fh> =~ m/^=head2 [ ]+ L<([\w\:]+)>/gmx;
    is_deeply [sort @summaries], [sort @policies], 'PolicySummary.pod contains all policies';
}
else {
    fail 'Cannot locate the PolicySummary.pod file';
}
