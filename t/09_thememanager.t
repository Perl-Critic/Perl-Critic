#!perl

#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use List::MoreUtils qw(all any none);
use Perl::Critic::ThemeManager;
use Perl::Critic::PolicyFactory;
use Perl::Critic::UserProfile;
use Perl::Critic::Config;
use Test::More (tests => 42);

#-----------------------------------------------------------------------------

my @invalid_expressions = (
    '$cosmetic',
    '"cosmetic"',
    '#cosmetic > risky',
    'cosmetic / risky',
    'cosmetic % risky',
    'cosmetic + [risky - pbp]',
    'cosmetic + {risky - pbp}',
    'cosmetic && risky || pbp',
    'cosmetic @ risky ^ pbp',
);

for my $invalid ( @invalid_expressions ) {
    eval { Perl::Critic::ThemeManager::_validate_rule( $invalid ) };
    like( $EVAL_ERROR, qr/Illegal character/, qq{Invalid expression: "$invalid"} );
}

my @valid_expressions = (
    'cosmetic',
    'cosmetic + risky',
    'cosmetic - risky',
    'cosmetic + (risky - pbp)',
    'cosmetic+(risky-pbp)',
    'cosmetic or risky',
    'cosmetic and risky',
    'cosmetic and (risky and not pbp)',
);

for my $valid ( @valid_expressions ) {
    my $got = Perl::Critic::ThemeManager::_validate_rule( $valid );
    is( $got, 1, qq{Valid expression: "$valid"} );
}

#-----------------------------------------------------------------------------

{
    my %expressions = (
        'cosmetic' => 'cosmetic',
        'cosmetic + risky',           =>  'cosmetic + risky',
        'cosmetic - risky',           =>  'cosmetic - risky',
        'cosmetic + (risky - pbp)'    =>  'cosmetic + (risky - pbp)',
        'cosmetic+(risky-pbp)'        =>  'cosmetic+(risky-pbp)',
        'cosmetic or risky'           =>  'cosmetic + risky',
        'cosmetic and risky'          =>  'cosmetic * risky',
        'cosmetic and (risky or pbp)' =>  'cosmetic * (risky + pbp)',
    );

    while ( my ($raw, $expected) = each %expressions ) {
        my $cooked = Perl::Critic::ThemeManager::_translate_rule( $raw );
        is( $cooked, $expected, 'Theme translation');
    }
}

#-----------------------------------------------------------------------------

{
    my %expressions = (
         'cosmetic'                    =>  '$tmap{"cosmetic"}',
         'cosmetic + risky',           =>  '$tmap{"cosmetic"} + $tmap{"risky"}',
         'cosmetic * risky',           =>  '$tmap{"cosmetic"} * $tmap{"risky"}',
         'cosmetic - risky',           =>  '$tmap{"cosmetic"} - $tmap{"risky"}',
         'cosmetic + (risky - pbp)'    =>  '$tmap{"cosmetic"} + ($tmap{"risky"} - $tmap{"pbp"})',
         'cosmetic*(risky-pbp)'        =>  '$tmap{"cosmetic"}*($tmap{"risky"}-$tmap{"pbp"})',
    );

    while ( my ($raw, $expected) = each %expressions ) {
        my $cooked = Perl::Critic::ThemeManager::_interpolate_rule( $raw, 'tmap' );
        is( $cooked, $expected, 'Theme interpolation');
    }
}

#-----------------------------------------------------------------------------

{
    my $profile = Perl::Critic::UserProfile->new( -profile => q{} );
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    my @pols = $factory->policies();
    my %pmap = map { ref $_ => $_ } @pols; #Hashify class_name -> object


    my $tm = Perl::Critic::ThemeManager->new( -theme => 'cosmetic', -policies => \@pols );
    my @thematic_pols = $tm->thematic_policy_names();
    ok( all { in_theme($pmap{$_}, 'cosmetic') }  @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => 'cosmetic - pbp', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') } @thematic_pols );
    ok( none { in_theme($pmap{$_}, 'pbp')      } @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => 'cosmetic + pbp', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') ||
               in_theme($pmap{$_}, 'pbp') } @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => 'risky * pbp', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    ok( all  { in_theme($pmap{$_}, 'risky') } @thematic_pols );
    ok( all  { in_theme($pmap{$_}, 'pbp')      } @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => '-pbp', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    ok( none  { in_theme($pmap{$_}, 'pbp') } @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => 'pbp - (danger * security)', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    ok( all  { in_theme($pmap{$_}, 'pbp') } @thematic_pols );
    ok( none { in_theme($pmap{$_}, 'danger') &&
               in_theme($pmap{$_}, 'security') } @thematic_pols );

    $tm = Perl::Critic::ThemeManager->new( -theme => 'bogus', -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    is( scalar @thematic_pols, 0, 'bogus theme' );

    $tm = Perl::Critic::ThemeManager->new( -theme => q{}, -policies => \@pols );
    @thematic_pols = $tm->thematic_policy_names();
    is( scalar @thematic_pols, scalar @pols, 'empty theme' );

}

sub in_theme {
    my ($policy, $theme) = @_;
    return any{ $_ eq $theme } $policy->get_themes();
}
