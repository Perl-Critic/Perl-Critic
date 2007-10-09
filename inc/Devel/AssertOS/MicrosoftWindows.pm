# $Id: MicrosoftWindows.pm,v 1.3 2007/09/28 14:35:08 drhyde Exp $

package Devel::AssertOS::MicrosoftWindows;

use Devel::CheckOS qw(die_unsupported);

$VERSION = '1.0';

sub os_is { $^O =~ /^(cygwin|MSWin32)$/ ? 1 : 0; }

die_unsupported() unless(os_is());

1;
