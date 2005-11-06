##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 17;
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
sub test_sub1 {
	$foo = shift;
	return undef;
}

sub test_sub2 {
	shift || return undef;
}

sub test_sub3 {
	return undef if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub1 {
	$foo = shift;
	return;
}

sub test_sub2 {
	shift || return;
}

sub test_sub3 {
	return if $bar;
}

END_PERL

$policy = 'Subroutines::ProhibitExplicitReturnUndef';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 ($@) {}
sub my_sub2 (@@) {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_sub1 {}
sub my_sub1 {}
END_PERL

$policy = 'Subroutines::ProhibitSubroutinePrototypes';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub open {}
sub map {}
sub eval {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub my_open {}
sub my_map {}
sub eval2 {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub import {}
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return {some => [qw(complicated data)], q{ } => /structure/}; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { return; } elsif (2) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

TODO:
{
local $TODO = 'we are not yet detecting ternaries';
$code = <<'END_PERL';
sub foo { 1 ? return : 2 ? return : return; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);
}

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return 1 ? 1 : 2 ? 2 : 3; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { 'Club sandwich'; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

# This one IS valid to a human or an optimizer, but it's too rare and
# too hard to detect so we disallow it

$code = <<'END_PERL';
sub foo { while (1==1) { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if (1) { $foo = 'bar'; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 1, $policy);
