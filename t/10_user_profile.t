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

use Test::More tests => 41;

#-----------------------------------------------------------------------------

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

# Create profile from hash

{
    my %policy_params = (keywords => 'Revision');
    my %profile_hash = ( '-NamingConventions::Capitalization' => {},
                         'Miscellanea::RequireRcsKeywords' => \%policy_params );

    my $up = Perl::Critic::UserProfile->new( -profile => \%profile_hash );

    # Using short policy names
    is(
        $up->policy_is_enabled('Miscellanea::RequireRcsKeywords'),
        1,
        'Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        1,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Policy::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Bogus'),
        {},
        q<Bogus Policy doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from array

{
    my %policy_params = (keywords => 'Revision');
    my @profile_array = ( q{ [-NamingConventions::Capitalization] },
                          q{ [Miscellanea::RequireRcsKeywords]           },
                          q{ keywords = Revision                         },
    );


    my $up = Perl::Critic::UserProfile->new( -profile => \@profile_array );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Miscellanea::RequireRcsKeywords'),
        1,
        'Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        1,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Policy::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Bogus'),
        {},
        q<Bogus Policy doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Create profile from string

{
    my %policy_params = (keywords => 'Revision');
    my $profile_string = <<'END_PROFILE';
[-NamingConventions::Capitalization]
[Miscellanea::RequireRcsKeywords]
keywords = Revision
END_PROFILE

    my $up = Perl::Critic::UserProfile->new( -profile => \$profile_string );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Miscellanea::RequireRcsKeywords'),
        1,
        'Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        1,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Policy::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Bogus'),
        {},
        q<Bogus Policy doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test long policy names

{
    my %policy_params = (keywords => 'Revision');
    my $long_profile_string = <<'END_PROFILE';
[-Perl::Critic::Policy::NamingConventions::Capitalization]
[Perl::Critic::Policy::Miscellanea::RequireRcsKeywords]
keywords = Revision
END_PROFILE

    my $up = Perl::Critic::UserProfile->new( -profile => \$long_profile_string );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Miscellanea::RequireRcsKeywords'),
        1,
        'Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('NamingConventions::Capitalization'),
        1,
        'NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Now using long policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        1,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords is enabled.',
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::NamingConventions::Capitalization'),
        1,
        'Perl::Critic::Policy::NamingConventions::Capitalization is disabled.',
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Miscellanea::RequireRcsKeywords'),
        \%policy_params,
        'Perl::Critic::Policy::Miscellanea::RequireRcsKeywords got the correct configuration.',
    );

    # Using bogus policy names
    is(
        $up->policy_is_enabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't enabled>,
    );
    is(
        $up->policy_is_disabled('Perl::Critic::Policy::Bogus'),
        q{},
        q<Bogus Policy isn't disabled>,
    );
    is_deeply(
        $up->raw_policy_params('Perl::Critic::Policy::Bogus'),
        {},
        q<Bogus Policy doesn't have any configuration.>,
    );
}

#-----------------------------------------------------------------------------
# Test exception handling

{
    my $code_ref = sub { return };
    eval { Perl::Critic::UserProfile->new( -profile => $code_ref ) };
    like(
        $EVAL_ERROR,
        qr/Can't [ ] load [ ] UserProfile/xms,
        'Invalid profile type',
    );

    eval { Perl::Critic::UserProfile->new( -profile => 'bogus' ) };
    like(
        $EVAL_ERROR,
        qr/File [ ] 'bogus' [ ] does [ ] not [ ] exist/xms,
        'Invalid profile path',
    );

    my $invalid_syntax = '[Foo::Bar'; # Missing "]"
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

    $invalid_syntax = 'severity 2'; # Missing "="
    eval { Perl::Critic::UserProfile->new( -profile => \$invalid_syntax ) };
    like(
        $EVAL_ERROR,
        qr/Syntax [ ] error [ ] at [ ] line/xms,
        'Invalid profile syntax',
    );

}

#-----------------------------------------------------------------------------
# Test profile finding

{
    my $expected = local $ENV{PERLCRITIC} = 'foo';
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
