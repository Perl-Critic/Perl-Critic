use warnings;
use strict;
use Test::More;

my @good_requests = (
    '',
    undef,
    'pbp',
    'pbp and danger',
    'pbp and (danger or risky)',
    'not pbp',
);

my @bad_requests = (
    '$foo',
    'exit()',
    'pbp && danger',
    'pbp + danger',
    'pbp cmp danger',
);

plan tests => 1 + @good_requests + @bad_requests;

use_ok('Perl::Critic::ThemeMath');

my %policies = ( eval join q{}, <DATA> );
die $@ if $@;

my %themes;
for my $policy (sort keys %policies) {
    for my $theme_name (@{$policies{$policy}}) {
        push @{$themes{$theme_name}}, $policy;
    }
}
$themes{all} = [sort keys %policies];

for my $request (@good_requests) {
    my $display_request = defined $request ? "'$request'" : '<undef>';
    #diag "request: $display_request\n";
    my @p = Perl::Critic::ThemeMath->_parse_themes($request, \%themes);
    my %p = map { $_ => 1 } @p;
    if (!@p)
    {
        pass("$display_request => none");
    }
    elsif (@p != keys %p) {
        fail("$display_request => got duplicates");
    }
    elsif (@p == @{$themes{all}}) {
        pass("$display_request => all");
    }
    elsif (defined $request && $themes{$request} && @p == @{$themes{$request}}) {
        pass("$display_request => $request");
    }
    else {
        pass("$display_request => (complex)");
        #diag("  $_ => @{$policies{$_}}") for @p;
    }
}

for my $request (@bad_requests) {
    #diag "request: '$request'\n";
    my @p;
    eval {@p = Perl::Critic::ThemeMath->_parse_themes($request, \%themes)};
    ok($@, "invalid request: '$request'");
}

# __DATA__ Generated via 
#  grep -r default_themes lib/Perl/Critic/Policy | perl -lne'm{.*Policy/(.*?)/(.*?)\.pm:.*(qw\(.*?\)).*} && print "\"${1}::$2\" => [$3],"'
__DATA__
"BuiltinFunctions::ProhibitLvalueSubstr" => [qw( unreliable pbp )],
"BuiltinFunctions::ProhibitSleepViaSelect" => [qw( pbp danger )],
"BuiltinFunctions::ProhibitStringyEval" => [qw( pbp danger )],
"BuiltinFunctions::ProhibitUniversalCan" => [qw( unreliable )],
"BuiltinFunctions::ProhibitUniversalIsa" => [qw( unreliable )],
"BuiltinFunctions::RequireBlockGrep" => [qw( risky pbp )],
"BuiltinFunctions::RequireBlockMap" => [qw( risky pbp )],
"BuiltinFunctions::RequireGlobFunction" => [qw( pbp danger )],
"ClassHierarchies::ProhibitAutoloading" => [qw( unreliable pbp )],
"ClassHierarchies::ProhibitExplicitISA" => [qw( unreliable pbp )],
"ClassHierarchies::ProhibitOneArgBless" => [qw( pbp danger )],
"CodeLayout::ProhibitHardTabs" => [qw(cosmetic)],
"CodeLayout::ProhibitParensWithBuiltins" => [qw( pbp cosmetic )],
"CodeLayout::ProhibitQuotedWordLists" => [qw(cosmetic)],
"CodeLayout::RequireTidyCode" => [qw(pbp cosmetic)],
"CodeLayout::RequireTrailingCommas" => [qw(pbp cosmetic)],
"ControlStructures::ProhibitUnreachableCode" => [qw( risky )],
"Documentation::RequirePodAtEnd" => [qw( cosmetic pbp )],
"InputOutput::ProhibitBarewordFileHandles" => [qw( pbp danger )],
"InputOutput::ProhibitInteractiveTest" => [qw( pbp danger )],
"InputOutput::ProhibitOneArgSelect" => [qw( risky pbp )],
"InputOutput::ProhibitReadlineInForLoop" => [qw( risky pbp )],
"InputOutput::ProhibitTwoArgOpen" => [qw(pbp danger security)],
"InputOutput::RequireBracedFileHandleWithPrint" => [qw( pbp cosmetic )],
"Miscellanea::ProhibitFormats" => [qw( unreliable pbp )],
"Modules::ProhibitAutomaticExportation" => [qw( risky )],
"Modules::ProhibitMultiplePackages" => [qw( risky )],
"Modules::RequireBarewordIncludes" => [qw(portability)],
"Modules::RequireEndWithOne" => [qw( risky pbp )],
"Modules::RequireExplicitPackage" => [qw( risky )],
"NamingConventions::ProhibitMixedCaseSubs" => [qw( pbp cosmetic )],
"NamingConventions::ProhibitMixedCaseVars" => [qw( pbp cosmetic )],
"Subroutines::ProhibitBuiltinHomonyms" => [qw( risky pbp )],
"Subroutines::ProhibitExplicitReturnUndef" => [qw(pbp danger)],
"Subroutines::ProhibitSubroutinePrototypes" => [qw(pbp danger)],
"Subroutines::RequireFinalReturn" => [qw( risky pbp )],
"TestingAndDebugging::ProhibitNoStrict" => [qw( pbp danger )],
"TestingAndDebugging::ProhibitNoWarnings" => [qw( risky pbp )],
"TestingAndDebugging::RequireUseStrict" => [qw( pbp danger )],
"TestingAndDebugging::RequireUseWarnings" => [qw( risky pbp )],
"ValuesAndExpressions::ProhibitConstantPragma" => [qw( risky pbp )],
"ValuesAndExpressions::ProhibitInterpolationOfLiterals" => [qw(pbp cosmetic)],
"ValuesAndExpressions::ProhibitLeadingZeros" => [qw( pbp danger )],
"ValuesAndExpressions::ProhibitMixedBooleanOperators" => [qw( risky pbp )],
"ValuesAndExpressions::RequireInterpolationOfMetachars" => [qw(pbp cosmetic)],
"Variables::ProhibitConditionalDeclarations" => [qw( danger )],
"Variables::ProhibitMatchVars" => [qw( risky pbp )],
"Variables::RequireLexicalLoopIterators" => [qw(pbp danger)],
"Variables::RequireNegativeIndices" => [qw( risky pbp )],
