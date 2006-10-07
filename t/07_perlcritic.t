#!perl

###############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
###############################################################################

use strict;
use warnings;
use File::Spec;
use English qw(-no_match_vars);
use Test::More tests => 33;

#-----------------------------------------------------------------------------
# Load perlcritic like a library so we can test its subroutines.  If it is not
# found in blib, then use the one in bin (for example, when using 'prove')

my $perlcritic = File::Spec->catfile( qw(blib script perlcritic) );
$perlcritic = File::Spec->catfile( qw(bin perlcritic) ) if ! -e $perlcritic;
require $perlcritic;  ## no critic

# Because bin/perlcritic does not declare a package, it has functions
# in main, just like this test file, so we can use it's functions
# without a prefix.

#-----------------------------------------------------------------------------

local @ARGV = ();
my %options = ();

#-----------------------------------------------------------------------------

@ARGV = qw(-1 -2 -3 -4 -5);
%options = get_options();
is( $options{-severity}, 1);

@ARGV = qw(-5 -3 -4 -1 -2);
%options = get_options();
is( $options{-severity}, 1);

@ARGV = qw();
%options = get_options();
is( $options{-severity}, undef);

@ARGV = qw(-2 -3 -severity 4);
%options = get_options();
is( $options{-severity}, 4);

@ARGV = qw(-severity 2 -3 -4);
%options = get_options();
is( $options{-severity}, 2);

#-----------------------------------------------------------------------------

@ARGV = qw(-top);
%options = get_options();
is( $options{-severity}, 1);
is( $options{-top}, 20);

@ARGV = qw(-top 10);
%options = get_options();
is( $options{-severity}, 1);
is( $options{-top}, 10);

@ARGV = qw(-severity 4 -top);
%options = get_options();
is( $options{-severity}, 4);
is( $options{-top}, 20);

@ARGV = qw(-severity 4 -top 10);
%options = get_options();
is( $options{-severity}, 4);
is( $options{-top}, 10);

@ARGV = qw(-severity 5 -2 -top 5);
%options = get_options();
is( $options{-severity}, 5);
is( $options{-top}, 5);

#-----------------------------------------------------------------------------

@ARGV = qw(-noprofile);
%options = get_options();
is( $options{-profile}, q{});

@ARGV = qw(-profile foo);
%options = get_options();
is( $options{-profile}, 'foo');

#-----------------------------------------------------------------------------

@ARGV = qw(-verbose 2);
%options = get_options();
is( $options{-verbose}, 2);

@ARGV = qw(-verbose %l:%c:%m);
%options = get_options();
is( $options{-verbose}, '%l:%c:%m');

#-----------------------------------------------------------------------------

@ARGV = qw(-quiet);
%options = get_options();
is( $options{-quiet}, 1);

#-----------------------------------------------------------------------------

ok( _interpolate( '\r%l\t%c\n' ) eq "\r%l\t%c\n", 'Interpolation' );
ok( _interpolate( 'literal'    ) eq "literal",    'Interpolation' );

#-----------------------------------------------------------------------------

{
    my @lines = policy_listing();
    my $list = join q{}, @lines;
    cmp_ok(scalar @lines, '>', 70, 'policy_listing');
    like($list, qr/^ \d \s \d \s BuiltinFunctions::/xms, 'policy_listing');
    like($list, qr/^ \d \s \d \s InputOutput::/xms, 'policy_listing');
    like($list, qr/^ \d \s \d \s Variables::/xms, 'policy_listing');
}

#-----------------------------------------------------------------------------
# Intercept pod2usage so we can test invalid options and special switches

{
    no warnings qw(redefine once);
    local *main::pod2usage = sub { my %args = @_; die $args{-message} || q{} };

    eval { @ARGV = qw( -help ); get_options() };
    ok( $EVAL_ERROR, '-help option' );

    eval { @ARGV = qw( -man ); get_options() };
    ok( $EVAL_ERROR, '-man option' );

    eval { @ARGV = qw( -noprofile -profile foo ); get_options() };
    like( $EVAL_ERROR, qr/-noprofile with -profile/, '-noprofile & -profile');

    eval { @ARGV = qw( -verbose bogus ); get_options() };
    like( $EVAL_ERROR, qr/looks odd/, 'Invalid -verbose option' );

    eval { @ARGV = qw( -top -9 ); get_options() };
    like( $EVAL_ERROR, qr/is negative/, 'Negative -verbose option' );

    eval { @ARGV = qw( -severity 0 ); get_options() };
    like( $EVAL_ERROR, qr/out of range/, '-severity too small' );

    eval { @ARGV = qw( -severity 6 ); get_options() };
    like( $EVAL_ERROR, qr/out of range/, '-severity too large' );
}
#-----------------------------------------------------------------------------
