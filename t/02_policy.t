#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/lib/Perl/Critic/Config.pm $
#     $Date: 2005-12-04 19:47:47 -0800 (Sun, 04 Dec 2005) $
#   $Author: thaljef $
# $Revision: 51 $
########################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 8;

our $VERSION = '0.13';
$VERSION = eval $VERSION;  ## no critic

#-------------------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Policy');
}

package PolicyTest;
use base 'Perl::Critic::Policy';

package main;

my $p = PolicyTest->new();
isa_ok($p, 'PolicyTest');

eval { $p->violates(); };
ok($EVAL_ERROR, 'abstract violates');

#Test default application...
is($p->applies_to(), 'PPI::Element', 'applies_to');

#Test default severity...
is( $p->default_severity(), 1, 'default_severity');
is( $p->get_severity(), 1, 'get_severity' );

#Change severity level...
$p->set_severity(3);

#Test severity again...
is( $p->default_severity(), 1 ); #Still the same
is( $p->get_severity(), 3 );     #Should have new value