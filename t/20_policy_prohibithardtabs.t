#!perl

##############################################################################
#      $URL: $
#     $Date: $
#   $Author: $
# $Revision: $
##############################################################################

use strict;
use warnings;
use Test::More tests => 5;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

# This specific policy is being tested without run.t because the .run file
# would have to contain invisible characters.

my $code;
my $policy = 'CodeLayout::ProhibitHardTabs';
my %config;

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

\t\t\t;

END_PERL

is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!
print "\t  \t  foobar  \t";
END_PERL

is( pcritique($policy, \$code), 1, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
\tfor(1){
\t\tdo_something();
\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($policy, \$code, \%config), 3, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
##This will be interpolated!

sub my_sub {
;\tfor(1){
\t\tdo_something();
;\t}
}

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($policy, \$code, \%config), 3, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!

__DATA__
foo\tbar\tbaz
\tfred\barney

END_PERL

%config = (allow_leading_tabs => 0);
is( pcritique($policy, \$code, \%config), 0, 'Tabs in __DATA__' );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
