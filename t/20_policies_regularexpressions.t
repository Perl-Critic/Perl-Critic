##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 2;
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
my $string =~ m{pattern}x;
my $string =~ m{pattern}gimx;
my $string =~ m{pattern}gixs;
my $string =~ m{pattern}xgms;

my $string =~ m/pattern/x;
my $string =~ m/pattern/gimx;
my $string =~ m/pattern/gixs;
my $string =~ m/pattern/xgms;

my $string =~ /pattern/x;
my $string =~ /pattern/gimx;
my $string =~ /pattern/gixs;
my $string =~ /pattern/xgms;

my $string =~ s/pattern/foo/x;
my $string =~ s/pattern/foo/gimx;
my $string =~ s/pattern/foo/gixs;
my $string =~ s/pattern/foo/xgms;
END_PERL

$policy = 'RegularExpressions::RequireExtendedFormatting';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ m{pattern};
my $string =~ m{pattern}gim;
my $string =~ m{pattern}gis;
my $string =~ m{pattern}gms;

my $string =~ m/pattern/;
my $string =~ m/pattern/gim;
my $string =~ m/pattern/gis;
my $string =~ m/pattern/gms;

my $string =~ /pattern/;
my $string =~ /pattern/gim;
my $string =~ /pattern/gis;
my $string =~ /pattern/gms;

my $string =~ s/pattern/foo/;
my $string =~ s/pattern/foo/gim;
my $string =~ s/pattern/foo/gis;
my $string =~ s/pattern/foo/gms;

END_PERL

$policy = 'RegularExpressions::RequireExtendedFormatting';
is( pcritique($policy, \$code), 16, $policy);
