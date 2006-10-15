#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 7;
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
                                               -policies => [$policy_name] );


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
