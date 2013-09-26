#!/usr/bin/perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use English qw< -no_match_vars >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

use Test::Kwalitee 1.15 tests => [ qw{ -no_symlinks } ];

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
