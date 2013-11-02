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

use Perl::Critic::Command qw< run >;
use Perl::Critic::Utils qw< :characters >;

use Test::More tests => 57;

#-----------------------------------------------------------------------------

our $VERSION = '1.121';

#-----------------------------------------------------------------------------

local @ARGV = ();
my $message;
my %options = ();

#-----------------------------------------------------------------------------

local @ARGV = qw(-1 -2 -3 -4 -5);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-5 -3 -4 -1 -2);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw();
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, undef, 'no arguments');

local @ARGV = qw(-2 -3 -severity 4);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 4, $message);

local @ARGV = qw(-severity 2 -3 -4);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 2, $message);

local @ARGV = qw(--severity=2 -3 -4);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 2, $message);

local @ARGV = qw(-cruel);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 'cruel', $message);

local @ARGV = qw(-cruel --severity=1 );
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-stern --severity=1 -2);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);

local @ARGV = qw(-stern -severity 1 -2);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-top);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-top 10);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 1, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-severity 4 -top);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 4, $message);
is( $options{-top}, 20, $message);

local @ARGV = qw(-severity 4 -top 10);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 4, $message);
is( $options{-top}, 10, $message);

local @ARGV = qw(-severity 5 -2 -top 5);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-severity}, 5, $message);
is( $options{-top}, 5, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-noprofile);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-profile}, q{}, $message);

local @ARGV = qw(-profile foo);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-profile}, 'foo', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-single-policy nowarnings);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{'-single-policy'}, 'nowarnings', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-verbose 2);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-verbose}, 2, $message);

local @ARGV = qw(-verbose %l:%c:%m);
%options = Perl::Critic::Command::_get_options();
is( $options{-verbose}, '%l:%c:%m', $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-statistics}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-statistics-only);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{'-statistics-only'}, 1, $message);

#-----------------------------------------------------------------------------

local @ARGV = qw(-quiet);
$message = "@ARGV";
%options = Perl::Critic::Command::_get_options();
is( $options{-quiet}, 1, $message);


#-----------------------------------------------------------------------------

local @ARGV = qw(-pager foo);
$message = "@ARGV";
%options = eval { Perl::Critic::Command::_get_options() };
is( $options{-pager}, 'foo', $message );


#-----------------------------------------------------------------------------

foreach my $severity ([qw{
    -color-severity-highest
    -colour-severity-highest
    -color-severity-5
    -colour-severity-5
    }],
    [qw{
    -color-severity-high
    -colour-severity-high
    -color-severity-4
    -colour-severity-4
    }],
    [qw{
    -color-severity-medium
    -colour-severity-medium
    -color-severity-3
    -colour-severity-3
    }],
    [qw{
    -color-severity-low
    -colour-severity-low
    -color-severity-2
    -colour-severity-2
    }],
    [qw{
    -color-severity-lowest
    -colour-severity-lowest
    -color-severity-1
    -colour-severity-1
    }],
) {
    my $canonical = $severity->[0];
    foreach my $opt (@{ $severity }) {
        local @ARGV = ($opt => 'cyan');
        $message = "@ARGV";
        %options = eval { Perl::Critic::Command::_get_options() };
        is( $options{$canonical}, 'cyan', $message );
    }
}


#-----------------------------------------------------------------------------
# Intercept pod2usage so we can test invalid options and special switches

{
    no warnings qw(redefine once); ## no critic (ProhibitNoWarnings)
    local *Perl::Critic::Command::pod2usage =
        sub { my %args = @_; confess $args{-message} || q{} };

    local @ARGV = qw( -help );
    eval { Perl::Critic::Command::_get_options() };
    ok( $EVAL_ERROR, '-help option' );

    local @ARGV = qw( -options );
    eval { Perl::Critic::Command::_get_options() };
    ok( $EVAL_ERROR, '-options option' );

    local @ARGV = qw( -man );
    eval { Perl::Critic::Command::_get_options() };
    ok( $EVAL_ERROR, '-man option' );

    local @ARGV = qw( -noprofile -profile foo );
    eval { Perl::Critic::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/-noprofile [ ] with [ ] -profile/xms,
        '-noprofile with -profile',
    );

    local @ARGV = qw( -verbose bogus );
    eval { Perl::Critic::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/looks [ ] odd/xms,
        'Invalid -verbose option',
    );

    local @ARGV = qw( -top -9 );
    eval { Perl::Critic::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/is [ ] negative/xms,
        'Negative -verbose option',
    );

    local @ARGV = qw( -severity 0 );
    eval { Perl::Critic::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-severity too small',
    );

    local @ARGV = qw( -severity 6 );
    eval { Perl::Critic::Command::_get_options() };
    like(
        $EVAL_ERROR,
        qr/out [ ] of [ ] range/xms,
        '-severity too large',
    );
}

#-----------------------------------------------------------------------------

# ensure we return true if this test is loaded by
# t/07_command.t_without_optional_dependencies.t
1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
