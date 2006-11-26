##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 24;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

# These are proxies for a compile test
can_ok('Perl::Critic::Policy::Variables::RequireLexicalLoopIterators', 'violates');
can_ok('Perl::Critic::Policy::Variables::RequireNegativeIndices', 'violates');



#----------------------------------------------------------------

$code = <<'END_PERL';
for $foo ( @list ) {}
foreach $foo ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 2, $policy.'non-lexical iterator' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for my $foo ( @list ) {}
foreach my $foo ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'lexical iterators' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for ( @list ) {}
foreach ( @list ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'$_ iterator' );

#----------------------------------------------------------------

$code = <<'END_PERL';
for ( $i=0; $i<10; $i++ ) {}
while ( $condition ) {}
until ( $condition ) {}
END_PERL

$policy = 'Variables::RequireLexicalLoopIterators';
is( pcritique($policy, \$code), 0, $policy.'Other compounds' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr[-1];
$arr[ -2 ];
$arr[$m-$n];
$arr[@foo-1];
$arr[$#foo-1];
$arr[@$arr-1];
$arr[$#$arr-1];
1+$arr[$#{$arr}-1];
$arr->[-1];
$arr->[ -2 ];
3+$arr->[@foo-1 ];
$arr->[@arr-1 ];
$arr->[ $#foo - 2 ];
$$arr[-1];
$$arr[ -2 ];
$$arr[@foo-1 ];
$$arr[@arr-1 ];
$$arr[ $#foo - 2 ];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr[$#arr];
$arr[$#arr-1];
$arr[ $#arr - 2 ];
$arr[@arr-1];
$arr[@arr - 2];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 5, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
$arr_ref->[$#{$arr_ref}-1];
$arr_ref->[$#$arr_ref-1];
$arr_ref->[@{$arr_ref}-1];
$arr_ref->[@$arr_ref-1];
$$arr_ref[$#{$arr_ref}-1];
$$arr_ref[$#$arr_ref-1];
$$arr_ref[@{$arr_ref}-1];
$$arr_ref[@$arr_ref-1];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 8, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
# These ones are too hard to detect for now; FIXME??
$some->{complicated}->[$data_structure]->[$#{$some->{complicated}->[$data_structure]} -1];
my $ref = $some->{complicated}->[$data_structure];
$some->{complicated}->[$data_structure]->[$#{$ref} -1];
$ref->[$#{$some->{complicated}->[$data_structure]} -1];
END_PERL

$policy = 'Variables::RequireNegativeIndices';
is( pcritique($policy, \$code), 0, $policy.', fixme' );

#----------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 expandtab :
