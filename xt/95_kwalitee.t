#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

our $VERSION = '1.140';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

eval 'use Test::Kwalitee 1.15 tests => [ qw{ -no_symlinks } ]; 1'
    or plan skip_all => 'Test::Kwalitee required to test kwalitee';


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
