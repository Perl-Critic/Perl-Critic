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

use English qw< -no_match_vars >;

use Test::More;

#-----------------------------------------------------------------------------

our $VERSION = '1.116';

#-----------------------------------------------------------------------------

use Test::Pod::Coverage 1.04;

{
    # HACK: Perl::Critic::Violation uses Pod::Parser to extract the
    # DIAGNOSTIC section of the POD in each Policy module.  This
    # happens when the Policy first C<uses> the Violation module.
    # Meanwhile, Pod::Coverage also uses Pod::Parser to extract the
    # POD and compare it with the subroutines that are in the symbol
    # table for that module.  For reasons I cannot yet explain, using
    # Pod::Parser twice this way causes the symbol table to get very
    # wacky and this test program dies with "Can't call method 'OPEN'
    # on IO::String at line 1239 of Pod/Parser.pm".

    # For now, my workaround is to temporarily redefine the import()
    # method in the Violation module so that it doesn't do any Pod
    # parsing.  I'll look for a better solution (or file a bug report)
    # when / if I have better understanding of the problem.

    no warnings qw<redefine once>; ## no critic (ProhibitNoWarnings)
    require Perl::Critic::Violation;
    *Perl::Critic::Violation::import = sub { 1 };
}

my @trusted_methods  = get_trusted_methods();
my $method_string = join ' | ', @trusted_methods;
my $trusted_rx = qr{ \A (?: $method_string ) \z }xms;
all_pod_coverage_ok( {trustme => [$trusted_rx]} );

#-----------------------------------------------------------------------------

sub get_trusted_methods {
    return qw(
        new
        initialize_if_enabled
        prepare_to_scan_document
        violates
        applies_to
        is_safe
        default_themes
        default_maximum_violations_per_document
        default_severity
        supported_parameters
        description
        Fields
        got_sigpipe
    );
}

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
