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

use Test::More tests => 4;

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
        description => 'A string parameter for testing',
        behavior    => 'string',
    };


$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
is($policy->{_test}, undef, q{no value, no default});

$policy = Perl::Critic::Policy->new();
$config{test} = 'foobie';
$parameter->parse_and_validate_config_value($policy, \%config);
is($policy->{_test}, 'foobie', q{'foobie', no default});


$specification->{default_string} = 'bletch';
delete $config{test};

$parameter = Perl::Critic::PolicyParameter->new($specification);
$policy = Perl::Critic::Policy->new();
$parameter->parse_and_validate_config_value($policy, \%config);
is($policy->{_test}, 'bletch', q{no value, default 'bletch'});

$policy = Perl::Critic::Policy->new();
$config{test} = 'foobie';
$parameter->parse_and_validate_config_value($policy, \%config);
is($policy->{_test}, 'foobie', q{'foobie', default 'bletch'});


###############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
