#!perl

##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 9;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

my $code ;
my $policy;
my %config;

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - no vars');

#----------------------------------------------------------------

$code = <<'END_PERL';
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line');

#----------------------------------------------------------------


$code = <<'END_PERL';
#!/usr/bin/perl -w -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - first line, perl arg');

#----------------------------------------------------------------

$code = <<'END_PERL';
#!/usr/bin/perl
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - second line');

#----------------------------------------------------------------

$code = <<'END_PERL';
# comment...
# -*- mode: cperl-mode -*-
foo();
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - second line, no shebang');

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
# Local Variables:
# End:
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - multi-line');

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();

# Local Variables:
# End:
END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 0, $policy.' - multi-line, after page break');

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
# Local Variables:
# End:
END_PERL
$code .= 'A' x 3000;

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - multi-line, too early');

#----------------------------------------------------------------

$code = <<'END_PERL';
foo();
# Local Variables:
# End:

END_PERL

$policy = 'Editor::RequireEmacsFileVariables';
is( pcritique($policy, \$code), 1, $policy.' - multi-line before page break');
