##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 14;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
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

$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code), 0, $policy );

#-----------------------------------------------------------------------------

$code = <<"END_PERL";
#This will be interpolated!
print "\t  \t  foobar  \t";
END_PERL

$policy = 'CodeLayout::ProhibitHardTabs';
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
$policy = 'CodeLayout::ProhibitHardTabs';
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
$policy = 'CodeLayout::ProhibitHardTabs';
is( pcritique($policy, \$code, \%config), 3, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
open ($foo, $bar);
open($foo, $bar);
uc();
lc();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
open $foo, $bar;
uc $foo;
lc $foo;
my $foo;
my ($foo, $bar);
our ($foo, $bar);
local ($foo $bar);
return ($foo, $bar);
return ();
my_subroutine($foo $bar);
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $obj = SomeClass->new();
$obj->open();
$obj->close();
$obj->prototype();
$obj->delete();
END_PERL

$policy = 'CodeLayout::ProhibitParensWithBuiltins';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, $bar, $baz);
@list = some_function($foo, $bar, $baz);
@list = ($baz);
@list = ();

@list = ($baz
);

@list = ($baz
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz);

@list = ($foo, 
	 $bar, 
	 $baz
	);

@list = ($foo, 
	 $bar, 
	 $baz
);


END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
@list = ($foo, 
	 $bar, 
	 $baz,);

@list = ($foo, 
	 $bar, 
	 $baz,
);

@list = ($foo, 
	 $bar, 
	 $baz,
	);

END_PERL

$policy = 'CodeLayout::RequireTrailingCommas';
is( pcritique($policy, \$code), 0, $policy);

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
