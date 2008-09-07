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

use English qw(-no_match_vars);
use Carp qw< confess >;

use File::Spec;

use Perl::Critic::Utils qw< :characters >;

use Test::More tests => 37;

#-----------------------------------------------------------------------------

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

# Load perlcritic like a library so we can test its subroutines.  If it is not
# found in blib, then use the one in bin (for example, when using 'prove')

my $perlcritic = File::Spec->catfile( qw(blib script perlcritic) );
if (not -e $perlcritic) {
    $perlcritic = File::Spec->catfile( qw(bin perlcritic) )
}
require $perlcritic;  ## no critic

# Because bin/perlcritic does not declare a package, it has functions
# in main, just like this test file, so we can use its functions
# without a prefix.

#-----------------------------------------------------------------------------

local @ARGV = ();
my $message;
my %options = ();

#-----------------------------------------------------------------------------

local @ARGV = qw(-1 -2 -3 -4 -5);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-5 -3 -4 -1 -2);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw();
%options = get_options();
is( $options{-severity}, undef, 'no arguments');

local @ARGV = qw(-2 -3 -severity 4);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 4, $message);

local @ARGV = qw(-severity 2 -3 -4);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 2, $message);

local @ARGV = qw(--severity=2 -3 -4);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 2, $message);

local @ARGV = qw(-cruel);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 'cruel', $message);

local @ARGV = qw(-cruel --severity=1 );
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-stern --severity=1 -2);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-stern -severity 1 -2);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-top);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-top 10);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 1, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-severity 4 -top);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 4, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-severity 4 -top 10);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 4, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-severity 5 -2 -top 5);
$message = "@ARGV";
%options = get_options();
is( $options{-severity}, 5, $message);
is( $options{-top}, 5, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-noprofile);
$message = "@ARGV";
%options = get_options();
is( $options{-profile}, q{}, $message);

local @ARGV = qw(-profile foo);
$message = "@ARGV";
%options = get_options();
is( $options{-profile}, 'foo', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-single-policy nowarnings);
$message = "@ARGV";
%options = get_options();
is( $options{'-single-policy'}, 'nowarnings', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-verbose 2);
$message = "@ARGV";
%options = get_options();
is( $options{-verbose}, 2, $message);

local @ARGV = qw(-verbose %l:%c:%m);
%options = get_options();
is( $options{-verbose}, '%l:%c:%m', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics);
$message = "@ARGV";
%options = get_options();
is( $options{-statistics}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics-only);
$message = "@ARGV";
%options = get_options();
is( $options{'-statistics-only'}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-quiet);
$message = "@ARGV";
%options = get_options();
is( $options{-quiet}, 1, $message);


#-----------------------------------------------------------------------------

local @ARGV = qw(-pager foo);
%options = eval { get_options() };
is( $options{-pager}, 'foo',  "@ARGV" );


#-----------------------------------------------------------------------------
# Intercept pod2usage so we can test invalid options and special switches

{
    no warnings qw(redefine once); ## no critic (ProhibitNoWarnings)
    local *main::pod2usage = sub { my %args = @_; confess $args{-message} || q{} };

    local @ARGV = qw( -help );
    eval { get_options() };
    ok( $EVAL_ERROR, '-help option' );

    local @ARGV = qw( -options );
    eval { get_options() };
    ok( $EVAL_ERROR, '-options option' );

    local @ARGV = qw( -man );
    eval { get_options() };
    ok( $EVAL_ERROR, '-man option' );

    local @ARGV = qw( -noprofile -profile foo );
    eval { get_options() };
    like(
        $EVAL_ERROR,
        qr/-noprofile [ ] with [ ] -profile/xms,
        '-noprofile with -profile',
    );

    local @ARGV = qw( -verbose bogus );
    eval { get_options() };
    like(
        $EVAL_ERROR,
        qr/looks [ ] odd/xms,
        'Invalid -verbose option',
    );

    local @ARGV = qw( -top -9 );
    eval { get_options() };
    like(
        $EVAL_ERROR,
        qr/is [ ] negative/xms,
        'Negative -verbose option',
    );

    local @ARGV = qw( -severity 0 );
    eval { get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-severity too small',
    );

    local @ARGV = qw( -severity 6 );
    eval { get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-severity too large',
    );
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
