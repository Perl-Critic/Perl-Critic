#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);

use Perl::Critic::Policy;
use Perl::Critic::PolicyParameter;

use Test::More tests => 28;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $policy;
my $values;

$specification =
    {
        name        => 'test',
        description => 'A string list parameter for testing',
        behavior    => 'string list',
    };


$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 0, q{no value, no default} );

$policy = Perl::Critic::Policy->new();
$config{test} = 'koyaanisqatsi';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 1, q{'koyaanisqatsi', no default} );
ok( $values->{koyaanisqatsi}, q{'koyaanisqatsi', no default} );

$policy = Perl::Critic::Policy->new();
$config{test} = 'powaqqatsi naqoyqatsi';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 2, q{'powaqqatsi naqoyqatsi', no default} );
ok( $values->{powaqqatsi}, q{'powaqqatsi naqoyqatsi', no default} );
ok( $values->{naqoyqatsi}, q{'powaqqatsi naqoyqatsi', no default} );


$specification->{default_string} = 'baraka chronos';
delete $config{test};

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 2, q{no value, default 'baraka chronos'} );
ok( $values->{baraka}, q{no value, default 'baraka chronos'} );
ok( $values->{chronos}, q{no value, default 'baraka chronos'} );

$policy = Perl::Critic::Policy->new();
$config{test} = 'akira';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 1, q{'akira', default 'baraka chronos'} );
ok( $values->{akira}, q{'akira', default 'baraka chronos'} );

$policy = Perl::Critic::Policy->new();
$config{test} = 'downfall murderball';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is( scalar( keys %{$values} ), 2, q{'downfall murderball', default 'baraka chronos'} );
ok( $values->{downfall}, q{'downfall murderball', default 'baraka chronos'} );
ok( $values->{murderball}, q{'downfall murderball', default 'baraka chronos'} );


$specification->{default_string} = 'chainsuck snog';
$specification->{list_always_present_values} =
    [ 'leaether strip', 'front line assembly' ];
delete $config{test};

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is(
    scalar( keys %{$values} ),
    4,
    q{no value, default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{chainsuck},
    q{no value, default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{snog},
    q{no value, default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'leaether strip'},
    q{no value, default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'front line assembly'},
    q{no value, default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);

$policy = Perl::Critic::Policy->new();
$config{test} = 'pig';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is(
    scalar( keys %{$values} ),
    3,
    q{'pig', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{pig},
    q{'pig', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'leaether strip'},
    q{'pig', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'front line assembly'},
    q{'pig', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);

$policy = Perl::Critic::Policy->new();
$config{test} = 'microdisney foetus';
$parameter->parse_and_validate_config_value($policy, \%config);
$values = $policy->{_test};
is(
    scalar( keys %{$values} ),
    4,
    q{'microdisney foetus', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{microdisney},
    q{'microdisney foetus', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{foetus},
    q{'microdisney foetus', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'leaether strip'},
    q{'microdisney foetus', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);
ok(
    $values->{'front line assembly'},
    q{'microdisney foetus', default 'chainsuck snog', always 'leaether strip' & 'front line assembly'}
);

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
