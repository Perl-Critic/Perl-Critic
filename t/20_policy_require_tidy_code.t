#!perl

##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;

use Perl::Critic::TestUtils qw(pcritique);

use Test::More tests => 6;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy = 'CodeLayout::RequireTidyCode';
my %config;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
$foo= 42;
$bar   =56;
$baz   =   67;
END_PERL

%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    1,
    'Untidy code',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Only one trailing newline
$foo = 42;
$bar = 56;
END_PERL

%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    0,
    'Tidy with one trailing newline',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Two trailing newlines
$foo = 42;
$bar = 56;

END_PERL

%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    0,
    'Tidy with two trailing newlines',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Several trailing newlines
$foo = 42;
$bar = 56;

   


    
  
END_PERL



%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    0,
    'Tidy with several trailing newlines',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
sub foo {
    my $code = <<'TEST';
 foo bar baz
TEST
    $code;
}  
END_PERL

%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    0,
    'Tidy with heredoc',
);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!perl

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
        if 0; # not running under some shell

package main;
END_PERL

%config = (perltidyrc => q{});
is(
    pcritique($policy, \$code, \%config),
    0,
    'Tidy with shell escape',
);

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/20_policy_requiretidycode.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
