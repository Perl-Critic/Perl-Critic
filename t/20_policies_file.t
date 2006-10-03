##################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_testinganddebugging.t $
#     $Date: 2006-10-02 12:48:01 -0500 (Mon, 02 Oct 2006) $
#   $Author: chrisdolan $
# $Revision: 688 $
##################################################################

use strict;
use warnings;
use File::Spec;
use Test::More tests => 18;

# common P::C testing tools
use Perl::Critic::TestUtils qw(fcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
package Filename::OK;
1;
END_PERL

$policy = 'File::RequireFilenameMatchesPackage';
for my $file ( qw( OK.pm
                   Filename/OK.pm
                   lib/Filename/OK.pm
                   blib/lib/Filename/OK.pm
                   OK.pl
                   Filename-OK-1.00/OK.pm
                   Filename-OK/OK.pm
                   Foobar-1.00/OK.pm
                 )) {
   is( fcritique($policy, \$code, $file), 0, $policy.' - '.$file );
}
for my $file ( qw( Bad.pm
                   Filename/Bad.pm
                   lib/Filename/BadOK.pm
                   ok.pm
                   filename/OK.pm
                   Foobar/OK.pm
                 )) {
   is( fcritique($policy, \$code, $file), 1, $policy.' - '.$file );
}

#----------------------------------------------------------------

$code = <<'END_PERL';
package D'Oh;
1;
END_PERL

$policy = 'File::RequireFilenameMatchesPackage';
for my $file ( qw( Oh.pm
                   D/Oh.pm
                 )) {
   is( fcritique($policy, \$code, $file), 0, $policy.' - '.$file );
}
for my $file ( qw( oh.pm
                   d/Oh.pm
                 )) {
   is( fcritique($policy, \$code, $file), 1, $policy.' - '.$file );
}
