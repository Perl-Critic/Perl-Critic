##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 92;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

\t\t\t;

END_PERL

$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!
print "\t  \t  foobar  \t";
END_PERL

$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code), 1, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code, \%config), 3, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
;\tfor(1){
\t\tdo_something();
;\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code, \%config), 3, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
open ($foo, $bar);
open($foo, $bar);
uc();
lc();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open $foo, $bar;
uc $foo;
lc $foo;
my $foo;
my ($foo, $bar);
our ($foo, $bar);
local ($foo $bar);
return ($foo, $bar);
return ();
my_subroutine($foo $bar);
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $obj = SomeClass->new();
$obj->open();
$obj->close();
$obj->prototype();
$obj->delete();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, $bar, $baz);
@list = some_function($foo, $bar, $baz);
@list = ($baz);
@list = ();

@list = ($baz
);

@list = ($baz
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz);

@list = ($foo, 
	 $bar, 
	 $baz
	);

@list = ($foo, 
	 $bar, 
	 $baz
);


END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz,);

@list = ($foo, 
	 $bar, 
	 $baz,
);

@list = ($foo, 
	 $bar, 
	 $baz,
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for($i=0; $i<=$max; $i++){
  do_something();
}
END_PERL

$policy = 'ControlStructures::ProhibitCStyleForLoops';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for(@list){
  do_something();
}

for my $element (@list){
  do_something();
}

foreach my $element (@list){
  do_something();
}

do_something() for @list;
END_PERL

$policy = 'ControlStructures::ProhibitCStyleForLoops';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
do_something() if $condition;
do_something() while $condition;
do_something() until $condition;
do_something() unless $condition;
do_something() for @list;
END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
is( pcritique($policy, \$code), 5, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
do_something() if $condition;
do_something() while $condition;
do_something() until $condition;
do_something() unless $condition;
do_something() for @list;
END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
%config = (allow => 'if while until unless for');
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
if($condition){ do_something() } 
while($condition){ do_something() }
until($condition){ do_something() }
unless($condition){ do_something() }
END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
%config = (allow => 'if while until unless for');
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#PPI versions < 1.03 had problems with this
for my $element (@list){ do_something() }
for (@list){ do_something_else() }

END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Carp;

while ($condition) {
    next if $condition;
    last if $condition; 
    redo if $condition;
    return if $condition;
    goto HELL if $condition;
}

die 'message' if $condition;
die if $condition;

warn 'message' if $condition;
warn if $condition;

carp 'message' if $condition;
carp if $condition;

croak 'message' if $condition;
croak if $condition;

cluck 'message' if $condition;
cluck if $condition;

confess 'message' if $condition;
confess if $condition;

END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my %hash;
$hash{if} = 1;
$hash{unless} = 1;
$hash{until} = 1;
$hash{while} = 1;
$hash{for} = 1;
END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my %hash = (if => 1, unless => 1, until => 1, while => 1, for => 1);
END_PERL

$policy = 'ControlStructures::ProhibitPostfixControls';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
if ($condition1){
  $foo;
}
elsif ($condition2){
  $bar;
}
elsif ($condition3){
  $baz;
}
elsif ($condition4){
  $barf;
}
else {
  $nuts;
}
END_PERL

$policy = 'ControlStructures::ProhibitCascadingIfElse';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
if ($condition1){
  $foo;
}
elsif ($condition2){
  $bar;
}
elsif ($condition3){
  $bar;
}
else {
  $nuts;
}

if ($condition1){
  $foo;
}
else {
  $nuts;
}

if ($condition1){
  $foo;
}
END_PERL

$policy = 'ControlStructures::ProhibitCascadingIfElse';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
if ($condition1){
  $foo;
}
elsif ($condition2){
  $bar;
}
elsif ($condition3){
  $baz;
}
else {
  $nuts;
}
END_PERL

%config = (max_elsif => 1);
$policy = 'ControlStructures::ProhibitCascadingIfElse';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
until($condition){
  do_something();
}
END_PERL

$policy = 'ControlStructures::ProhibitUntilBlocks';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
while(! $condition){
  do_something();
}

do_something() until $condition
END_PERL

$policy = 'ControlStructures::ProhibitUntilBlocks';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
unless($condition){
  do_something();
}
END_PERL

$policy = 'ControlStructures::ProhibitUnlessBlocks';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
if(! $condition){
  do_something();
}

do_something() unless $condition
END_PERL

$policy = 'ControlStructures::ProhibitUnlessBlocks';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#just a comment
$foo = "bar";
$baz = qq{nuts};
END_PERL

$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
# $Revision$
# $Source$
# $Date$
END_PERL

$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
'$Revision$'
'$Source: foo/bar $'
'$Date$'
END_PERL

$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
q{$Revision$}
q{$Source: foo/bar $}
q{$Date$}
END_PERL

$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
q{$Revision$}
q{$Author$}
q{$Id: whatever $}
END_PERL

%config = (keywords => 'Revision Author Id');
$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#nothing here!
END_PERL

%config = (keywords => 'Author Id');
$policy = 'Miscellanea::RequireRcsKeywords';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
package bar;
package nuts;
$some_code = undef;
END_PERL

$policy = 'Modules::ProhibitMultiplePackages';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
$some_code = undef;
END_PERL

$policy = 'Modules::ProhibitMultiplePackages';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require 'Exporter';
require 'My/Module.pl';
use 'SomeModule';
use "OtherModule.pm";
no "Module";
no "Module.pm";
END_PERL

$policy = 'Modules::RequireBarewordIncludes';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require MyModule;
use MyModule;
no MyModule;
use strict;
END_PERL

$policy = 'Modules::RequireBarewordIncludes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Some::Module;
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Some::Module;
print 'whatever';
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
use strict;
$foo = $bar;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
$foo = $bar;
package foo;
END_PERL

%config = (exempt_scripts => 1); 
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
use strict;
use warnings;
my $foo = 42;

END_PERL

%config = (exempt_scripts => 1);
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 0, $policy);


#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
package foo;
$foo = $bar;
END_PERL

%config = (exempt_scripts => 1); 
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
END_PERL

$policy = 'Modules::ProhibitSpecificModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Good::Module;
END_PERL

$policy = 'Modules::ProhibitSpecificModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
#Nothing!
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $VERSION = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our ($VERSION) = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$Package::VERSION = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use vars '$VERSION';
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use vars qw($VERSION);
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $VERSION;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $Version;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
__END__
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
__DATA__
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
# The end
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1; # final true value
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
0;
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
sub foo {}
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
END {}
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
'Larry';
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ m{pattern}x;
my $string =~ m{pattern}gimx;
my $string =~ m{pattern}gixs;
my $string =~ m{pattern}xgms;

my $string =~ m/pattern/x;
my $string =~ m/pattern/gimx;
my $string =~ m/pattern/gixs;
my $string =~ m/pattern/xgms;

my $string =~ /pattern/x;
my $string =~ /pattern/gimx;
my $string =~ /pattern/gixs;
my $string =~ /pattern/xgms;

my $string =~ s/pattern/foo/x;
my $string =~ s/pattern/foo/gimx;
my $string =~ s/pattern/foo/gixs;
my $string =~ s/pattern/foo/xgms;
END_PERL

$policy = 'RegularExpressions::RequireExtendedFormatting';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ m{pattern};
my $string =~ m{pattern}gim;
my $string =~ m{pattern}gis;
my $string =~ m{pattern}gms;

my $string =~ m/pattern/;
my $string =~ m/pattern/gim;
my $string =~ m/pattern/gis;
my $string =~ m/pattern/gms;

my $string =~ /pattern/;
my $string =~ /pattern/gim;
my $string =~ /pattern/gis;
my $string =~ /pattern/gms;

my $string =~ s/pattern/foo/;
my $string =~ s/pattern/foo/gim;
my $string =~ s/pattern/foo/gis;
my $string =~ s/pattern/foo/gms;

END_PERL

$policy = 'RegularExpressions::RequireExtendedFormatting';
is( pcritique($policy, \$code), 16, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@out = `some_command`;
@out = qx{some_command};
END_PERL

$policy = 'InputOutput::ProhibitBacktickOperators';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open FH, '>', $some_file;
open FH, '>', $some_file or die;
open(FH, '>', $some_file);
open(FH, '>', $some_file) or die;

END_PERL

$policy = 'InputOutput::ProhibitBarewordFileHandles';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open $fh, '>', $some_file;
open $fh, '>', $some_file or die;
open($fh, '>', $some_file);
open($fh, '>', $some_file) or die;

open my $fh, '>', $some_file;
open my $fh, '>', $some_file or die;
open(my $fh, '>', $some_file);
open(my $fh, '>', $some_file) or die;

END_PERL

$policy = 'InputOutput::ProhibitBarewordFileHandles';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
select( $fh );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, '1 arg; variable, w/parens' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select $fh;
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, '1 arg; variable, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( STDERR );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, '1 arg; fh, w/parens' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select STDERR;
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, '1 arg; fh, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, 0.25 );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
isnt( pcritique($policy, \$code), 1, '4 args' );

#----------------------------------------------------------------

$code = <<'END_PERL';

open $fh, ">$output";
open($fh, ">$output");
open($fh, ">$output") or die;

open my $fh, ">$output";
open(my $fh, ">$output");
open(my $fh, ">$output") or die;

open FH, ">$output";
open(FH, ">$output");
open(FH, ">$output") or die;

#This are tricky because the Critic can't
#tell where the expression really ends
open FH, ">$output" or die;
open $fh, ">$output" or die;
open my $fh, ">$output" or die;

END_PERL

$policy = 'InputOutput::ProhibitTwoArgOpen';
is( pcritique($policy, \$code), 12, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open $fh, '>', $output";
open($fh, '>', $output");
open($fh, '>', $output") or die;

open my $fh, '>', $output";
open(my $fh, '>', $output");
open(my $fh, '>', $output") or die;

open FH, '>', $output";
open(FH, '>', $output");
open(FH, '>', $output") or die;

#This are tricky because the Critic can't
#tell where the expression really ends
open $fh, '>', $output" or die;
open my $fh, '>', $output" or die;
open FH, '>', $output" or die;

END_PERL

$policy = 'InputOutput::ProhibitTwoArgOpen';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print "this is literal";
print qq{this is literal};
END_PERL

$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------
$code = <<'END_PERL';
print 'this is literal';
print q{this is literal};
END_PERL

$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq( qq{ qq[ qq/'); 
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq( qq{'); 
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => '() {}'); #Testing odd config
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq() qq{}'); #Testing odd config
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print 'this is not $literal';
print q{this is not $literal};
print 'this is not literal\n';
print q{this is not literal\n};
END_PERL

$policy = 'ValuesAndExpressions::RequireInterpolationOfMetachars';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print "this is not $literal";
print qq{this is not $literal};
print "this is not literal\n";
print qq{this is not literal\n};
END_PERL

$policy = 'ValuesAndExpressions::RequireInterpolationOfMetachars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 01;
$var = 010;
$var = 001;
$var = 0010;
$var = 0.12;
$var = 00.001;
$var = -01;
$var = -010;
$var = -001;
$var = -0010;
$var = -0.12;
$var = -00.001;
$var = +01;
$var = +010;
$var = +001;
$var = +0010;
$var = +0.12;
$var = +00.001;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitLeadingZeros';
is( pcritique($policy, \$code), 18, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 0;
$var = 0.;
$var = 10;
$var = 0.0;
$var = 10.0;
$var = -0;
$var = -0.;
$var = -10;
$var = -0.0;
$var = -10.0;
$var = +0;
$var = +0.;
$var = +10;
$var = +0.0;
$var = +10.0;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitLeadingZeros';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 1234_567;
$var = 1234_567.;
$var = 1234_567.890;
$var = -1234_567.8901;
$var = -1234_567;
$var = -1234_567.;
$var = -1234_567.890;
$var = -1234_567.8901;
$var = +1234_567;
$var = +1234_567.;
$var = +1234_567.890;
$var = +1234_567.8901;

END_PERL

$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code), 12, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 12;
$var = 1234;
$var = 1_234;
$var = 1_234.01;
$var = 1_234_567;
$var = 1_234_567.;
$var = 1_234_567.890_123;
$var = -1_234;
$var = -1_234.01;
$var = -1_234_567;
$var = -1_234_567.;
$var = -1_234_567.890_123;
$var = +1_234;
$var = +1_234.01;
$var = +1_234_567;
$var = +1_234_567.;
$var = +1_234_567.890_123;
END_PERL

$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 1000001;
$var = 1000000.01;
$var = 1000_000.01;
$var = 10000_000.01;
$var = -1000001;
$var = -1234567;
$var = -1000000.01;
$var = -1000_000.01;
$var = -10000_000.01;
END_PERL

%config = (min_value => 1_000_000);
$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code, \%config), 9, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 999999;
$var = 123456;
$var = 100000.01;
$var = 10_000.01;
$var = 100_000.01;
$var = -999999;
$var = -123456;
$var = -100000.01;
$var = -10_000.01;
$var = -100_000.01;
END_PERL

%config = (min_value => 1_000_000);
$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'baz');

@list = ('foo',
	 'bar',
	 'baz');

END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'bee baz');
@list = ('foo, 'bar');
@list = ($foo, 'bar', 'baz');
%hash = ('foo' => 'bar', 'fo' => 'fum');
my_function('foo', 'bar', 'fudge');
foreach ('foo', 'bar', 'nuts'){ do_something($_) }
END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar, 'baz');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'baz', 'nuts');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 1, $policy);
