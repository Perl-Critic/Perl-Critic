##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 6;
use Perl::Critic::Config;
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
