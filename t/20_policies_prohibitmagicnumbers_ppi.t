#!perl

use strict;
use warnings;
use Test::More tests => 1;

use PPI; # force $PPI::VERSION to be initialized.
BEGIN {
    $PPI::VERSION = '1.118';
} # end BEGIN

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $policy = 'ValuesAndExpressions::ProhibitMagicNumbers';
my $code;

#----------------------------------------------------------------

# TEST

$code = <<'END_PERL';
$Woodland_elf = 2.5;
END_PERL
    
is(
    pcritique($policy, \$code),
    0,
    "$policy: all code must be considered valid if the installed version of PPI is 1.118 or earlier."
);

#----------------------------------------------------------------
