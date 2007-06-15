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
use Test::More (tests => 66);

use Perl::Critic::TestUtils;
use Perl::Critic::PolicyFactory;
use Perl::Critic::UserProfile;
use Perl::Critic::Theme;

#-----------------------------------------------------------------------------

ILLEGAL_RULES:{

    my @invalid_rules = (
        '$cosmetic',
        '"cosmetic"',
        '#cosmetic > bugs',
        'cosmetic / bugs',
        'cosmetic % bugs',
        'cosmetic + [bugs - pbp]',
        'cosmetic + {bugs - pbp}',
        'cosmetic @ bugs ^ pbp',
    );

    for my $invalid ( @invalid_rules ) {
        eval { Perl::Critic::Theme::->new( -rule => $invalid ) };
        like( $EVAL_ERROR, qr/Illegal char/, qq{Invalid rule: "$invalid"});
    }
}

#-----------------------------------------------------------------------------

VALID_RULES:{

    my @valid_rules = (
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

    for my $valid ( @valid_rules ) {
        my $theme = Perl::Critic::Theme->new( -rule => $valid );
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
        my $cooked = Perl::Critic::Theme::cook_rule( $raw );
        is( $cooked, $expected, qq{Theme cooking: '$raw' -> '$cooked'});
    }
}


#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

{
    my $profile = Perl::Critic::UserProfile->new( -profile => q{} );
    my $factory = Perl::Critic::PolicyFactory->new( -profile => $profile );
    my @policy_names = Perl::Critic::PolicyFactory::site_policy_names();
    my @pols = map { $factory->create_policy( -name => $_ ) } @policy_names;

    #--------------

    my $rule = 'cosmetic';
    my $theme = Perl::Critic::Theme->new( -rule => $rule );
    my @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all { has_theme( $_, 'cosmetic' ) } @members );

    #--------------

    $rule = 'cosmetic - pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    $rule = 'cosmetic and not pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    $rule = 'cosmetic && ! pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) }  @pols;
    ok( all  { has_theme( $_, 'cosmetic' ) } @members );
    ok( none { has_theme( $_, 'pbp')       } @members );

    #--------------

    $rule = 'cosmetic + pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    $rule = 'cosmetic || pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    $rule = 'cosmetic or pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'cosmetic') ||
               has_theme($_, 'pbp') } @members );

    #--------------

    $rule = 'bugs * pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    $rule = 'bugs and pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    $rule = 'bugs && pbp';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'bugs')  } @members );
    ok( all  { has_theme($_, 'pbp')   } @members );

    #-------------

    $rule = 'pbp - (danger * security)';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    $rule = 'pbp and ! (danger and security)';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    $rule = 'pbp && not (danger && security)';
    $theme = Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    ok( all  { has_theme($_, 'pbp') } @members );
    ok( none { has_theme($_, 'danger') &&
               has_theme($_, 'security') } @members );

    #--------------

    $rule = 'bogus';
    $theme =  Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $rule = 'bogus - pbp';
    $theme =  Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, 0, 'bogus theme' );

    $rule = q{};
    $theme =  Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, scalar @pols, 'empty theme' );

    $rule = q{};
    $theme =  Perl::Critic::Theme->new( -rule => $rule );
    @members = grep { $theme->policy_is_thematic( -policy => $_) } @pols;
    is( scalar @members, scalar @pols, 'undef theme' );

    #--------------
    # Exceptions

    $rule = 'cosmetic *(';
    $theme =  Perl::Critic::Theme->new( -rule => $rule );
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
