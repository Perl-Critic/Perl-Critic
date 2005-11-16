use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 4;

our $VERSION = '0.13';
$VERSION = eval $VERSION;  ## no critic

#---------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Policy');
}

package PolicyTest;
use base 'Perl::Critic::Policy';

package main;

my $p = PolicyTest->new();
isa_ok($p, 'PolicyTest');

eval { $p->violates(); };
ok($EVAL_ERROR, 'abstract violates');

is($p->applies_to(), 'PPI::Element', 'applies_to');
