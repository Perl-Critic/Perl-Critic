##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 20;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use warnings;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use strict;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Module;
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict;
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict 'refs', 'vars';
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

%config = (allow => 'vars refs subs');
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict "vars", "refs", "subs";
END_PERL

%config = (allow => 'vars refs subs');
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict "vars", "refs", 'subs';
END_PERL

%config = (allow => 'VARS SUBS'); #Note wrong case!
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

%config = (allow => 'VARS SUBS'); #Note wrong case!
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings;
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings 'uninitialized', 'deprecated';
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(closure glob);
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(glob io once);
END_PERL

%config = (allow => 'iO Glob OnCe');
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings "numeric", "pack", "portable";
END_PERL

%config = (allow => 'numeric,portable, pack'); #Funky config
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings "numeric", "pack", 'portable';
END_PERL

#Note wrong case, funky config...
%config = (allow => 'NumerIC;PORTABLE'); 
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(numeric pack portable);
END_PERL

#Note wrong case, funky config...
%config = (allow => 'paCK/PortablE'); 
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 1, $policy);

