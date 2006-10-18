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
use List::MoreUtils qw(any);
use Perl::Critic::PolicyFactory ( -test => 1 );

#-----------------------------------------------------------------------------

if (!$ENV{TEST_AUTHOR}) {
    plan skip_all => 'Author test';
}


if (open my ($fh), '<', File::Spec->catfile(qw(lib Perl Critic PolicySummary.pod))) {

    my @policy_names = Perl::Critic::PolicyFactory::native_policy_names();
    my @summaries    = map { m/^=head2 [ ]+ L<([\w:]+)>/mx } <$fh>;
    plan( tests => scalar @policy_names );

    for my $policy_name ( @policy_names ) {
        my $label = qq{PolicySummary.pod has "$policy_name"};
        ok( any{ $_ eq $policy_name } @summaries, $label );
    }
}
else {
    fail 'Cannot locate the PolicySummary.pod file';
}
