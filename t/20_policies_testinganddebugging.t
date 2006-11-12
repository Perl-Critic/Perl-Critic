#!perl

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 47;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use warnings;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy.' 1 stmnt before warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
$baz = $nuts;
use warnings;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 2, $policy.' 2 stmnts before warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy.' no warnings at all');

#----------------------------------------------------------------

$code = <<'END_PERL';
require warnings;
1;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy.' require warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
use warnings;

END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' warnings used, but no code');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl -w

END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' warnings used, but no code');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!perl -W

END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' warnings used, but no code');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;

#Should not find the rest of these

__END__

=head1 NAME

Foo - A Foo factory class

=cut

END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy.' no warnings at all, w/ END');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;

#Should not find the rest of these

__DATA__

Fred
Barney
Wilma

END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 1, $policy.' no warnings at all, w/ DATA');

#----------------------------------------------------------------

$code = <<'END_PERL';
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' warnings used');
#----------------------------------------------------------------

$code = <<'END_PERL';
use Module;
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' inclusion stmnt before warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use warnings;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseWarnings';
is( pcritique($policy, \$code), 0, $policy.' package stmnt before warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
use strict;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy.' 1 stmnt before strict' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
$baz = $nuts;
use strict;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 2, $policy.' 2 stmnts before strict' );

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy.' no strict at all');

#----------------------------------------------------------------

$code = <<'END_PERL';
require strict;
1;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy.' require strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;

END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 0, $policy.' strictures used, but no code');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;

#Should not find the rest of these

__END__

=head1 NAME

Foo - A Foo factory class

=cut

END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy.' no strict at all, w/ END');

#----------------------------------------------------------------

$code = <<'END_PERL';
$foo = $bar;

#Should not find the rest of these

__DATA__

Fred
Barney
Wilma

END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 1, $policy.' no strict at all, w/ DATA');

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 0, $policy.' strictures used ok');

#----------------------------------------------------------------

$code = <<'END_PERL';
use Module;
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 0, $policy.' inclusion stmnt before strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package FOO;
use strict;
$foo = $bar;
END_PERL

$policy = 'TestingAndDebugging::RequireUseStrict';
is( pcritique($policy, \$code), 0, $policy.' package stmnt before strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict;
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy.' stricture disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict 'refs', 'vars';
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy.' selective strictures disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code), 1, $policy.' selective strictures disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

%config = (allow => 'vars refs subs');
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 0, $policy.' allowed no strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict "vars", "refs", "subs";
END_PERL

%config = (allow => 'vars refs subs');
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 0, $policy.' allowed no strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict "vars", "refs", 'subs';
END_PERL

%config = (allow => 'VARS SUBS'); #Note wrong case!
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 1, $policy.' partially allowed no strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no strict qw(vars refs subs);
END_PERL

%config = (allow => 'VARS SUBS'); #Note wrong case!
$policy = 'TestingAndDebugging::ProhibitNoStrict';
is( pcritique($policy, \$code, \%config), 1, $policy.' partially allowed no strict');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings;
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy.' warnings disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings 'uninitialized', 'deprecated';
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy.' selective warnings disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(closure glob);
END_PERL

$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code), 1, $policy.' selective warnings disabled');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(glob io once);
END_PERL

%config = (allow => 'iO Glob OnCe');
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 0, $policy.' allow no warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings "numeric", "pack", "portable";
END_PERL

%config = (allow => 'numeric,portable, pack'); #Funky config
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 0, $policy.' allow no warnings');

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings "numeric", "pack", 'portable';
END_PERL

#Note wrong case, funky config...
%config = (allow => 'NumerIC;PORTABLE'); 
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package foo;
no warnings qw(numeric pack portable);
END_PERL

#Note wrong case, funky config...
%config = (allow => 'paCK/PortablE'); 
$policy = 'TestingAndDebugging::ProhibitNoWarnings';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
use Test::More tests => 10;
ok($foo);
ok(!$foo);
is(1,2);
isnt(1,2);
like('foo',qr/f/);
unlike('foo',qr/f/);
cmp_ok(1,'==',2);
is_deeply([], []);
is_deeply({}, {});
pass();
fail();
END_PERL

$policy = 'TestingAndDebugging::RequireTestLabels';
is( pcritique($policy, \$code), 11, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
ok($foo);
ok(!$foo);
is(1,2);
isnt(1,2);
like('foo',qr/f/);
unlike('foo',qr/f/);
cmp_ok(1,'==',2);
is_deeply([], []);
is_deeply({}, {});
pass();
fail();
END_PERL

$policy = 'TestingAndDebugging::RequireTestLabels';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use Test::More tests => 10;
ok($foo,'label');
ok(!$foo,'label');
is(1,2,'label');
isnt(1,2,'label');
like('foo',qr/f/,'label');
unlike('foo',qr/f/,'label');
cmp_ok(1,'==',2,'label');
is_deeply('foo', 'bar','label');
pass('label');
fail('label');
END_PERL

$policy = 'TestingAndDebugging::RequireTestLabels';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use Test::Bar tests => 10;
ok($foo);
END_PERL

%config = (modules => 'Test::Foo Test::Bar'); 
$policy = 'TestingAndDebugging::RequireTestLabels';
is( pcritique($policy, \$code, \%config), 1, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use Test::Baz tests => 10;
ok($foo);
END_PERL

%config = (modules => 'Test::Foo Test::Bar'); 
$policy = 'TestingAndDebugging::RequireTestLabels';
is( pcritique($policy, \$code, \%config), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
no strict;
END_PERL

$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
no strict;
print 1;
print 2;
print 3;
print 4;
END_PERL

$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code), 1, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
no strict;
print 1;
print 2;
print 3;
END_PERL

$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
sub foo {
    no strict;
}
print 1;
print 2;
print 3;
print 4;
END_PERL

$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code), 0, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
sub foo {
    no strict;
    print 1;
    print 2;
    print 3;
    print 4;
}
END_PERL

$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code), 1, $policy );

#----------------------------------------------------------------

$code = <<'END_PERL';
use strict;
sub foo {
    no strict;
    print 1;
    print 2;
    print 3;
    print 4;
    print 5;
    print 6;

END_PERL

%config = ( lines => 6 );
$policy = 'TestingAndDebugging::ProhibitProlongedStrictureOverride';
is( pcritique($policy, \$code, \%config), 0, $policy );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 expandtab
