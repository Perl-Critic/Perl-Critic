#!perl

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw{ starting_points_including_examples };

use Test::More;# 1.41;  # Need 1.41 or newer for correct support of L<text|scheme:...> links.

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

use Test::Pod 1.00;

all_pod_files_ok( all_pod_files( starting_points_including_examples() ) );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
