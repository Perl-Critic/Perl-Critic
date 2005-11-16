##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 8;
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
local $foo = $bar;
local $/ = undef;
local $| = 1;
local ($foo, $bar) = ();
local ($/) = undef;
local ($RS, $>) = ();
local ($foo, %SIG);
END_PERL

$policy = 'Variables::ProhibitLocalVars';
is( pcritique($policy, \$code), 7, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
local ($RS);
local $INPUT_RECORD_SEPARATOR;
local $PROGRAM_NAME;
local ($EVAL_ERROR, $OS_ERROR);
my  $var1 = 'foo';
our $var2 = 'bar';
local $SIG{HUP} \&handler;
local $INC{$module} = $path;
END_PERL

$policy = 'Variables::ProhibitLocalVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $var1 = 'foo';
our (%var2, %var3) = 'foo';
our (%VAR4, $var5) = ();
$Package::foo;
@Package::list = ('nuts');
%Package::hash = ('nuts');
$::foo = $bar;
@::foo = ($bar);
%::foo = ();
use vars qw($FOO $BAR);
END_PERL

$policy = 'Variables::ProhibitPackageVars';
is( pcritique($policy, \$code), 10, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $VAR1 = 'foo';
our (%VAR2, %VAR3) = ();
our $VERSION = '1.0';
our @EXPORT = qw(some symbols);
$Package::VERSION = '1.2';
%Package::VAR = ('nuts');
@Package::EXPORT = ();
$::VERSION = '1.2';
%::VAR = ('nuts');
@::EXPORT = ();
&Package::my_sub();
&::my_sub();
END_PERL

$policy = 'Variables::ProhibitPackageVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $var1 = 'foo';
my %var2 = 'foo';
my ($foo, $bar) = ();
END_PERL

$policy = 'Variables::ProhibitPackageVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$/ = undef;
$| = 1;
$> = 3;
END_PERL

$policy = 'Variables::ProhibitPunctuationVars';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$RS = undef;
$INPUT_RECORD_SEPARATOR = "\n";
$OUTPUT_AUTOFLUSH = 1;
print $foo, $baz;
END_PERL

$policy = 'Variables::ProhibitPunctuationVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$string =~ /((foo)bar)/;
$foobar = $1;
$foo = $2;
$3;
$stat = stat(_);
@list = @_;
my $line = $_;
END_PERL

$policy = 'Variables::ProhibitPunctuationVars';
is( pcritique($policy, \$code), 0, $policy);

