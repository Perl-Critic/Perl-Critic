#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::UserProfile;
use Perl::Critic::PolicyFactory (-test => 1);
use Perl::Critic::TestUtils qw();

use Test::More tests => 10;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------

{
    my $policy_name = 'Perl::Critic::Policy::Modules::ProhibitEvilModules';
    my $params = {severity => 2, set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );


    # Now test...
    my $policy = $pf->create_policy( -name => $policy_name, -params => $params );
    is( ref $policy, $policy_name, 'Created correct type of policy');

    my $severity = $policy->get_severity();
    is( $severity, 2, 'Set the severity');

    my @themes = $policy->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Using short module name.
{
    my $policy_name = 'Variables::ProhibitPunctuationVars';
    my $params = {set_themes => 'betty', add_themes => 'wilma'};

    my $userprof = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );


    # Now test...
    my $policy = $pf->create_policy( -name => $policy_name, -params => $params );
    my $policy_name_long = 'Perl::Critic::Policy::' . $policy_name;
    is( ref $policy, $policy_name_long, 'Created correct type of policy');

    my @themes = $policy->get_themes();
    is_deeply( \@themes, [ qw(betty wilma) ], 'Set the theme');
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $userprof = Perl::Critic::UserProfile->new( -profile => 'NONE' );
    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );

    # Try missing arguments
    eval{ $pf->create_policy() };
    like(
        $EVAL_ERROR,
        qr/The [ ] -name [ ] argument/xms,
        'create without -name arg',
    );

    # Try creating bogus policy
    eval{ $pf->create_policy( -name => 'Perl::Critic::Foo' ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] locate [ ] object [ ] method/xms,
        'create bogus policy',
    );

    # Try using a bogus severity level
    my $policy_name = 'Modules::RequireVersionVar';
    my $policy_params = {severity => 'bogus'};
    eval{ $pf->create_policy( -name => $policy_name, -params => $policy_params)};
    like(
        $EVAL_ERROR,
        qr/Invalid [ ] severity: [ ] "bogus"/xms,
        'create policy w/ bogus severity',
    );
}

#-----------------------------------------------------------------------------
# Test warnings about bogus policies

{
    my $last_warning = q{}; #Trap warning messages here
    local $SIG{__WARN__} = sub { $last_warning = shift };

    my $profile = { 'Perl::Critic::Bogus' => {} };
    my $userprof = Perl::Critic::UserProfile->new( -profile => $profile );
    my $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Policy [ ] ".*Bogus" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for positive configuration of Policy.',
    );
    $last_warning = q{};

    $profile = { '-Perl::Critic::Shizzle' => {} };
    $userprof = Perl::Critic::UserProfile->new( -profile => $profile );
    $pf = Perl::Critic::PolicyFactory->new( -profile  => $userprof );
    like(
        $last_warning,
        qr/^Policy [ ] ".*Shizzle" [ ] is [ ] not [ ] installed/xms,
        'Got expected warning for negative configuration of Policy.',
    );
    $last_warning = q{};
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/11_policyfactory.t_without_optional_dependencies.t
1;

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
