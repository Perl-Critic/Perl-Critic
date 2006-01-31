package ViolationTest2;

use strict;
use warnings;
use PPI::Document;
use Perl::Critic::Violation;

# This file exists solely to test Perl::Critic::Violation::import()

sub get_violation {

    my $code = 'Hello World;';
    my $doc = PPI::Document->new(\$code);
    return Perl::Critic::Violation->new('', '', [0,0], 0);
}

1;
