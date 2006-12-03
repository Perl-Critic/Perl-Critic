#!perl

##############################################################################
#      $URL: $
#     $Date: $
#   $Author: $
# $Revision: $
##############################################################################

use strict;
use warnings;
use Test::More tests => 6;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
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

my $has_perltidy = eval {require Perl::Tidy};
my $expected_result = $has_perltidy ? 1 : 0;
%config = (perltidyrc => q{});
is( pcritique($policy, \$code, \%config), $expected_result, 'Untidy code' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Only one trailing newline
$foo = 42;
$bar = 56;
END_PERL

%config = (perltidyrc => q{});
is( pcritique($policy, \$code, \%config), 0, 'Tidy with one trailing newline' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Two trailing newlines
$foo = 42;
$bar = 56;

END_PERL

%config = (perltidyrc => q{});
is( pcritique($policy, \$code, \%config), 0, 'Tidy with two trailing newlines' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#Several trailing newlines
$foo = 42;
$bar = 56;

   


    
  
END_PERL



%config = (perltidyrc => q{});
is( pcritique($policy, \$code, \%config), 0, 'Tidy with several trailing newlines' );

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
is( pcritique($policy, \$code, \%config), 0, 'Tidy with heredoc' );

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
#!perl

eval 'exec /usr/bin/perl -w -S $0 ${1+"$@"}'
        if 0; # not running under some shell

package main;
END_PERL

%config = (perltidyrc => q{});
is( pcritique($policy, \$code, \%config), 0, 'Tidy with shell escape' );

#-----------------------------------------------------------------------------

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
