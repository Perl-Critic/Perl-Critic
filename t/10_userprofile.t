#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 41;
use English qw(-no_match_vars);
use Perl::Critic::UserProfile;

#-----------------------------------------------------------------------------
# Create profile from hash

{
    my %policy_params = (keywords => 'Revision');
    my %profile_hash = ( '-NamingConventions::ProhibitMixedCaseVars' => {},
                         'Miscellanea::RequireRcsKeywords' => \%policy_params );

    my $up = Perl::Critic::UserProfile->new( -profile => \%profile_hash );

    #Using short policy names
    is($up->policy_is_enabled('Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Now using long policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Using bogus policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Bogus'),   q{} );
    is($up->policy_is_disabled('Perl::Critic::Policy::Bogus'),  q{} );
    is_deeply($up->policy_params('Perl::Critic::Policy::Bogus'), {} );
}

#-----------------------------------------------------------------------------
# Create profile from array

{
    my %policy_params = (keywords => 'Revision');
    my @profile_array = ( q{ [-NamingConventions::ProhibitMixedCaseVars] },
                          q{ [Miscellanea::RequireRcsKeywords]           },
                          q{ keywords = Revision                         },
    );


    my $up = Perl::Critic::UserProfile->new( -profile => \@profile_array );

    #Now using long policy names
    is($up->policy_is_enabled('Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Now using long policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Using bogus policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Bogus'),   q{} );
    is($up->policy_is_disabled('Perl::Critic::Policy::Bogus'),  q{} );
    is_deeply($up->policy_params('Perl::Critic::Policy::Bogus'), {} );
}

#-----------------------------------------------------------------------------
# Create profile from string

{
    my %policy_params = (keywords => 'Revision');
    my $profile_string = <<'END_PROFILE';
[-NamingConventions::ProhibitMixedCaseVars]
[Miscellanea::RequireRcsKeywords]
keywords = Revision
END_PROFILE

    my $up = Perl::Critic::UserProfile->new( -profile => \$profile_string );

    #Now using long policy names
    is($up->policy_is_enabled('Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Now using long policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), 1 );
    is($up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars'), 1 );
    is_deeply($up->policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), \%policy_params);

    #Using bogus policy names
    is($up->policy_is_enabled('Perl::Critic::Policy::Bogus'),   q{} );
    is($up->policy_is_disabled('Perl::Critic::Policy::Bogus'),  q{} );
    is_deeply($up->policy_params('Perl::Critic::Policy::Bogus'), {} );
}

#-----------------------------------------------------------------------------
# Test long policy names

{
       my %policy_params = (keywords => 'Revision');
       my $long_profile_string = <<'END_PROFILE';
[-Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars]
[Perl::Critic::Policy::Miscellanea::RequireRcsKeywords]
keywords = Revision
END_PROFILE

       my $up = Perl::Critic::UserProfile->new( -profile => \$long_profile_string );

       #Now using long policy names
       is($up->policy_is_enabled('Miscellanea::RequireRcsKeywords'), 1 );
       is($up->policy_is_disabled('NamingConventions::ProhibitMixedCaseVars'), 1 );
       is_deeply($up->policy_params('Miscellanea::RequireRcsKeywords'), \%policy_params);

       #Now using long policy names
       is($up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), 1 );
       is($up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars'), 1 );
       is_deeply($up->policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'), \%policy_params);

       #Using bogus policy names
       is($up->policy_is_enabled('Perl::Critic::Policy::Bogus'),   q{} );
       is($up->policy_is_disabled('Perl::Critic::Policy::Bogus'),  q{} );
       is_deeply($up->policy_params('Perl::Critic::Policy::Bogus'), {} );
   }

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $code_ref = sub { return };
    eval { Perl::Critic::UserProfile->new( -profile => $code_ref ) };
    like( $EVAL_ERROR, qr/Can't load UserProfile/, 'Invalid profile type');

    eval { Perl::Critic::UserProfile->new( -profile => 'bogus' ) };
    like( $EVAL_ERROR, qr/File 'bogus' does not exist/, 'Invalid profile path');

    my $invalid_syntax = '[Foo::Bar'; #Missing "]"
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like( $EVAL_ERROR, qr/Syntax error at line/, 'Invalid profile syntax');

    $invalid_syntax = 'severity 2'; #Missing "="
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like( $EVAL_ERROR, qr/Syntax error at line/, 'Invalid profile syntax');

}

#-----------------------------------------------------------------------------
# Test profile finding

{
    my $expected = $ENV{PERLCRITIC} = 'foo';
    my $got = Perl::Critic::UserProfile::_find_profile_path();
    is( $got, $expected, 'PERLCRITIC environment variable');
}

#-----------------------------------------------------------------------------

# ensure we run true if this test is loaded by
# t/10_userprofile.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
