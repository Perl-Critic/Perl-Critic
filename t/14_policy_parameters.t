#!perl

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/13_bundled_policies.t $
#     $Date: 2006-12-09 13:31:57 -0800 (Sat, 09 Dec 2006) $
#   $Author: chrisdolan $
# $Revision: 1056 $
##############################################################################

use strict;
use warnings;
use Test::More; #plan set below!
use English qw(-no_match_vars);
use Perl::Critic::UserProfile qw();
use Perl::Critic::PolicyFactory ( -test => 1 );
use Perl::Critic::TestUtils qw(bundled_policy_names);

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------
# This script just proves that each policy that ships with Perl::Critic
# overrides the policy_parameters() method.  It tries to create each Policy
# using the parameters that it claims to support, but it uses a dummy value
# for the parameter.  So this doesn't actually prove if we can create the
# Policy using the parameters that it claims to support.
#
# This script also verifies that Perl::Critic::PolicyFactory throws an
# exception when we try to create a policy with bogus parameters.  However, it
# is your responsibility to verify that valid parameters actually work as
# expected.  You can do this by using the #parms directive in the *.run files.
#
# When/if the individual policies start validating the value of the parameters
# that are passed in, these tests will fail.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_policies = bundled_policy_names();
my @all_params   = map { $_->policy_parameters() } @all_policies;
my $ntests       = @all_policies + @all_params;
plan( tests => $ntests );

#-----------------------------------------------------------------------------

for my $policy ( @all_policies ) {
    test_invalid_parameters( $policy );
    test_has_declared_parameters( $policy );
    test_supported_parameters( $policy );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $policy = shift;
    my @supported_params = $policy->policy_parameters();
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    for my $param_name ( @supported_params ) {
        my %args = ( -policy => $policy, -params => {$param_name => 'dummy'} );
        eval { $config->add_policy( %args ) };
        my $label = qq{Created policy "$policy" with param "$param_name"};
        is( $EVAL_ERROR, q{}, $label );
    }
}

#-----------------------------------------------------------------------------

sub test_invalid_parameters {
    my $policy = shift;
    my $profile = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    eval { $factory->create_policy( $policy, {bogus => 'shizzle'} ) };
    my $label = qq{Created $policy with bogus parameters};
    like( $EVAL_ERROR, qr/Parameter "bogus" isn't supported/, $label);
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $policy = shift;
    my @supported_params = $policy->policy_parameters();
    if ( !defined $supported_params[0] && @supported_params == 1) {
        fail( qq{I don't know if $policy supports params} );
        diag( qq{This means $policy needs a policy_parameters() method} );
        return;
    }
}

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
