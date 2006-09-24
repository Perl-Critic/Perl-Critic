##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_testinganddebugging.t $
#    $Date: 2006-08-22 18:25:01 -0500 (Tue, 22 Aug 2006) $
#   $Author: jjore $
# $Revision: 642 $
##################################################################

use strict;
use warnings;
use Test::More tests => 3;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
use Test::More tests => 20;
ok($foo);
ok(!$foo);
is(1,2);
isnt(1,2);
like('foo',qr/f/);
unlike('foo',qr/f/);
cmp_ok(1,'==',2);
is_deeply([], {});
pass();
fail();
END_PERL

$policy = 'Testing::RequireTestLabels';
is( pcritique($policy, \$code), 10, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
ok($foo);
ok(!$foo);
is(1,2);
isnt(1,2);
like('foo',qr/f/);
unlike('foo',qr/f/);
cmp_ok(1,'==',2);
is_deeply([], {});
pass();
fail();
END_PERL

$policy = 'Testing::RequireTestLabels';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
ok($foo,'label');
ok(!$foo,'label');
is(1,2,'label');
isnt(1,2,'label');
like('foo',qr/f/,'label');
unlike('foo',qr/f/,'label');
cmp_ok(1,'==',2,'label');
is_deeply([], {},'label');
pass('label');
fail('label');
END_PERL

$policy = 'Testing::RequireTestLabels';
is( pcritique($policy, \$code), 0, $policy );

