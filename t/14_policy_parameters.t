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
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::PolicyParameter;
use Perl::Critic::TestUtils qw(bundled_policy_names);

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------
# This script proves that each policy that ships with Perl::Critic overrides
# the supported_parameters() method and, assuming that the policy is
# configurable, that each parameter can parse its own default_string.
#
# This script also verifies that Perl::Critic::PolicyFactory throws an
# exception when we try to create a policy with bogus parameters.  However, it
# is your responsibility to verify that valid parameters actually work as
# expected.  You can do this by using the #parms directive in the *.run files.
#-----------------------------------------------------------------------------

# Figure out how many tests there will be...
my @all_policies = bundled_policy_names();
my @all_params   = map { $_->supported_parameters() } @all_policies;
my $ntests       = @all_policies + 2 * @all_params;
plan( tests => $ntests );

#-----------------------------------------------------------------------------

for my $policy ( @all_policies ) {
    test_invalid_parameters( $policy );
    test_has_declared_parameters( $policy );
    test_supported_parameters( $policy );
}

#-----------------------------------------------------------------------------

sub test_supported_parameters {
    my $policy_name = shift;
    my @supported_params = $policy_name->supported_parameters();
    my $config = Perl::Critic::Config->new( -profile => 'NONE' );

    for my $param_specification ( @supported_params ) {
        my $parameter =
            Perl::Critic::PolicyParameter->new($param_specification);
        my $param_name = $parameter->get_name();

        is(
            ref $param_specification,
            'HASH',
            qq{Param "$param_name" for policy "$policy_name" specified as a hash},
        );

        my %args = (
            -policy => $policy_name,
            -params => {
                 $param_name => $parameter->get_default_string(),
            }
        );
        eval { $config->add_policy( %args ) };
        is(
            $EVAL_ERROR,
            q{},
            qq{Created policy "$policy_name" with param "$param_name"},
        );
    }
}

#-----------------------------------------------------------------------------

sub test_invalid_parameters {
    my $policy = shift;
    my $bogus_params  = { bogus => 'shizzle' };
    my $profile = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    eval { $factory->create_policy(-name => $policy, -params => $bogus_params) };
    my $label = qq{Created $policy with bogus parameters};
    like( $EVAL_ERROR, qr/Parameter "bogus" isn't supported/, $label);
}

#-----------------------------------------------------------------------------

sub test_has_declared_parameters {
    my $policy = shift;
    if ( not $policy->can('supported_parameters') ) {
        fail( qq{I don't know if $policy supports params} );
        diag( qq{This means $policy needs a supported_parameters() method} );
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
