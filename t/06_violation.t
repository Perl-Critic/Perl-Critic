use strict;
use warnings;
use English qw(-no_match_vars);
use Test::More tests => 22;

our $VERSION = '0.13';
$VERSION = eval $VERSION;  ## no critic

#---------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Violation');
}

use lib qw(t/tlib);
use ViolationTest;   # this is solely to test the import() method; has diagnostics
use ViolationTest2;  # this is solely to test the import() method; no diagnostics

###########################
#  method tests

can_ok('Perl::Critic::Violation', 'sort_by_location');
can_ok('Perl::Critic::Violation', 'new');
can_ok('Perl::Critic::Violation', 'location');
can_ok('Perl::Critic::Violation', 'diagnostics');
can_ok('Perl::Critic::Violation', 'description');
can_ok('Perl::Critic::Violation', 'explanation');
can_ok('Perl::Critic::Violation', 'policy');
can_ok('Perl::Critic::Violation', 'to_string');
    
###########################
# individual tests

# Failures:
eval { Perl::Critic::Violation->new('desc', 'expl'); };
ok($EVAL_ERROR, 'new, wrong number of args');
eval { Perl::Critic::Violation->new('desc', 'expl', {line=>0,column=>0}); };
ok($EVAL_ERROR, 'new, bad arg');

# accessors
my $no_diagnostics_msg = qr/ \s* No [ ] diagnostics [ ] available \s* /xms;
my $viol = Perl::Critic::Violation->new('Foo', 'Bar', [2,3]);
is(       $viol->description(), 'Foo',       'description');
is(       $viol->explanation(), 'Bar',       'explanation');
is_deeply($viol->location(),    [2,3],       'location');
is(       $viol->policy(),      __PACKAGE__, 'policy');
like($viol->diagnostics(), qr/ \A $no_diagnostics_msg \z /xms, 'diagnostics');

{
   local $Perl::Critic::Violation::FORMAT = '%l,%c,%m,%e,%p,%d';
   my $pkg = __PACKAGE__;
   my $expect = qr/\A 2,3,Foo,Bar,\Q$pkg\E,$no_diagnostics_msg \z/xms;
   like($viol->to_string(), $expect, 'to_string');
   like("$viol", $expect, 'stringify');
}

is(Perl::Critic::Violation->new('Foo', [28], [2,3])->explanation(), 'See page 28 of PBP', 'explanation');
is(Perl::Critic::Violation->new('Foo', [28,30], [2,3])->explanation(), 'See pages 28,30 of PBP', 'explanation');

# import
like(ViolationTest->get_violation()->diagnostics(),
     qr/ \A \s* This [ ] is [ ] a [ ] test [ ] diagnostic\. \s*\z /xms, 'import diagnostics');

# location sorting
# test data:
my %l = (
   no_col  => [1,undef],
   no_line => [undef,1],
   nothing => [undef,undef],
   l1_1     => [1,1],
   l1_10    => [1,10],
   l1_15    => [1,15],
   l2_1     => [2,1],
   l2_10    => [2,10],
   l3_1     => [3,1],
);
my @v = map {Perl::Critic::Violation->new('', '', $_)} values %l;
is_deeply([map {$_->location()} Perl::Critic::Violation->sort_by_location(@v)],
          [@l{qw(nothing no_line no_col l1_1 l1_10 l1_15 l2_1 l2_10 l3_1)}], 'sort_by_location');
