#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use List::MoreUtils qw(all any none);
use Perl::Critic::Theme;
use Perl::Critic::PolicyFactory;
use Perl::Critic::UserProfile;
use Perl::Critic::Config;
use Test::More (tests => 53);

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
    eval { Perl::Critic::Theme::_validate_expression( $invalid ) };
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
    my $got = Perl::Critic::Theme::_validate_expression( $valid );
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
        my $cooked = Perl::Critic::Theme::_translate_expression( $raw );
        is( $cooked, $expected, 'Theme translation');
    }
}

#-----------------------------------------------------------------------------

{
    my %expressions = (
         'cosmetic'                 =>  '$tmap{"cosmetic"}',
         'cosmetic + risky',        =>  '$tmap{"cosmetic"} + $tmap{"risky"}',
         'cosmetic * risky',        =>  '$tmap{"cosmetic"} * $tmap{"risky"}',
         'cosmetic - risky',        =>  '$tmap{"cosmetic"} - $tmap{"risky"}',
         'cosmetic + (risky - pbp)' =>  '$tmap{"cosmetic"} + ($tmap{"risky"} - $tmap{"pbp"})',
         'cosmetic*(risky-pbp)'     =>  '$tmap{"cosmetic"}*($tmap{"risky"}-$tmap{"pbp"})',
    );

    while ( my ($raw, $expected) = each %expressions ) {
        my $cooked = Perl::Critic::Theme::_interpolate_expression($raw,'tmap');
        is( $cooked, $expected, 'Theme interpolation');
    }
}

#-----------------------------------------------------------------------------

{
    my $prof = Perl::Critic::UserProfile->new( -profile => q{} );
    my @pols = Perl::Critic::PolicyFactory->new( -profile => $prof )->policies();
    my %pmap = map { ref $_ => $_ } @pols; #Hashify class_name -> object


    my $theme = 'cosmetic';
    my %args = (-theme => $theme, -policies => \@pols);
    my @members = Perl::Critic::Theme->new( %args )->members();
    ok( all { in_theme($pmap{$_}, 'cosmetic') }  @members );

    #--------------

    $theme = 'cosmetic - pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') } @members );
    ok( none { in_theme($pmap{$_}, 'pbp')      } @members );

    $theme = 'cosmetic not pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') } @members );
    ok( none { in_theme($pmap{$_}, 'pbp')      } @members );

    #--------------

    $theme = 'cosmetic + pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') ||
               in_theme($pmap{$_}, 'pbp') } @members );

    $theme = 'cosmetic or pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'cosmetic') ||
               in_theme($pmap{$_}, 'pbp') } @members );

    #--------------

    $theme = 'risky * pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'risky') } @members );
    ok( all  { in_theme($pmap{$_}, 'pbp')   } @members );

    $theme = 'risky and pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'risky') } @members );
    ok( all  { in_theme($pmap{$_}, 'pbp')   } @members );

    #--------------

    $theme = '-pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( none  { in_theme($pmap{$_}, 'pbp') } @members );

    $theme = 'not pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( none  { in_theme($pmap{$_}, 'pbp') } @members );

    #--------------

    $theme = 'pbp - (danger * security)';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'pbp') } @members );
    ok( none { in_theme($pmap{$_}, 'danger') &&
               in_theme($pmap{$_}, 'security') } @members );

    $theme = 'pbp not (danger and security)';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    ok( all  { in_theme($pmap{$_}, 'pbp') } @members );
    ok( none { in_theme($pmap{$_}, 'danger') &&
               in_theme($pmap{$_}, 'security') } @members );

    #--------------

    $theme = 'bogus';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    is( scalar @members, 0, 'bogus theme' );

    $theme = 'bogus - pbp';
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    is( scalar @members, 0, 'bogus theme' );

    $theme = q{};
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    is( scalar @members, scalar @pols, 'empty theme' );

    $theme = undef;
    %args  = (-theme => $theme, -policies => \@pols);
    @members = Perl::Critic::Theme->new( %args )->members();
    is( scalar @members, scalar @pols, 'undef theme' );

    #--------------
    # Exceptions

    $theme = 'cosmetic *(';
    %args  = (-theme => $theme, -policies => \@pols);
    eval{ Perl::Critic::Theme->new( %args )->members() };
    like( $EVAL_ERROR, qr/Invalid theme/, 'invalid theme expression' );

}

sub in_theme {
    my ($policy, $theme) = @_;
    return any{ $_ eq $theme } $policy->get_themes();
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
