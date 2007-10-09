# $Id: MSWin32.pm,v 1.1 2007/09/28 14:35:08 drhyde Exp $

package Devel::AssertOS::MSWin32;

use Devel::CheckOS qw(die_unsupported);

$VERSION = '1.0';

sub os_is { $^O eq 'MSWin32' ? 1 : 0; }

die_unsupported() unless(os_is());

1;
