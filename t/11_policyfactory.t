#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use English qw(-no_mactch_vars);
use Test::More tests => 8;
use Perl::Critic::UserProfile;
use Perl::Critic::PolicyFactory;

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

{
    my $policy_name = 'Perl::Critic::Policy::CodeLayout::RequireTidyCode';
    my $params = {severity => 5, set_themes => 'foo bar', add_themes => 'bar baz'};
    my $profile  = {$policy_name => $params};
    my $userprof = Perl::Critic::UserProfile->new( -profile => $profile );

    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof,
                                               -policy_names => [$policy_name] );


    # Now test...
    my @policies = $pf->policies();
    is( scalar @policies, 1, 'Created 1 policy');

    my $policy = $policies[0];
    is( ref $policy, $policy_name, 'Created correct type of policy');

    my $severity = $policy->get_severity();
    is( $severity, 5, 'Set the severity');

    my @themes = $policy->get_themes();
    is_deeply( \@themes, [ qw(bar baz foo) ], 'Set the theme');
}

#-----------------------------------------------------------------------------

{
    my $policy_name = 'Perl::Critic::Policy::Modules::ProhibitEvilModules';
    my $params = {severity => 2, set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );


    # Now test...
    my $policy = $pf->create_policy( $policy_name, $params );
    is( ref $policy, $policy_name, 'Created correct type of policy');

    my $severity = $policy->get_severity();
    is( $severity, 2, 'Set the severity');

    my @themes = $policy->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Test exception handling

TODO:{

    # Try loading from bogus namespace
    local $TODO = 'Test not working yet';
    $Perl::Critic::Utils::POLICY_NAMESPACE = 'bogus';
    eval { Perl::Critic::PolicyFactory->import() };
    like( $EVAL_ERROR, qr/No Policies found/, 'loading from bogus namespace' );

}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab
