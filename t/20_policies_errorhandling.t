##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_builtinfunctions.t $
#    $Date: 2006-07-15 01:00:50 -0700 (Sat, 15 Jul 2006) $
#   $Author: thaljef $
# $Revision: 486 $
##################################################################

use strict;
use warnings;
use Test::More tests => 4;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;

#----------------------------------------------------------------

$code = <<'END_PERL';
die 'A horrible death' if $condtion;

if ($condition) {
   die 'A horrible death';
}

open my $fh, '<', $path or
  die "Can't open file $path";
END_PERL

$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 3, 'die' );

#----------------------------------------------------------------

$code = <<'END_PERL';
warn 'A horrible death' if $condtion;

if ($condition) {
   warn 'A horrible death';
}

open my $fh, '<', $path or
  warn "Can't open file $path";
END_PERL

$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 3, 'warn' );

#----------------------------------------------------------------

$code = <<'END_PERL';
carp 'A horrible death' if $condtion;

if ($condition) {
   carp 'A horrible death';
}

open my $fh, '<', $path or
  carp "Can't open file $path";
END_PERL

$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 0, 'carp' );

#----------------------------------------------------------------

$code = <<'END_PERL';
croak 'A horrible death' if $condtion;

if ($condition) {
   croak 'A horrible death';
}

open my $fh, '<', $path or
  croak "Can't open file $path";
END_PERL

$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 0, 'croak' );

#----------------------------------------------------------------
