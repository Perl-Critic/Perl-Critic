#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 19;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

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

$foo{open}; # not a function call
{open}; # zero args, for Devel::Cover

END_PERL

$policy = 'InputOutput::ProhibitBarewordFileHandles';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
select( $fh );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, $policy.' 1 arg; variable, w/parens' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select $fh;
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, $policy.' 1 arg; variable, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( STDERR );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, $policy.' 1 arg; fh, w/parens' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select STDERR;
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 1, $policy.' 1 arg; fh, as built-in' );

#----------------------------------------------------------------

$code = <<'END_PERL';
select( undef, undef, undef, 0.25 );
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 0, $policy.' 4 args' );

#----------------------------------------------------------------

$code = <<'END_PERL';
sub select { }
END_PERL

$policy = 'InputOutput::ProhibitOneArgSelect';
is( pcritique($policy, \$code), 0, $policy.' RT Bug: #15653' );

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

$foo{open}; # not a function call

# There is no three-arg equivalent for these
open( \*STDOUT, '>&STDERR' );
open( *STDOUT, '>&STDERR' );
open( STDOUT, '>&STDERR' );

# Other file modes.
open( \*STDOUT, '>>&STDERR' );
open( \*STDOUT, '<&STDERR' );
open( \*STDOUT, '+>&STDERR' );
open( \*STDOUT, '+>>&STDERR' );
open( \*STDOUT, '+<&STDERR' );

END_PERL

$policy = 'InputOutput::ProhibitTwoArgOpen';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo (<FH>) {}
for $foo (<$fh>) {}
for (<>) {}

foreach my $foo (<FH>) {}
foreach $foo (<$fh>) {}
foreach (<>) {}
END_PERL

$policy = 'InputOutput::ProhibitReadlineInForLoop';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo (@lines) {}
while( my $foo = <> ){}
while( $foo = <> ){}
while( <> ){}
END_PERL

$policy = 'InputOutput::ProhibitReadlineInForLoop';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

#print FH;             #Punt on this
print FH "something" . "something else";
print FH generate_report();
print FH "something" if $DEBUG;
print FH @list;
print FH $foo, $bar;
print( FH @list );
print( FH $foo, $bar );

END_PERL

$policy = 'InputOutput::RequireBracedFileHandleWithPrint';
is( pcritique($policy, \$code), 7, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

#print $fh;           #Punt on this
#print $fh if 1;
print $fh "something" . "something else";
print $fh generate_report();
print $fh "something" if $DEBUG;
print $fh @list;
print $fh $foo, $bar;
print( $fh @list );
print( $fh $foo, $bar );

END_PERL

$policy = 'InputOutput::RequireBracedFileHandleWithPrint';
is( pcritique($policy, \$code), 7, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print "something" . "something else";
print "something" . "something else"
  or die;
print {FH} "something" . "something else";
print {FH} "something" . "something else"
  or die;

print generate_report();
print generate_report()
  or die;
print {FH} generate_report();
print {FH} generate_report()
  or die;

print rand 10;
print rand 10
  or die;

print {FH};
print {FH}
  or die;
print {FH} @list;
print {FH} @list
  or die;
print {FH} $foo, $bar;
print {FH} $foo, $bar
  or die;

print @list;
print @list
  or die;
print $foo, $bar;
print $foo, $bar
  or die;
print $foo , $bar;
print $foo , $bar
  or die;
print foo => 1;
print foo => 1
  or die;

print( {FH} @list );
print( {FH} @list )
  or die;
print( {FH} $foo, $bar );
print( {FH} $foo, $bar )
  or die;

print();
print()
  or die;
print( );
print( )
  or die;
print( @list );
print( @list )
  or die;
print( $foo, $bar );
print( $foo, $bar )
  or die;

print if 1;
print or die if 1;

print 1 2; # syntax error, but not a policy violation
$foo{print}; # not a function call
{print}; # no siblings

END_PERL

$policy = 'InputOutput::RequireBracedFileHandleWithPrint';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

print {$fh};
print {$fh} @list;
print {$fh} $foo, $bar;
print( {$fh} @list );
print( {$fh} $foo, $bar );

END_PERL

$policy = 'InputOutput::RequireBracedFileHandleWithPrint';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
-t;
if (-t) { }
END_PERL

$policy = 'InputOutput::ProhibitInteractiveTest';
is( pcritique($policy, \$code), 2, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
-toomany;
-f _;
END_PERL

$policy = 'InputOutput::ProhibitInteractiveTest';
is( pcritique($policy, \$code), 0, $policy );
