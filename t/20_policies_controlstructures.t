##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 18;
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
    exit if $condition;
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

exit 0 if $condition;
exit if $condition;

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
sub a {
  return 123;
  do_something();
}

sub b {
  croak 'error';
  do_something();
}

sub c {
  confess 'error';
  do_something();
}

for (1..2) {
  next;
  do_something();
}

for (1..2) {
  last;
  do_something();
}

for (1..2) {
  redo;
  do_something();
}

exit;
do_something();

die;
do_something();

exit;
sub d {}
print 123;

die;
print 456;
FOO:

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 10, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub a {
  return 123 if $a == 1;
  do_something();
}

sub b {
  croak 'error' unless $b;
  do_something();
}

sub c {
  confess 'error' if $c != $d;
  do_something();
}

for (1..2) {
  next if $_ == 1;
  do_something();
}

for (1..2) {
  last if $_ == 2;
  do_something();
}

for (1..2) {
  redo if do_this($_);
  do_something();
}

{
    exit;
    FOO:
    do_something();
}

{
    die;
    BAR:
    do_something();
}

{
    exit;
    sub d {}
    BAZ:
    print 123;
}

die;
JAPH:
sub e {}
print 456;

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 0, $policy);

