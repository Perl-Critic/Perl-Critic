#!perl

use 5.006001;
use strict;
use warnings;

use File::Spec;

use Test::More tests => 1;

our $VERSION = '1.140';

use Perl::Critic::TestUtils;
Perl::Critic::TestUtils::assert_version( $VERSION );

my $perlcritic = File::Spec->rel2abs( File::Spec->catfile( qw( blib script perlcritic ) ) );
if (not -e $perlcritic) {
    $perlcritic = File::Spec->rel2abs( File::Spec->catfile( qw( bin perlcritic ) ) );
}

require_ok($perlcritic);

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
