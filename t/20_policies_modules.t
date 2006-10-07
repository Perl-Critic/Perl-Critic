#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 54;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
#no package
$some_code = $foo;
END_PERL

$policy = 'Modules::ProhibitMultiplePackages';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
package bar;
package nuts;
$some_code = undef;
END_PERL

$policy = 'Modules::ProhibitMultiplePackages';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
$some_code = undef;
END_PERL

$policy = 'Modules::ProhibitMultiplePackages';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require; #incomplete statement
use;     #incomplete statement
no;      #incomplete statement
{require}; # for Devel::Cover
END_PERL

$policy = 'Modules::RequireBarewordIncludes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require 'Exporter';
require 'My/Module.pl';
use 'SomeModule';
use "OtherModule.pm";
no "Module";
no "Module.pm";
END_PERL

$policy = 'Modules::RequireBarewordIncludes';
is( pcritique($policy, \$code), 6, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use 5.008;
require MyModule;
use MyModule;
no MyModule;
use strict;
END_PERL

$policy = 'Modules::RequireBarewordIncludes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy.' 1 stmnt before package');

#----------------------------------------------------------------

$code = <<'END_PERL';
BEGIN{
    print 'Hello';
    print 'Beginning';
}

package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 3, $policy.' BEGIN block before package');

#----------------------------------------------------------------

$code = <<'END_PERL';
use Some::Module;
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy.' inclusion before package');

#----------------------------------------------------------------

$code = <<'END_PERL';
$baz = $nuts;
print 'whatever';
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 2, $policy.' 2 stmnts before package');

#----------------------------------------------------------------

$code = <<'END_PERL';
print 'whatever';
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 1, $policy.' no package at all');

#----------------------------------------------------------------

$code = <<'END_PERL';

END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 0, $policy.' no statements at all');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 0, $policy.' just a package, no other statements');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
use strict;
$foo = $bar;
END_PERL

$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code), 0, $policy.' package ok');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
$foo = $bar;
package foo;
END_PERL

%config = (exempt_scripts => 1);
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 0, $policy.' scripts exempted');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
use strict;
use warnings;
my $foo = 42;
END_PERL

%config = (exempt_scripts => 0);
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 3, $policy.' scripts not exempted');


#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
package foo;
$foo = $bar;
END_PERL

%config = (exempt_scripts => 0); 
$policy = 'Modules::RequireExplicitPackage';
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Good::Module;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => 'Evil::Module Super::Evil::Module');
is( pcritique($policy, \$code, \%config), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Demonic::Module
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::/ /Demonic/');
is( pcritique($policy, \$code, \%config), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
use Demonic::Module;
use Acme::Foo;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::/ Demonic::Module /Acme/');
is( pcritique($policy, \$code, \%config), 4, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Evil::Module qw(bad stuff);
use Super::Evil::Module;
use Demonic::Module;
use Acme::Foo;
END_PERL

$policy = 'Modules::ProhibitEvilModules';
%config = (modules => '/Evil::|Demonic::Module|Acme/');
is( pcritique($policy, \$code, \%config), 4, $policy);

#----------------------------------------------------------------

{
    # Trap warning messages from ProhibitEvilModules
    my $caught_warning = q{};
    local $SIG{__WARN__} = sub { $caught_warning = shift; };
    pcritique($policy, \$code, { modules => '/(/' } );
    like( $caught_warning, qr/Regexp syntax error/, 'Invalid regex config');
}

#----------------------------------------------------------------

$code = <<'END_PERL';
#Nothing!
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $VERSION = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our ($VERSION) = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$Package::VERSION = 1.0;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use vars '$VERSION';
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use vars qw($VERSION);
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
my $VERSION;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
our $Version;
END_PERL

$policy = 'Modules::RequireVersionVar';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

TODO:
{

    local $TODO = q{"no critic" doesn't work at the document level};

    $code = <<'END_PERL';
#!anything
## no critic (RequireVersionVar)
END_PERL

    $policy = 'Modules::RequireVersionVar';
    is( pcritique($policy, \$code), 0, $policy);
}

#----------------------------------------------------------------

$code = <<'END_PERL';
=pod

=head1 NO CODE IN HERE

=cut
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
__END__
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
__DATA__
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
# The end
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1; # final true value
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1  ;   #With extra space.
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
  1  ;   #With extra space.
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = 2; 1;   #On same line..
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
0;
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
sub foo {}
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
1;
END {}
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
'Larry';
END_PERL

$policy = 'Modules::RequireEndWithOne';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require Exporter;
our @EXPORT = qw(foo bar);
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Exporter;
use vars '@EXPORT';
@EXPORT = qw(foo bar);
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 1, $policy);


#----------------------------------------------------------------

$code = <<'END_PERL';
use base 'Exporter';
@Foo::EXPORT = qw(foo bar);
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
require Exporter;
our @EXPORT_OK = ( '$foo', '$bar' );
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Exporter;
use vars '%EXPORT_TAGS';
%EXPORT_TAGS = ();
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);


#----------------------------------------------------------------

$code = <<'END_PERL';
use base 'Exporter';
@Foo::EXPORT_OK = qw(foo bar);
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use base 'Exporter';
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(foo bar);
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use base 'Exporter';
use vars qw(@EXPORT_TAGS);
%EXPORT_TAGS = ( foo => [ qw(baz bar) ] );
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
print 123; # no exporting at all; for test coverage
END_PERL

$policy = 'Modules::ProhibitAutomaticExportation';
is( pcritique($policy, \$code), 0, $policy);

