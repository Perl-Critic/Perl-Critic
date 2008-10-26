#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Test::More (tests => 1);
use Perl::Critic::PolicyFactory (test => 1);
use Perl::Critic::Document;
use PPI::Document;

#-----------------------------------------------------------------------------

my $violation_free_code = <<'END_PERL';

$foo = 0;  ## this line is not disabled

## no critic;    #\
$foo = 1;        # |-> this block counts as 3 disabled lines
## use critic;   #/

$foo = 2; ## no critic;

$foo = 3; ## no critic (MagicNumbers)

sub foo {  ## no critic (ExcessComplexity, BuiltinHomonyms)
    return 1;
}

$foo = 5;  ## this line is not disabled

END_PERL

my $ppi_doc = PPI::Document->new(\$violation_free_code);
my $doc = Perl::Critic::Document->new($ppi_doc);

my @site_policies = Perl::Critic::PolicyFactory::site_policy_names();
$doc->mark_disabled_lines(@site_policies);

my @empty_violation_list = ();
my @got_warnings = $doc->useless_no_critic_warnings(@empty_violation_list);
is(scalar @got_warnings, 7, 'Got correct numer of useless-no-critic warnings.');

#-----------------------------------------------------------------------------
