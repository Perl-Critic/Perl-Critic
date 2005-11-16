package ViolationTest;

use warnings;
use strict;
use Perl::Critic::Violation;
use Perl::Critic::Violation;  # this is duplicated for test coverage of repeated calls to import()

# This file exists solely to test Perl::Critic::Violation::import()

=head1 DESCRIPTION

This is a test diagnostic.

=cut

sub get_violation
{
   return Perl::Critic::Violation->new('', '', [0,0]);
}

1;
