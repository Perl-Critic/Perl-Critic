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
    eval { Perl::Critic::ThemeManager::_validate_expression( $invalid ) };
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
    my $got = Perl::Critic::ThemeManager::_validate_expression( $valid );
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
        my $cooked = Perl::Critic::ThemeManager::_translate_expression( $raw );
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
        my $cooked = Perl::Critic::ThemeManager::_interpolate_expression( $raw, 'tmap' );
        is( $cooked, $expected, 'Theme interpolation');
    }
}

#-----------------------------------------------------------------------------

{
    my @pols = Perl::Critic::Config::native_policy_names();
    my $up   = Perl::Critic::UserProfile->new( -profile => q{} );
    my $pf   = Perl::Critic::PolicyFactory->new( -profile => $up, -policies => \@pols );
    my $tm   = Perl::Critic::ThemeManager->new( -policies => [ $pf->policies() ] );
    my %pmap = map { ref $_ => $_ } $pf->policies(); #Hashify class_name -> object


    my @thematic_pols = $tm->evaluate( 'cosmetic' );
    ok( all { in_theme($pmap{$_}, 'cosmetic') }  @thematic_pols );

    @thematic_pols = $tm->evaluate( 'cosmetic - pbp' );
    ok( all  { in_theme($pmap{$_}, 'cosmetic') } @thematic_pols );
    ok( none { in_theme($pmap{$_}, 'pbp')      } @thematic_pols );

    @thematic_pols =  $tm->evaluate( 'cosmetic + pbp' );
    ok( all  { in_theme($pmap{$_}, 'cosmetic') ||
               in_theme($pmap{$_}, 'pbp') } @thematic_pols );

    @thematic_pols = $tm->evaluate( 'risky * pbp' );
    ok( all  { in_theme($pmap{$_}, 'risky') } @thematic_pols );
    ok( all  { in_theme($pmap{$_}, 'pbp')      } @thematic_pols );

    @thematic_pols = $tm->evaluate( '-pbp' );
    ok( none  { in_theme($pmap{$_}, 'pbp') } @thematic_pols );

    @thematic_pols = $tm->evaluate( 'pbp - (danger * security)' );
    ok( all  { in_theme($pmap{$_}, 'pbp') } @thematic_pols );
    ok( none { in_theme($pmap{$_}, 'danger') &&
               in_theme($pmap{$_}, 'security') } @thematic_pols );

    @thematic_pols = $tm->evaluate( 'bogus' );
    is( scalar @thematic_pols, 0, 'bogus theme' );

    @thematic_pols = $tm->evaluate( q{} );
    is( scalar @thematic_pols, 0, 'empty theme' );

}

sub in_theme {
    my ($policy, $theme) = @_;
    return any{ $_ eq $theme } $policy->get_themes();
}
