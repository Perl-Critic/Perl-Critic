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
use Perl::Critic::Utils qw{ :booleans };

use Test::More tests => 22;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

my $specification;
my $parameter;
my %config;
my $policy;

$specification =
    {
        name        => 'test',
        description => 'An integer parameter for testing',
        behavior    => 'integer',
    };


$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
is($policy->{_test}, undef, q{no value, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '2943';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 2943, q{2943, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '+2943';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 2943, q{+2943, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '-2943';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, -2943, q{-2943, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '29_43';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 2943, q{29_43, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '+29_43';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 2943, q{+29_43, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '-29_43';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, -2943, q{-29_43, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 0, q{0, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = '1.5';
eval { $parameter->parse_and_validate_config_value($policy, \%config); };
ok($EVAL_ERROR, q{not an integer});


$specification->{default_string} = '0';
delete $config{test};

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 0, q{no value, default 0});

$policy = Perl::Critic::Policy->new();
$config{test} = '5';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 5, q{5, default 0});


$specification->{integer_minimum} = 0;

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$config{test} = '5';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 5, q{5, minimum 0});

$policy = Perl::Critic::Policy->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 0, q{0, minimum 0});

$policy = Perl::Critic::Policy->new();
$config{test} = '-5';
eval { $parameter->parse_and_validate_config_value($policy, \%config); };
ok($EVAL_ERROR, q{below minimum});


delete $specification->{integer_minimum};
$specification->{integer_maximum} = 0;

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$config{test} = '-5';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, -5, q{-5, maximum 0});

$policy = Perl::Critic::Policy->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 0, q{0, maximum 0});

$policy = Perl::Critic::Policy->new();
$config{test} = '5';
eval { $parameter->parse_and_validate_config_value($policy, \%config); };
ok($EVAL_ERROR, q{above maximum});


$specification->{integer_minimum} = 0;
$specification->{integer_maximum} = 5;

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$config{test} = '-5';
eval { $parameter->parse_and_validate_config_value($policy, \%config); };
ok($EVAL_ERROR, q{below minimum of range});

$policy = Perl::Critic::Policy->new();
$config{test} = '0';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 0, q{0, minimum 0, maximum 5});

$policy = Perl::Critic::Policy->new();
$config{test} = '3';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 3, q{3, minimum 0, maximum 5});

$policy = Perl::Critic::Policy->new();
$config{test} = '5';
$parameter->parse_and_validate_config_value($policy, \%config);
cmp_ok($policy->{_test}, q<==>, 5, q{5, minimum 0, maximum 5});

$policy = Perl::Critic::Policy->new();
$config{test} = '10';
eval { $parameter->parse_and_validate_config_value($policy, \%config); };
ok($EVAL_ERROR, q{above maximum of range});

###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
