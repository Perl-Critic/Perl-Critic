##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 11;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(critique);
PerlCriticTestUtils::block_perlcriticrc();

# Configure Critic not to load certain policies.  This
# just make it a little easier to create test cases
my $profile = { '-CodeLayout::RequireTidyCode'     => {},
                '-Miscellanea::RequireRcsKeywords' => {},
                '-Modules::RequireEndWithOne'      => {}
};

my $code = undef;

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

require 'some_library.pl';  ## no critic
print $crap if $condition;  ## no critic
END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 0);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$foo = $bar;

## no critic

require 'some_library.pl';
print $crap if $condition;

## use critic

$baz = $nuts;

END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 0);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 1);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

## use critic
my $noisy = '!';

END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 1);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## no critic
  $long_int = 12345678;
  $oct_num  = 033;
  ## use critic
}

my $noisy = '!';
my $empty = '';

END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 2);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

## no critic
for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
my $empty = '';
END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 0);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic
my $empty = '';        ## use critic
END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 1);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic

$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';
END_PERL

is( critique(\$code, {-profile => $profile, -severity => 1} ), 4);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

$long_int = 12345678;  ## no critic
$oct_num  = 033;       ## no critic
my $noisy = '!';       ## no critic
my $empty = '';        ## no critic

## use critic
$long_int = 12345678;
$oct_num  = 033;
my $noisy = '!';
my $empty = '';
END_PERL

is( critique(\$code, {-profile  => $profile,
                      -severity => 1,
                      -force    => 1 } ), 8);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  $long_int = 12345678;
  $oct_num  = 033;
}

my $noisy = '!';
my $empty = '';
END_PERL

is( critique(\$code, {-profile  => $profile,
                      -severity => 1,
                      -force    => 1 } ), 4);

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
use warnings;
our $VERSION = 1.0;

for my $foo (@list) {
  ## use critic
  $long_int = 12345678;
  $oct_num  = 033;
}

## use critic
my $noisy = '!';
my $empty = '';
END_PERL

is( critique(\$code, {-profile  => $profile,
                      -severity => 1,
                      -force    => 1 } ), 4);
