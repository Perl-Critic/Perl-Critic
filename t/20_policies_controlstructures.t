#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 29;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

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

foreach (1,2,3){
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
{
    exit;
    require Foo;
}

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

{
    exit;
    do_something();
}


{
    die;
    do_something();
}


{
    exit;
    sub d {}
    print 123;
}

{
   $foo, die;
   print 123;
}

die;
print 456;
FOO: print $baz;

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 12, $policy);

#----------------------------------------------------------------
$code = <<'END_PERL';

exit;

no warnings;
use Memoize;
our %memoization;

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
exit;

__DATA__
...
END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
exit;

__END__
...
END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 0, $policy);

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

{
    die;
    JAPH:
    sub e {}
    print 456;
}

{
    exit;
    BEGIN {
        print 123;
    }
}

{
   $foo || die;
   print 123;
}

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 0, $policy);



#----------------------------------------------------------------

$code = <<'END_PERL';

exit;
print; ## no critic(ProhibitUnreachableCode)
print;

END_PERL

$policy = 'ControlStructures::ProhibitUnreachableCode';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

for $element1 ( @list1 ) {
    foreach $element2 ( @list2 ) {
        for $element3 ( @list3 ) {
            foreach $element4 ( @list4 ) {
               for $element5 ( @list5 ) {
                  for $element6 ( @list6 ) {
                  }
               }
            }
        }
    }
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 1, '6 for loops');

#----------------------------------------------------------------

$code = <<'END_PERL';

if ($condition1) {
  if ($condition2) {
    if ($condition3) {
      if ($condition4) {
        if ($condition5) {
          if ($condition6) {
          }
        }
      }
    }
  }
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 1, '6 if blocks');

#----------------------------------------------------------------

$code = <<'END_PERL';

if ($condition1) {
  if ($condition2) {}
  if ($condition3) {}
  if ($condition4) {}
  if ($condition5) {}
  if ($condition6) {}
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 0, '6 if blocks, not nested');

#----------------------------------------------------------------

$code = <<'END_PERL';


for     $element1 ( @list1 ) {
  foreach $element2 ( @list2 ) {}
  for     $element3 ( @list3 ) {}
  foreach $element4 ( @list4 ) {}
  for     $element5 ( @list5 ) {}
  foreach $element6 ( @list6 ) {}
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 0, '6 for loops, not nested');

#----------------------------------------------------------------

$code = <<'END_PERL';

if ($condition) {
  foreach ( @list ) {
    until ($condition) {
      for (my $i=0; $<10; $i++) {
        if ($condition) {
          while ($condition) {
          }
        }
      }
    }
  }
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 1, '6 mixed nests');

#----------------------------------------------------------------

$code = <<'END_PERL';

if ($condition) {
  foreach ( @list ) {
    until ($condition) {
      for (my $i=0; $<10; $i++) {
        if ($condition) {
          while ($condition) {
          }
        }
      }
    }
  }
}

END_PERL

%config = ( max_nests => 6 );
$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code, \%config), 0, 'Configurable');

#----------------------------------------------------------------

$code = <<'END_PERL';

if ($condition) {
    s/foo/bar/ for @list;
    until ($condition) {
      for (my $i=0; $<10; $i++) {
          die if $condition;
        while ($condition) {
        }
      }
   }
}

END_PERL

$policy = 'ControlStructures::ProhibitDeepNests';
is( pcritique($policy, \$code), 0, 'With postfixes');
