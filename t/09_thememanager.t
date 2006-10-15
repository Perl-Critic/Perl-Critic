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
use Perl::Critic::ThemeManager;
use Perl::Critic::Config (-test => 1);
use Test::More (tests => 31);

#-----------------------------------------------------------------------------

my @invalid_requests = (
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

for my $invalid ( @invalid_requests ) {
    eval { Perl::Critic::ThemeManager::_validate_request( $invalid ) };
    like( $EVAL_ERROR, qr/Illegal character/, qq{Invalid request: "$invalid"} );
}

my @valid_requests = (
    'cosmetic',
    'cosmetic + risky',
    'cosmetic - risky',
    'cosmetic + (risky - pbp)',
    'cosmetic+(risky-pbp)',
    'cosmetic or risky',
    'cosmetic and risky',
    'cosmetic and (risky and not pbp)',
);

for my $valid ( @valid_requests ) {
    my $rc = eval { Perl::Critic::ThemeManager::_validate_request( $valid ) };
    is( $rc, 1, qq{Valid request: "$valid"} );
}

#-----------------------------------------------------------------------------

{
    my %requests = (
        'cosmetic' => 'cosmetic',
        'cosmetic + risky',           =>  'cosmetic + risky',
        'cosmetic - risky',           =>  'cosmetic - risky',
        'cosmetic + (risky - pbp)'    =>  'cosmetic + (risky - pbp)',
        'cosmetic+(risky-pbp)'        =>  'cosmetic+(risky-pbp)',
        'cosmetic or risky'           =>  'cosmetic + risky',
        'cosmetic and risky'          =>  'cosmetic * risky',
        'cosmetic and (risky or pbp)' =>  'cosmetic * (risky + pbp)',
    );

    while ( my ($raw, $expected) = each %requests ) {
        my $cooked = Perl::Critic::ThemeManager::_translate_request( $raw );
        is( $cooked, $expected, 'Theme translation');
    }
}

#-----------------------------------------------------------------------------

{
    my %requests = (
         'cosmetic'                    =>  '$tmap{"cosmetic"}',
         'cosmetic + risky',           =>  '$tmap{"cosmetic"} + $tmap{"risky"}',
         'cosmetic * risky',           =>  '$tmap{"cosmetic"} * $tmap{"risky"}',
         'cosmetic - risky',           =>  '$tmap{"cosmetic"} - $tmap{"risky"}',
         'cosmetic + (risky - pbp)'    =>  '$tmap{"cosmetic"} + ($tmap{"risky"} - $tmap{"pbp"})',
         'cosmetic*(risky-pbp)'        =>  '$tmap{"cosmetic"}*($tmap{"risky"}-$tmap{"pbp"})',
    );

    while ( my ($raw, $expected) = each %requests ) {
        my $cooked = Perl::Critic::ThemeManager::_interpolate_request( $raw, 'tmap' );
        is( $cooked, $expected, 'Theme interpolation');
    }
}

#-----------------------------------------------------------------------------


