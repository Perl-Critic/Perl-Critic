#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 5;

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
die 'A horrible death';
END_PERL

$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 1, 'croak' );

#----------------------------------------------------------------

$code = <<'END_PERL';
die "A horrible death\n";
END_PERL

TODO: {
    local $TODO = q{Shouldn't complain if the message ends with \n};
$policy = 'ErrorHandling::RequireCarping';
is( pcritique($policy, \$code), 0, 'croak' );
}

#----------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab
