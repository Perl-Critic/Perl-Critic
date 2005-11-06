use strict;
use warnings;
use PPI::Document;
use Test::More tests => 16;

our $VERSION = '0.12_03';
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

