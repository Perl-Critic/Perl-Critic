##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 6;
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

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ m{pattern}m;
my $string =~ m{pattern}gimx;
my $string =~ m{pattern}gmis;
my $string =~ m{pattern}mgxs;

my $string =~ m/pattern/m;
my $string =~ m/pattern/gimx;
my $string =~ m/pattern/gmis;
my $string =~ m/pattern/mgxs;

my $string =~ /pattern/m;
my $string =~ /pattern/gimx;
my $string =~ /pattern/gmis;
my $string =~ /pattern/mgxs;

my $string =~ s/pattern/foo/m;
my $string =~ s/pattern/foo/gimx;
my $string =~ s/pattern/foo/gmis;
my $string =~ s/pattern/foo/mgxs;
END_PERL

$policy = 'RegularExpressions::RequireLineBoundaryMatching';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ m{pattern};
my $string =~ m{pattern}gix;
my $string =~ m{pattern}gis;
my $string =~ m{pattern}gxs;

my $string =~ m/pattern/;
my $string =~ m/pattern/gix;
my $string =~ m/pattern/gis;
my $string =~ m/pattern/gxs;

my $string =~ /pattern/;
my $string =~ /pattern/gix;
my $string =~ /pattern/gis;
my $string =~ /pattern/gxs;

my $string =~ s/pattern/foo/;
my $string =~ s/pattern/foo/gix;
my $string =~ s/pattern/foo/gis;
my $string =~ s/pattern/foo/gxs;

END_PERL

$policy = 'RegularExpressions::RequireLineBoundaryMatching';
is( pcritique($policy, \$code), 16, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ tr/[A-Z]/[a-z]/;
my $string =~ tr|[A-Z]|[a-z]|;
my $string =~ tr{[A-Z]}{[a-z]};

my $string =~ y/[A-Z]/[a-z]/;
my $string =~ y|[A-Z]|[a-z]|;
my $string =~ y{[A-Z]}{[a-z]};

my $string =~ tr/[A-Z]/[a-z]/cds;
my $string =~ y/[A-Z]/[a-z]/cds;
END_PERL

$policy = 'RegularExpressions::RequireExtendedFormatting';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $string =~ tr/[A-Z]/[a-z]/;
my $string =~ tr|[A-Z]|[a-z]|;
my $string =~ tr{[A-Z]}{[a-z]};

my $string =~ y/[A-Z]/[a-z]/;
my $string =~ y|[A-Z]|[a-z]|;
my $string =~ y{[A-Z]}{[a-z]};

my $string =~ tr/[A-Z]/[a-z]/cds;
my $string =~ y/[A-Z]/[a-z]/cds;
END_PERL

$policy = 'RegularExpressions::RequireLineBoundaryMatching';
is( pcritique($policy, \$code), 0, $policy);
