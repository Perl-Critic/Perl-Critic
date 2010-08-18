#!perl

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/branches/Perl-Critic-backlog/t/20_policy_require_interpolation_of_metachars.t $
#     $Date: 2009-09-07 16:19:21 -0500 (Mon, 07 Sep 2009) $
#   $Author: clonezone $
# $Revision: 3629 $
##############################################################################

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw< pcritique >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.105';

#-----------------------------------------------------------------------------

eval {
    require PPIx::Regexp;
    PPIx::Regexp->VERSION( 0.010 );
    1;
} or plan( skip_all =>
    'PPIx::Regexp 0.010 or better required for Subroutines::ProhibitUnusedPrivateSubroutines to look inside regular expressions.'
);

plan tests => 3;

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

# This is in addition to the regular .run file.

my $policy = 'Subroutines::ProhibitUnusedPrivateSubroutines';


my $code = <<'END_PERL';

s/ ( foo ) / _bar( $1 ) /smxe;

sub _bar {
    my ( $foo ) = @_;
    return $foo x 3;
}

END_PERL

my $result = pcritique($policy, \$code);
is(
    $result,
    0,
    'Subroutine called in replacement portion of s/.../.../e',
);


$code = <<'END_PERL';

s/ ( foo ) /@{[ _bar( $1 ) ]}/smx;

sub _bar {
    my ( $foo ) = @_;
    return $foo x 3;
}

END_PERL

$result = pcritique($policy, \$code);
is(
    $result,
    0,
    'Subroutine called in regexp interpolation',
);


$code = <<'END_PERL';

m/ (?{ _foo() }) /smx;

sub _foo {
    return 'bar';
}

END_PERL

$result = pcritique($policy, \$code);
is(
    $result,
    0,
    'Subroutine called in regexp embedded code',
);


#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
