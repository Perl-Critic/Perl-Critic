#!perl

##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use Test::More tests => 29;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

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

$foo{return}; # hash key, not keyword
sub foo {return}; # no sibling
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
sub import   { do_something(); }
sub AUTOLOAD { do_something(); }
sub DESTROY  { do_something(); }
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
BEGIN { do_something(); }
INIT  { do_something(); }
CHECK { do_something(); }
END   { do_something(); }
END_PERL

$policy = 'Subroutines::ProhibitBuiltinHomonyms';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { }
sub bar;
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
sub foo { if ($bool) { return; } else { return; } }
sub foo { unless ($bool) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { if ($bool) { return; } elsif ($bool2) { return; } else { return; } }
sub foo { unless ($bool) { return; } elsif ($bool2) { return; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

TODO:{
local $TODO = 'we are not yet detecting ternaries';

$code = <<'END_PERL';
sub foo { 1 ? return : 2 ? return : return; }
END_PERL

#TODO blocks don't seem to work properly with the Test::Harness
#that I have at work. So for now, I'm just going to disable these
#tests.

#$policy = 'Subroutines::RequireFinalReturn';
#is( pcritique($policy, \$code), 0, $policy);
1;

}

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { return 1 ? 1 : 2 ? 2 : 3; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub foo { 1 }
sub foo { 'Club sandwich'; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 2, $policy);

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
sub foo { if ($bool) { } else { } }
sub foo { if ($bool) { $foo = 'bar'; } else { return; } }
sub foo { unless ($bool) { $foo = 'bar'; } else { return; } }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 3, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
BEGIN {
  print 'this should not need a return';
}
INIT {
  print 'nor this';
}
CHECK {
  print 'nor this';
}
END {
  print 'nor this';
}
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

# goto is equivalent to return
$code = <<'END_PERL';
sub foo { goto &bar; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

# next, last are not equivalent to return (and are invalid Perl)
$code = <<'END_PERL';
sub foo { next; }
sub bar { last; }
END_PERL

$policy = 'Subroutines::RequireFinalReturn';
is( pcritique($policy, \$code), 2, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
&function_call();
&my_package::function_call();
&function_call( $args );
&my_package::function_call( %args );
&function_call( &other_call( @foo ), @bar );
&::function_call();
END_PERL

$policy = 'Subroutines::ProhibitAmpersandSigils';
is( pcritique($policy, \$code), 7, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
exists &function_call;
defined &function_call;
\ &function_call;
exists &my_package::function_call;
defined &my_package::function_call;
\ &my_package::function_call;
$$foo; # for Devel::Cover; skip non-backslash casts
END_PERL

$policy = 'Subroutines::ProhibitAmpersandSigils';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
function_call();
my_package::function_call();
function_call( $args );
my_package::function_call( %args );
function_call( other_call( @foo ), @bar );
\&my_package::function_call;
\&function_call;
goto &foo;
END_PERL

$policy = 'Subroutines::ProhibitAmpersandSigils';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub {
    if ( $foo && $bar || $baz ) {
        open my $fh, '<', $file or die $!;
    }
    elsif ( $blah >>= some_function() ) {
        return if $barf;
    }
    else {
        $results = $condition ? 1 : 0;
    }
    croak unless $result;

    while( $condition ){ frobulate() }
    until( $foo > $baz ){ blech() }
}
END_PERL

%config = ( max_mccabe => 11 );
$policy = 'Subroutines::ProhibitExcessComplexity';
is( pcritique($policy, \$code, \%config), 1, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub {
    if ( $foo && $bar || $baz ) {
        open my $fh, '<', $file or die $!;
    }
    elsif ( $blah >>= some_function() ) {
        return if $barf;
    }
    else {
        $results = $condition ? 1 : 0;
    }
    croak unless $result;
}
END_PERL

$policy = 'Subroutines::ProhibitExcessComplexity';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
sub test_sub {
}
END_PERL

$policy = 'Subroutines::ProhibitExcessComplexity';
is( pcritique($policy, \$code), 0, $policy.' no-op sub');

#----------------------------------------------------------------

$code = <<'END_PERL';
Other::Package::_foo();
Other::Package->_bar();
Other::Package::_foo;
Other::Package->_bar;
$self->Other::Package::_baz();
END_PERL

$policy = 'Subroutines::ProtectPrivateSubs';
is( pcritique($policy, \$code), 5, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';
package My::Self::_private;
use My::Self::_private;
require My::Self::_private;
END_PERL

$policy = 'Subroutines::ProtectPrivateSubs';
is( pcritique($policy, \$code), 0, $policy);

#----------------------------------------------------------------

$code = <<'END_PERL';

# This one should be illegal, but it is too hard to distinguish from
# the next one, which is legal
$pkg->_foo();

$self->_bar();
$self->SUPER::_foo();
END_PERL

$policy = 'Subroutines::ProtectPrivateSubs';
is( pcritique($policy, \$code), 0, $policy);

