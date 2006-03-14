##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 20;
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
local $Other::Package::foo;
local (@Other::Package::foo, $EVAL_ERROR);
my  $var1 = 'foo';
our $var2 = 'bar';
local $SIG{HUP} \&handler;
local $INC{$module} = $path;
END_PERL

$policy = 'Variables::ProhibitLocalVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use English;
 use English qw($PREMATCH) ; 
use English qw($MATCH);
use English qw($POSTMATCH);
$`;
$&;
$';
$PREMATCH;
$MATCH;
$POSTMATCH;
END_PERL

$policy = 'Variables::ProhibitMatchVars';
is( pcritique($policy, \$code), 10, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use English qw(-no_match_vars);
use English qw($EVAL_ERROR);
END_PERL

$policy = 'Variables::ProhibitMatchVars';
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

use vars qw($fooBar $baz);
use vars qw($fooBar @EXPORT);
use vars '$fooBar', "$baz";
use vars '$fooBar', '@EXPORT';
use vars ('$fooBar', '$baz');
use vars ('$fooBar', '@EXPORT');
END_PERL

$policy = 'Variables::ProhibitPackageVars';
is( pcritique($policy, \$code), 15, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $VAR1 = 'foo';
our (%VAR2, %VAR3) = ();
our $VERSION = '1.0';
our @EXPORT = qw(some symbols);

use vars qw($VERSION @EXPORT);
use vars ('$VERSION, '@EXPORT');
use vars  '$VERSION, '@EXPORT';

#local $Foo::bar;
#local @This::that;
#local %This::that;
#local $This::that{ 'key' };
#local $This::that[ 1 ];
#local (@Baz::bar, %Baz::foo);

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

#----------------------------------------------------------------

$code = <<'END_PERL';
$Other::Package::_foo;
@Other::Package::_bar;
%Other::Package::_baz;
&Other::Package::_quux;
*Other::Package::_xyzzy;
\$Other::Package::_foo;
END_PERL

$policy = 'Variables::ProtectPrivateVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$_foo;
@_bar;
%_baz;
&_quux;
\$_foo;
$::_foo;
END_PERL

$policy = 'Variables::ProtectPrivateVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 if $bar;
local $foo = 1 if $bar;
our $foo = 1 if $bar;

my ($foo, $baz) = @list if $bar;
local ($foo, $baz) = @list if $bar;
our ($foo, $baz) = 1 if $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 unless $bar;
local $foo = 1 unless $bar;
our $foo = 1 unless $bar;

my ($foo, $baz) = @list unless $bar;
local ($foo, $baz) = @list unless $bar;
our ($foo, $baz) = 1 unless $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 while $bar;
local $foo = 1 while $bar;
our $foo = 1 while $bar;

my ($foo, $baz) = @list while $bar;
local ($foo, $baz) = @list while $bar;
our ($foo, $baz) = 1 while $bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 for @bar;
local $foo = 1 for @bar;
our $foo = 1 for @bar;

my ($foo, $baz) = @list for @bar;
local ($foo, $baz) = @list for @bar;
our ($foo, $baz) = 1 for @bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo = 1 foreach @bar;
local $foo = 1 foreach @bar;
our $foo = 1 foreach @bar;

my ($foo, $baz) = @list foreach @bar;
local ($foo, $baz) = @list foreach @bar;
our ($foo, $baz) = 1 foreach @bar;

END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo (@list) { do_something() }
foreach my $foo (@list) { do_something() }
while (my $foo $condition) { do_something() }
until (my $foo = $condition) { do_something() }
unless (my $foo = $condition) { do_something() }
END_PERL

$policy = 'Variables::ProhibitConditionalDeclarations';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

local $foo;
local ($foo, $bar);

local $|;
local ($|, $$);

local $OUTPUT_RECORD_SEPARATOR;
local ($OUTPUT_RECORD_SEPARATOR, $PROGRAM_NAME);

END_PERL

$policy = 'Variables::RequireInitializationForLocalVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

local $foo = 'foo';
local ($foo, $bar) = 'foo';       #Not right, but still passes
local ($foo, $bar) = qw(foo bar);

my $foo;
my ($foo, $bar);
our $bar
our ($foo, $bar);

END_PERL

$policy = 'Variables::RequireInitializationForLocalVars';
is( pcritique($policy, \$code), 0, $policy);

