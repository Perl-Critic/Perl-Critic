##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 12;
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

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use strict;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Module;
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict;
END_PERL

$policy = 'TestingAndDebugging::ProhibitStrictureDisabling';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict 'refs', 'vars';
END_PERL

$policy = 'TestingAndDebugging::ProhibitStrictureDisabling';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

$policy = 'TestingAndDebugging::ProhibitStrictureDisabling';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

%config = (allow => 'vars refs subs');
$policy = 'TestingAndDebugging::ProhibitStrictureDisabling';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict "vars", "refs", 'subs';
END_PERL

%config = (allow => 'vars subs');
$policy = 'TestingAndDebugging::ProhibitStrictureDisabling';
is( pcritique($policy, \$code, \%config), 1, $policy);

