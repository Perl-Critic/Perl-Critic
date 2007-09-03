#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;

use lib 't/tlib';

use English qw(-no_match_vars);

use Perl::Critic::TestUtilitiesWithMinimalDependencies qw{
    should_skip_author_tests
    get_author_test_skip_message
    get_skip_all_tests_tap
};

#-----------------------------------------------------------------------------

if ( should_skip_author_tests() ) {
    print get_skip_all_tests_tap(), get_author_test_skip_message(), "\n";
    exit 0;
}

eval <<'END_HIDE_MODULES';
use Test::Without::Module qw{
    File::HomeDir
    File::Which
    IPC::Open2
    Perl::Tidy
    Pod::Spell
    Pod::Spell
    Text::ParseWords
};
END_HIDE_MODULES

if ( $EVAL_ERROR ) {
    print
        get_skip_all_tests_tap(),
        'Test::Without::Module required to test with the ',
        "absence of optional modules\n";
    exit 0;
}


require 't/01_config.t';

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
