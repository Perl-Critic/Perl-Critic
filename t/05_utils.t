use strict;
use warnings;
use PPI::Document;
use Test::More tests => 31;

our $VERSION = '0.13';
$VERSION = eval $VERSION;  ## no critic

#---------------------------------------------------------------

BEGIN
{
    # Needs to be in BEGIN for global vars
    use_ok('Perl::Critic::Utils');
}

###########################
#  export tests

can_ok('main', 'find_keywords');
can_ok('main', 'is_hash_key');
can_ok('main', 'is_method_call');
can_ok('main', 'parse_arg_list');
can_ok('main', 'is_script');
is($SPACE, ' ', 'character constants');
is((scalar grep {$_ eq 'grep'} @BUILTINS), 1, 'perl builtins');
is((scalar grep {$_ eq 'OSNAME'} @GLOBALS), 1, 'perl globals');

###########################
#  find_keywords tests

sub count_matches { my $val = shift; return defined $val ? scalar @$val : 0; }
is(count_matches(find_keywords(PPI::Document->new(), 'return')), 0, 'find_keywords, no doc');
is(count_matches(find_keywords(PPI::Document->new(\'sub foo { }'), 'return')), 0, 'find_keywords');
is(count_matches(find_keywords(PPI::Document->new(\'sub foo { return 1; }'), 'return')), 1, 'find_keywords');
is(count_matches(find_keywords(PPI::Document->new(\'sub foo { return 0 if @_; return 1; }'), 'return')), 2, 'find_keywords');

###########################
#  is_hash_key tests

{
   my $code = 'sub foo { return $hash1{bar}, $hash2->{baz}; }';
   my $doc = PPI::Document->new(\$code);
   my @words = @{$doc->find('PPI::Token::Word')};
   my @expect = (
      ['sub', 0],
      ['foo', 0],
      ['return', 0],
      ['bar', 1],
      ['baz', 1],
   );
   is(scalar @words, scalar @expect, 'is_hash_key count');
   for my $i (0 .. $#expect)
   {
      is($words[$i], $expect[$i][0], 'is_hash_key word');
      is(is_hash_key($words[$i]), $expect[$i][1], 'is_hash_key boolean');
   }
}

###########################
#  is_script tests

my @good = (
    "#!perl\n",
    "#! perl\n",
    "#!/usr/bin/perl -w\n",
    "#!C:\\Perl\\bin\\perl\n",
    "#!/bin/sh\n",
);

my @bad = (
    "package Foo;\n",
    "\n#!perl\n",
);

for my $code (@good) {
    my $doc = PPI::Document->new(\$code) || die;
    $doc->index_locations();
    ok(is_script($doc), 'is_script, true');
}
for my $code (@bad) {
    my $doc = PPI::Document->new(\$code) || die;
    $doc->index_locations();
    ok(!is_script($doc), 'is_script, false');
}

