##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 61;
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
@list = ('foo', 'bar', 'baz');

@list = ('foo',
	 'bar',
	 'baz');

END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'bee baz');
@list = ('foo, 'bar');
@list = ($foo, 'bar', 'baz');
%hash = ('foo' => 'bar', 'fo' => 'fum');
my_function('foo', 'bar', 'fudge');
foreach ('foo', 'bar', 'nuts'){ do_something($_) }
END_PERL

$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar, 'baz');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ('foo', 'bar', 'baz', 'nuts');
END_PERL

%config = (min_elements => 4);
$policy = 'CodeLayout::ProhibitQuotedWordLists';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $fooBAR;
my ($fooBAR) = 'nuts';
local $FooBar;
our ($FooBAR);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foobar, $fooBAR);
my (%foobar, @fooBAR, $foo);
local ($foobar, $fooBAR);
local (%foobar, @fooBAR, $foo);
our ($foobar, $fooBAR);
our (%foobar, @fooBAR, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $foo_BAR;
my $FOO_BAR;
my $foo_bar;
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my ($foo_BAR, $BAR_FOO);
my ($foo_BAR, $BAR_FOO) = q(this, that);
our (%FOO_BAR, @BAR_FOO);
local ($FOO_BAR, %BAR_foo) = @_;
my ($foo_bar, $foo);
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseVars';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub fooBAR {}
sub FooBar {}
sub Foo_Bar {}
sub FOObar {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo_BAR {}
sub foo_bar {}
sub FOO_bar {}
END_PERL

$policy = 'NamingConventions::ProhibitMixedCaseSubs';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub1 {
	$foo = shift;
	return undef;
}

sub test_sub2 {
	shift || return undef;
}

sub test_sub3 {
	return undef if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub1 {
	$foo = shift;
	return;
}

sub test_sub2 {
	shift || return;
}

sub test_sub3 {
	return if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 ($@) {}
sub my_sub2 (@@) {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 {}
sub my_sub1 {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub open {}
sub map {}
sub eval {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_open {}
sub my_map {}
sub eval2 {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub import {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return {some => [qw(complicated data)], q{ } => /structure/}; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } elsif (2) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

TODO:
{
local $TODO = 'we are not yet detecting ternaries';
$code = <<'END_PERL';
sub foo { 1 ? return : 2 ? return : return; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);
}

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return 1 ? 1 : 2 ? 2 : 3; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { 'Club sandwich'; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

# This one IS valid to a human or an optimizer, but it's too rare and
# too hard to detect so we disallow it

$code = <<'END_PERL';
sub foo { while (1==1) { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { $foo = 'bar'; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use warnings;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageWarnings';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use strict;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Module;
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequirePackageStricture';
is( pcritique($policy, \$code), 0, $policy);

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
