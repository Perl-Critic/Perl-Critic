##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 16;
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
