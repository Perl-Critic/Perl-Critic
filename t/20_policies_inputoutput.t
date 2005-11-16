##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 10;
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
