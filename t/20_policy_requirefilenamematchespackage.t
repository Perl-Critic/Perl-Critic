#!perl

##############################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_modules.t $
#    $Date: 2006-12-03 23:58:25 -0600 (Sun, 03 Dec 2006) $
#   $Author: petdance $
# $Revision: 1022 $
##############################################################################

use strict;
use warnings;
use Test::More tests => 18;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $policy = 'Modules::RequireFilenameMatchesPackage';

BASIC_CHECKS: {
    my $code = <<'END_PERL';
package Filename::OK;
1;
END_PERL

    my @goodfiles = qw(
        OK.pm
        Filename/OK.pm
        lib/Filename/OK.pm
        blib/lib/Filename/OK.pm
        OK.pl
        Filename-OK-1.00/OK.pm
        Filename-OK/OK.pm
        Foobar-1.00/OK.pm
    );
    for my $file ( @goodfiles ) {
        is( fcritique($policy, \$code, $file), 0, "$policy - $file" );
    }

    my @badfiles = qw(
        Bad.pm
        Filename/Bad.pm
        lib/Filename/BadOK.pm
        ok.pm
        filename/OK.pm
        Foobar/OK.pm
    );
    for my $file ( @badfiles ) {
        is( fcritique($policy, \$code, $file), 1, "$policy - $file" );
    }
}

#-----------------------------------------------------------------------------

APOSTROPHES: {
    my $code = <<'END_PERL';
package D'Oh;
1;
END_PERL

    my @goodfiles = qw( Oh.pm D/Oh.pm );
    for my $file ( @goodfiles ) {
        is( fcritique($policy, \$code, $file), 0, "$policy - $file" );
    }
    my @badfiles = qw( oh.pm d/Oh.pm );
    for my $file ( @badfiles ) {
        is( fcritique($policy, \$code, $file), 1, "$policy - $file" );
    }
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
