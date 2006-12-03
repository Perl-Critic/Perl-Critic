#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 4;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
tie $scalar, 'Some::Class';
tie @array, 'Some::Class';
tie %hash, 'Some::Class';

tie ($scalar, 'Some::Class');
tie (@array, 'Some::Class');
tie (%hash, 'Some::Class');

tie $scalar, 'Some::Class', @args;
tie @array, 'Some::Class', @args;
tie %hash, 'Some::Class' @args;

tie ($scalar, 'Some::Class', @args);
tie (@array, 'Some::Class', @args);
tie (%hash, 'Some::Class', @args);
END_PERL

$policy = 'Miscellanea::ProhibitTies';
is( pcritique($policy, \$code, \%config), 12, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
$hash{tie} = 'foo';
%hash = ( tie => 'knot' );
$object->tie();
END_PERL

$policy = 'Miscellanea::ProhibitTies';
is( pcritique($policy, \$code, \%config), 0, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
format STDOUT =
@<<<<<<   @||||||   @>>>>>>
"left",   "middle", "right"
.

format =
@<<<<<<   @||||||   @>>>>>>
"foo",   "bar",     "baz"
.

format REPORT_TOP =
                                Passwd File
Name                Login    Office   Uid   Gid Home
------------------------------------------------------------------
.
format REPORT =
@<<<<<<<<<<<<<<<<<< @||||||| @<<<<<<@>>>> @>>>> @<<<<<<<<<<<<<<<<<
$name,              $login,  $office,$uid,$gid, $home
.

END_PERL

$policy = 'Miscellanea::ProhibitFormats';
is( pcritique($policy, \$code, \%config), 4, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
$hash{format} = 'foo';
%hash = ( format => 'baz' );
$object->format();
END_PERL

$policy = 'Miscellanea::ProhibitFormats';
is( pcritique($policy, \$code, \%config), 0, $policy);

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
