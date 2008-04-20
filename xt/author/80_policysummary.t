#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use File::Spec;
use Test::More;
use List::MoreUtils qw(any);

use Perl::Critic::PolicyFactory ( -test => 1 );
use Perl::Critic::TestUtils qw{ bundled_policy_names };

#-----------------------------------------------------------------------------

if (open my ($fh), '<', File::Spec->catfile(qw(lib Perl Critic PolicySummary.pod))) {

    my $content = do {local $/=undef; <$fh> };
    close $fh;

    my @policy_names = bundled_policy_names();
    my @summaries    = $content =~ m/^=head2 [ ]+ L<([\w:]+)>/gxms;
    plan( tests => 2 + 2 * @policy_names );

    my %num_summaries;
    for my $summary (@summaries) {
        ++$num_summaries{$summary};
    }
    if (!ok(@summaries == keys %num_summaries, 'right number of summaries')) {
        for my $policy_name (sort keys %num_summaries) {
            next if 1 == $num_summaries{$policy_name};
            diag('Duplicate summary for ' . $policy_name);
        }
    }

    my $profile = Perl::Critic::UserProfile->new();
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    my %found_policies = map { ref $_ => $_ } $factory->create_all_policies();

    my %descriptions = $content =~ m/^=head2 [ ]+ L<([\w:]+)>\n\n([^\n]+)/gxms;
    for my $policy_name (keys %descriptions) {
        $descriptions{$policy_name} =~ s/[ ] \[Severity [ ] (\d+)\]//xms;
        my $severity = $1;
        $descriptions{$policy_name} = {
                                       desc => $descriptions{$policy_name},
                                       severity => $severity,
                                      };
    }

    for my $policy_name ( @policy_names ) {
        my $label = qq{PolicySummary.pod has "$policy_name"};
        my $has_summary = delete $num_summaries{$policy_name};
        is( $has_summary, 1, $label );

        my $summary_severity = $descriptions{$policy_name}->{severity};
        my $real_severity = $found_policies{$policy_name} &&
          $found_policies{$policy_name}->default_severity;
        is( $summary_severity, $real_severity, "severity for $policy_name" );
    }

    if (!ok(0 == keys %num_summaries, 'no extra summaries')) {
        for my $policy_name (sort keys %num_summaries) {
            diag('Extraneous summary for ' . $policy_name);
        }
    }
}
else {
    fail 'Cannot locate the PolicySummary.pod file';
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/80_policysummary.t.without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
