#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Perl::Critic::TestUtils qw{ should_skip_author_tests $AUTHOR_TEST_SKIP_MESSAGE };

if (should_skip_author_tests()) {
    plan skip_all => $AUTHOR_TEST_SKIP_MESSAGE;
}

eval
{
   require Test::Kwalitee;
   Test::Kwalitee->import( tests => [ '-no_symlinks' ] );
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
