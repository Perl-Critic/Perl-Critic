#!/usr/bin/perl -w

use warnings;
use strict;
use Test::More;
if (!$ENV{TEST_AUTHOR}) {
    plan skip_all => 'Author test';
}

my $aspell_path = eval q{use Test::Spelling; use File::Which;
                         which('aspell') || die 'no aspell';};
plan skip_all => 'Optional Test::Spelling, File::Which and aspell program required to spellcheck POD' if $@;

add_stopwords(<DATA>);
set_spell_cmd("$aspell_path -l");
all_pod_files_spelling_ok();

__DATA__
autoflushes
CGI
CVS
Dolan
HEREDOC
HEREDOCs
HEREDOCS
IDE
Maxia
Mehner
namespace
namespaces
PBP
perlcritic
perlcriticrc
PPI
refactor
sigil
sigils
SQL
STDERR
STDIN
STDOUT
TerMarsch
Thalhammer
TODO
