##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.00';
plan skip_all => 'Test::Pod::Coverage 1.00 requried to test POD' if $@;
my $trusted_rx = qr{ \A (?: new | violates | applies_to | severity ) \z }x; 
my $trustme = { trustme => [ $trusted_rx ] };
all_pod_coverage_ok($trustme);