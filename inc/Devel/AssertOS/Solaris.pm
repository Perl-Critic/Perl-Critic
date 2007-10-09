# $Id: Solaris.pm,v 1.1 2007/09/27 16:41:25 drhyde Exp $

package Devel::AssertOS::Solaris;

use Devel::CheckOS qw(die_unsupported);

$VERSION = '1.0';

sub os_is { $^O eq 'solaris' ? 1 : 0; }

die_unsupported() unless(os_is());

1;