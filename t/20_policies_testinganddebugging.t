##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 34;

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

