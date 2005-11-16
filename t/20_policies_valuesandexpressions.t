##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 28;
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
print "this is literal";
print qq{this is literal};
END_PERL

$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------
$code = <<'END_PERL';
print 'this is literal';
print q{this is literal};
END_PERL

$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq( qq{ qq[ qq/'); 
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq( qq{'); 
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => '() {}'); #Testing odd config
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$sql = qq(select foo from bar);
$sql = qq{select foo from bar};
$sql = qq[select foo from bar];
$sql = qq/select foo from bar/;
END_PERL

%config = (allow => 'qq() qq{}'); #Testing odd config
$policy = 'ValuesAndExpressions::ProhibitInterpolationOfLiterals';
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print 'this is not $literal';
print q{this is not $literal};
print 'this is not literal\n';
print q{this is not literal\n};
END_PERL

$policy = 'ValuesAndExpressions::RequireInterpolationOfMetachars';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print "this is not $literal";
print qq{this is not $literal};
print "this is not literal\n";
print qq{this is not literal\n};
END_PERL

$policy = 'ValuesAndExpressions::RequireInterpolationOfMetachars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 01;
$var = 010;
$var = 001;
$var = 0010;
$var = 0.12;
$var = 00.001;
$var = -01;
$var = -010;
$var = -001;
$var = -0010;
$var = -0.12;
$var = -00.001;
$var = +01;
$var = +010;
$var = +001;
$var = +0010;
$var = +0.12;
$var = +00.001;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitLeadingZeros';
is( pcritique($policy, \$code), 18, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 0;
$var = 0.;
$var = 10;
$var = 0.0;
$var = 10.0;
$var = -0;
$var = -0.;
$var = -10;
$var = -0.0;
$var = -10.0;
$var = +0;
$var = +0.;
$var = +10;
$var = +0.0;
$var = +10.0;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitLeadingZeros';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 1234_567;
$var = 1234_567.;
$var = 1234_567.890;
$var = -1234_567.8901;
$var = -1234_567;
$var = -1234_567.;
$var = -1234_567.890;
$var = -1234_567.8901;
$var = +1234_567;
$var = +1234_567.;
$var = +1234_567.890;
$var = +1234_567.8901;

END_PERL

$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code), 12, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 12;
$var = 1234;
$var = 1_234;
$var = 1_234.01;
$var = 1_234_567;
$var = 1_234_567.;
$var = 1_234_567.890_123;
$var = -1_234;
$var = -1_234.01;
$var = -1_234_567;
$var = -1_234_567.;
$var = -1_234_567.890_123;
$var = +1_234;
$var = +1_234.01;
$var = +1_234_567;
$var = +1_234_567.;
$var = +1_234_567.890_123;
END_PERL

$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 1000001;
$var = 1000000.01;
$var = 1000_000.01;
$var = 10000_000.01;
$var = -1000001;
$var = -1234567;
$var = -1000000.01;
$var = -1000_000.01;
$var = -10000_000.01;
END_PERL

%config = (min_value => 1_000_000);
$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code, \%config), 9, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = 999999;
$var = 123456;
$var = 100000.01;
$var = 10_000.01;
$var = 100_000.01;
$var = -999999;
$var = -123456;
$var = -100000.01;
$var = -10_000.01;
$var = -100_000.01;
END_PERL

%config = (min_value => 1_000_000);
$policy = 'ValuesAndExpressions::RequireNumberSeparators';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use constant FOO => 42;
use constant BAR => 24;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitConstantPragma';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $FOO = 42;
local BAR = 24;
our $NUTS = 16;
END_PERL

$policy = 'ValuesAndExpressions::ProhibitConstantPragma';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = "";
$var = ''
$var = '     ';
$var = "     ";
END_PERL

$policy = 'ValuesAndExpressions::ProhibitEmptyQuotes';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = qq{};
$var = q{}
$var = qq{     };
$var = q{     };
END_PERL

$policy = 'ValuesAndExpressions::ProhibitEmptyQuotes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = qq{this};
$var = q{that}
$var = qq{the};
$var = q{other};
$var = "this";
$var = 'that';
$var = 'the'; 
$var = "other";
END_PERL

$policy = 'ValuesAndExpressions::ProhibitEmptyQuotes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = "!";
$var = '!';
$var = '!!';
$var = "||";
END_PERL

$policy = 'ValuesAndExpressions::ProhibitNoisyQuotes';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = q{'};
$var = q{"};
$var = q{!!};
$var = q{||};
$var = "!!!";
$var = '!!!';
$var = 'a';
$var = "a";
$var = '1';
$var = "1";
END_PERL

$policy = 'ValuesAndExpressions::ProhibitNoisyQuotes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$var = '(';
$var = ')';
$var = '{';
$var = '}';
$var = '[';
$var = ']';

$var = '{(';
$var = ')}';
$var = '[{';
$var = '[}';
$var = '[(';
$var = '])';

$var = "(";
$var = ")";
$var = "{";
$var = "}";
$var = "[";
$var = "]";

$var = "{(";
$var = ")]";
$var = "({";
$var = "}]";
$var = "{[";
$var = "]}";
END_PERL

$policy = 'ValuesAndExpressions::ProhibitNoisyQuotes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<END_QUOTE;
Four score and seven years ago...
END_QUOTE
END_PERL

$policy = 'ValuesAndExpressions::RequireQuotedHeredocTerminator';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<'END_QUOTE';
Four score and seven years ago...
END_QUOTE
END_PERL

$policy = 'ValuesAndExpressions::RequireQuotedHeredocTerminator';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<"END_QUOTE";
Four score and seven years ago...
END_QUOTE
END_PERL

$policy = 'ValuesAndExpressions::RequireQuotedHeredocTerminator';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<"endquote";
Four score and seven years ago...
endquote
END_PERL

$policy = 'ValuesAndExpressions::RequireUpperCaseHeredocTerminator';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<endquote;
Four score and seven years ago...
endquote
END_PERL

$policy = 'ValuesAndExpressions::RequireUpperCaseHeredocTerminator';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print <<"QUOTE";
Four score and seven years ago...
QUOTE
END_PERL

$policy = 'ValuesAndExpressions::RequireUpperCaseHeredocTerminator';
is( pcritique($policy, \$code), 0, $policy);
