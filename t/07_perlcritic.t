##################################################################
#     $URL$
#    $Date$
#   $Author$
# $Revision$
##################################################################

use strict;
use warnings;
use File::Spec;
use Test::More tests => 21;

#-----------------------------------------------------------------------------
# Load perlcritic like a library so we can test its subroutines.  If it is not
# found in blib, then use the one in bin (for example, when using 'prove')

my $perlcritic = File::Spec->catfile( qw(blib script perlcritic) );
$perlcritic = File::Spec->catfile( qw(bin perlcritic) ) if ! -e $perlcritic;
require $perlcritic;  ## no critic

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

ok( _interpolate( '\r%l\t%c\n' ) eq "\r%l\t%c\n", 'Interpolation' );
ok( _interpolate( 'literal'    ) eq "literal",    'Interpolation' );

#-----------------------------------------------------------------------------
