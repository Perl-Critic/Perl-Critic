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
use List::MoreUtils qw(any all none);
use Perl::Critic::PolicyFactory;
use Perl::Critic::UserProfile;
use Perl::Critic::Theme;
use Test::More (tests => 66);

#-----------------------------------------------------------------------------

ILLEGAL_MODELS:{

    my @invalid_models = (
        '$cosmetic',
        '"cosmetic"',
        '#cosmetic > bugs',
        'cosmetic / bugs',
        'cosmetic % bugs',
        'cosmetic + [bugs - pbp]',
        'cosmetic + {bugs - pbp}',
        'cosmetic @ bugs ^ pbp',
    );

    for my $invalid ( @invalid_models ) {
        eval { Perl::Critic::Theme::->new( -model => $invalid ) };
        like( $EVAL_ERROR, qr/Illegal char/, qq{Invalid model: "$invalid"});
    }
}

#-----------------------------------------------------------------------------

VALID_MODELS:{

    my @valid_models = (
        'cosmetic',
        '!cosmetic',
        '-cosmetic',
        'not cosmetic',

        'cosmetic + bugs',
        'cosmetic - bugs',
        'cosmetic + (bugs - pbp)',
        'cosmetic+(bugs-pbp)',

        'cosmetic || bugs',
        'cosmetic && bugs',
        'cosmetic || (bugs - pbp)',
        'cosmetic||(bugs-pbp)',

        'cosmetic or bugs',
        'cosmetic and bugs',
        'cosmetic or (bugs not pbp)',
    );

    for my $valid ( @valid_models ) {
        my $theme = Perl::Critic::Theme->new( -model => $valid );
        ok( $theme, qq{Valid expression: "$valid"} );
    }
}

#-----------------------------------------------------------------------------

TRANSLATIONS:
{
    my %expressions = (
        'cosmetic'                     =>  'cosmetic',
        '!cosmetic'                    =>  '!cosmetic',
        '-cosmetic'                    =>  '!cosmetic',
        'not cosmetic'                 =>  '! cosmetic',
        'cosmetic + bugs',             =>  'cosmetic || bugs',
        'cosmetic - bugs',             =>  'cosmetic && ! bugs',
        'cosmetic + (bugs - pbp)'      =>  'cosmetic || (bugs && ! pbp)',
        'cosmetic+(bugs-pbp)'          =>  'cosmetic||(bugs&& !pbp)',
        'cosmetic or bugs'             =>  'cosmetic || bugs',
        'cosmetic and bugs'            =>  'cosmetic && bugs',
        'cosmetic and (bugs or pbp)'   =>  'cosmetic && (bugs || pbp)',
        'cosmetic + bugs'              =>  'cosmetic || bugs',
        'cosmetic * bugs'              =>  'cosmetic && bugs',
        'cosmetic * (bugs + pbp)'      =>  'cosmetic && (bugs || pbp)',
        'cosmetic || bugs',            =>  'cosmetic || bugs',
        '!cosmetic && bugs',           =>  '!cosmetic && bugs',
        'cosmetic && not (bugs or pbp)'=>  'cosmetic && ! (bugs || pbp)'
    );

    while ( my ($raw, $expected) = each %expressions ) {
        my $cooked = Perl::Critic::Theme::_cook_model( $raw );
        is( $cooked, $expected, qq{Theme cooking: '$raw' -> '$cooked'});
    }
}


#-----------------------------------------------------------------------------

{
    my $profile = Perl::Critic::UserProfile->new( -profile => q{} );
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    my @policy_names = Perl::Critic::PolicyFactory::site_policy_names();
    my @pols = map { $factory->create_policy( -name => $_ ) } @policy_names;

    #--------------

    my $model = 'cosmetic';
    my $theme = Perl::Critic::Theme->new( -model => $model );
    my @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all { has_theme( $_, 'cosmetic' ) } @members );

    #--------------

    $model = 'cosmetic - pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    $model = 'cosmetic and not pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    $model = 'cosmetic && ! pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    #--------------

    $model = 'cosmetic + pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    $model = 'cosmetic || pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    $model = 'cosmetic or pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    #--------------

    $model = 'bugs * pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    $model = 'bugs and pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    $model = 'bugs && pbp';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    #-------------

    $model = 'pbp - (danger * security)';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    $model = 'pbp and ! (danger and security)';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    $model = 'pbp && not (danger && security)';
    $theme = Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    #--------------

    $model = 'bogus';
    $theme =  Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $model = 'bogus - pbp';
    $theme =  Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $model = q{};
    $theme =  Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, scalar @pols, 'empty theme' );

    $model = q{};
    $theme =  Perl::Critic::Theme->new( -model => $model );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, scalar @pols, 'undef theme' );

    #--------------
    # Exceptions

    $model = 'cosmetic *(';
    $theme =  Perl::Critic::Theme->new( -model => $model );
    eval{ $theme->policy_is_thematic( -policy => $pols[0] ) };
    like( $EVAL_ERROR, qr/Syntax error/, 'invalid theme expression' );

}

#-----------------------------------------------------------------------------

sub has_theme {
    my ($policy, $theme) = @_;
    return any { $_ eq $theme } $policy->get_themes();
}

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
