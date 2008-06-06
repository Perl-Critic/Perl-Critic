#!perl

##############################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##############################################################################

use 5.006001;
use strict;
use warnings;
use File::Spec;
use English qw(-no_match_vars);
use Test::More tests => 36;

#-----------------------------------------------------------------------------
# Load perlcritic like a library so we can test its subroutines.  If it is not
# found in blib, then use the one in bin (for example, when using 'prove')

my $perlcritic = File::Spec->catfile( qw(blib script perlcritic) );
$perlcritic = File::Spec->catfile( qw(bin perlcritic) ) if ! -e $perlcritic;
require $perlcritic;  ## no critic

# Because bin/perlcritic does not declare a package, it has functions
# in main, just like this test file, so we can use its functions
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

@ARGV = qw(--severity=2 -3 -4);
%options = get_options();
is( $options{-severity}, 2);

@ARGV = qw(-cruel);
%options = get_options();
is( $options{-severity}, 'cruel');

@ARGV = qw(-cruel --severity=1);
%options = get_options();
is( $options{-severity}, 1);

@ARGV = qw(-stern --severity=1 -2);
%options = get_options();
is( $options{-severity}, 1);

@ARGV = qw(-stern -severity 1 -2);
%options = get_options();
is( $options{-severity}, 1);

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

@ARGV = qw(-single-policy nowarnings);
%options = get_options();
is( $options{'-single-policy'}, 'nowarnings');

#-----------------------------------------------------------------------------

@ARGV = qw(-verbose 2);
%options = get_options();
is( $options{-verbose}, 2);

@ARGV = qw(-verbose %l:%c:%m);
%options = get_options();
is( $options{-verbose}, '%l:%c:%m');

#-----------------------------------------------------------------------------

@ARGV = qw(-statistics);
%options = get_options();
is( $options{-statistics}, 1);

#-----------------------------------------------------------------------------

@ARGV = qw(-statistics-only);
%options = get_options();
is( $options{'-statistics-only'}, 1);

#-----------------------------------------------------------------------------

@ARGV = qw(-quiet);
%options = get_options();
is( $options{-quiet}, 1);

#-----------------------------------------------------------------------------
# Intercept pod2usage so we can test invalid options and special switches

{
    no warnings qw(redefine once);
    local *main::pod2usage = sub { my %args = @_; die $args{-message} || q{} };

    eval { @ARGV = qw( -help ); get_options() };
    ok( $EVAL_ERROR, '-help option' );

    eval { @ARGV = qw( -options ); get_options() };
    ok( $EVAL_ERROR, '-options option' );

    eval { @ARGV = qw( -man ); get_options() };
    ok( $EVAL_ERROR, '-man option' );

    eval { @ARGV = qw( -noprofile -profile foo ); get_options() };
    like( $EVAL_ERROR, qr/-noprofile with -profile/, '-noprofile with -profile');

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

# ensure we run true if this test is loaded by
# t/07_perlcritic.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
