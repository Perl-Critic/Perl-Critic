#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################


use strict;
use warnings;
use Test::More;
use Perl::Critic::TestUtils qw{ should_skip_author_tests get_author_test_skip_message };

#-----------------------------------------------------------------------------

if (should_skip_author_tests()) {
    plan skip_all => get_author_test_skip_message();
}

my $aspell_path = eval q{use Test::Spelling; use File::Which;
                         which('aspell') || die 'no aspell';};
plan skip_all => 'Optional Test::Spelling, File::Which and aspell program required to spellcheck POD' if $@;

add_stopwords(<DATA>);
set_spell_cmd("$aspell_path list");
all_pod_files_spelling_ok();

__DATA__
autoflushes
BBEdit
CGI
CPAN
CVS
Dolan
exponentials
filename
Guzis
HEREDOC
HEREDOCS
HEREDOCs
IDE
Maxia
Mehner
multi-line
namespace
namespaces
PBP
perlcritic
perlcriticrc
PolicyListing
postfix
PPI
Readonly
refactor
refactoring
runtime
sigil
sigils
SQL
STDERR
STDIN
STDOUT
subdirectories
TerMarsch
Thalhammer
TODO
UI
unblessed
vice-versa

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
