##################################################################
#     $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic/t/20_policies_inputoutput.t $
#    $Date: 2005-11-15 22:42:33 -0800 (Tue, 15 Nov 2005) $
#   $Author: thaljef $
# $Revision: 44 $
##################################################################

use strict;
use warnings;
use Test::More tests => 2;
use Perl::Critic::Config;
use Perl::Critic;

# common P::C testing tools
use lib qw(t/tlib);
use PerlCriticTestUtils qw(pcritique);
PerlCriticTestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
%hash   = %{ $some_ref };
@array  = @{ $some_ref };
$scalar = ${ $some_ref };

$some_ref = \%hash;
$some_ref = \@array;
$some_ref = \$scalar;
$some_ref = \&code;
END_PERL

$policy = 'References::RequireCircumfixDereferences';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
%hash   = %$some_ref;
%array  = @$some_ref;
%scalar = $$some_ref;

%hash   = ( %$some_ref );
%array  = ( @$some_ref );
%scalar = ( $$some_ref );
END_PERL

$policy = 'References::RequireCircumfixDereferences';
is( pcritique($policy, \$code), 6, $policy);
