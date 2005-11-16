package ViolationTest2;

use warnings;
use strict;
use Perl::Critic::Violation;

# This file exists solely to test Perl::Critic::Violation::import()

sub get_violation
{
   return Perl::Critic::Violation->new('', '', [0,0]);
}

1;
