package ViolationTest;

use warnings;
use strict;
use PPI::Document;
use Perl::Critic::Violation;
use Perl::Critic::Violation;  # this is duplicated for test coverage of repeated calls to import()

# This file exists solely to test Perl::Critic::Violation::import()

=head1 DESCRIPTION

This is a test diagnostic.

=cut

sub get_violation {

    my $code = 'Hello World;';
    my $doc = PPI::Document->new(\$code);
    return Perl::Critic::Violation->new('', '', $doc, 0);
}

1;
