#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 24;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique fcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 2, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use Good::Module;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 0, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Demonic::Module
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::/ /Demonic/');
is( pcritique($policy, \$code, \%config), 2, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
use Demonic::Module;
use Acme::Foo;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::/ Demonic::Module /Acme/');
is( pcritique($policy, \$code, \%config), 4, $policy);

#-----------------------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
use Demonic::Module;
use Acme::Foo;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::|Demonic::Module|Acme/');
is( pcritique($policy, \$code, \%config), 4, $policy);

#-----------------------------------------------------------------------------

{
    # Trap warning messages from ProhibitEvilModules
    my $caught_warning = q{};
    local $SIG{__WARN__} = sub { $caught_warning = shift; };
    pcritique($policy, \$code, { modules => '/(/' } );
    like( $caught_warning, qr/Regexp syntax error/, 'Invalid regex config');
}

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
