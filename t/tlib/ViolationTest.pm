package ViolationTest;

use 5.006001;
use strict;
use warnings;

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

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
