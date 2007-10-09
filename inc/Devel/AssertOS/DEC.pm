# $Id: DEC.pm,v 1.2 2007/09/28 14:35:08 drhyde Exp $

package Devel::AssertOS::DEC;

use Devel::CheckOS qw(die_unsupported);

$VERSION = '1.0';

sub os_is { $^O =~ /^(VMS|dec_osf)$/ ? 1 : 0; }

die_unsupported() unless(os_is());

1;
