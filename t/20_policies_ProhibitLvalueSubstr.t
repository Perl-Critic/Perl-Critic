#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use strict;
use warnings;
use Test::More tests => 5;

# common P::C testing tools
use Perl::Critic::TestUtils qw(pcritique);
Perl::Critic::TestUtils::block_perlcriticrc();

#-----------------------------------------------------------------------------
# Begin...

test_substr_as_lvalue();
test_4_arg_substr();
test_substr_as_lvalue();
test_substr_as_hash_rvalue();
test_substr_as_bareword();
exit;

#-----------------------------------------------------------------------------

sub test_substr_as_lvalue {

    my $code = <<'END_PERL';
substr( $foo, 2, 1 ) = 'XYZ';
END_PERL

    my $policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
    is( pcritique($policy, \$code), 1, $policy.' lvalue' );
}

#-----------------------------------------------------------------------------

sub test_4_arg_substr {

    my $code = <<'END_PERL';
substr $foo, 2, 1, 'XYZ';
END_PERL

    my $policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
    is( pcritique($policy, \$code), 0, $policy.' 4 arg substr' );
}

#-----------------------------------------------------------------------------

sub test_substr_as_rvalue {

    my $code = <<'END_PERL';
$bar = substr( $foo, 2, 1 );
END_PERL

    my $policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
    is( pcritique($policy, \$code), 0, $policy.' rvalue' );
}

#-----------------------------------------------------------------------------

sub test_substr_as_hash_rvalue {

    my $code = <<'END_PERL';
%bar = ( foobar => substr( $foo, 2, 1 ) );
END_PERL

    my $policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
    is( pcritique($policy, \$code), 0, $policy.' hash rvalue' );
}

#-----------------------------------------------------------------------------

sub test_substr_as_bareword {

    my $code = <<'END_PERL';
$foo{substr};
END_PERL

    my $policy = 'BuiltinFunctions::ProhibitLvalueSubstr';
    is( pcritique($policy, \$code), 0, $policy.' substr as word' );
}

#-----------------------------------------------------------------------------
