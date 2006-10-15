#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 36;
use Perl::Critic::UserProfile;

# common P::C testing tools
use Perl::Critic::TestUtils qw();
Perl::Critic::TestUtils::block_perlcriticrc();

#--------------------------------------------------------------
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

#--------------------------------------------------------------
# Test config as array

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

#--------------------------------------------------------------
# Test config as string

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


#--------------------------------------------------------------
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
