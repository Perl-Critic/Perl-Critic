##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Perl::Critic::Utils qw{ :characters :severities };
use Perl::Critic::Utils::PPI qw{
    is_ppi_constant_element
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
};
use Readonly;

use base 'Perl::Critic::Policy';

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DOLLAR => q<$>;
# All uses of the $DOLLAR variable below are to prevent false failures in
# xt/author/93_version.t.
Readonly::Scalar my $QV => q<qv>;
Readonly::Scalar my $VERSION_MODULE => q<version>;
Readonly::Scalar my $VERSION_VARIABLE => $DOLLAR . q<VERSION>;

Readonly::Scalar my $DESC => $DOLLAR . q<VERSION value must be a constant>;
Readonly::Scalar my $EXPL => qq<Computed ${DOLLAR}VERSION may tie the code to a single repository, or cause spooky action from a distance>;

#-----------------------------------------------------------------------------

sub supported_parameters { return                            }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Token::Symbol'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Any variable other than $VERSION is ignored.
    $elem or return;
    $VERSION_VARIABLE eq $elem->content() or return;

    # We are only interested in assignments to $VERSION, but it might be a
    # list assignment, so if we do not find an assignment, we move up the
    # parse tree. If we hit a statement (or no parent at all) we do not
    # understand the code to be an assignment statement, and we simply return.
    my $operator;
    $operator = get_next_element_in_same_simple_statement( $elem )
        and $EQUAL eq $operator
        or return;

    # If there is no operand to the right of the assignment, we do not
    # understand the code; simply return.
    my $value = $operator->snext_sibling() or return;

    # If the value is the word 'qv', check to see if there is a 'use version;'
    # on the same line. If so, extract its argument, so it can be subjected to
    # the following rules.
    if ( $value->isa( 'PPI::Token::Word' ) and $QV eq $value->content() ) {
        my $module = get_previous_module_used_on_same_line( $elem )
            or return $self->violation( $DESC, $EXPL, $elem );
        $VERSION_MODULE eq $module->content()
            or return $self->violation( $DESC, $EXPL, $elem );
        $value = $value->snext_sibling()
            and $value->isa( 'PPI::Structure::List' )
            and $value = $value->schild( 0 )
            and $value->isa( 'PPI::Statement::Expression' )
            and $value = $value->schild( 0 );
    }

    # If the value is anything but a constant, we cry foul.
    is_ppi_constant_element( $value )
        or return $self->violation( $DESC, $EXPL, $elem );

    # If we have nothing after the value, it is OK.
    my $structure = get_next_element_in_same_simple_statement( $value )
        or return;

    # If we have a semicolon after the value, it is OK.
    $SCOLON eq $structure->content() and return;

    # If there is anything else after the value, we cry foul.
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion - Require $VERSION to be a constant rather than a computed value.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION


The $VERSION variable of a module should be a simple constant - either a
number, a single-quotish string, or a 'use version'-style C<qv()> string.
Computing the version has problems of various severities.

The most benign violation is computing the version from (e.g.) a Subversion
revision number:

 our ($VERSION) = q$REVISION: 42$ =~ /(\d+)/;

The problem here is that the version is tied to a single repository. The code
can not be moved to another repository (even of the same type) without
changing its version, possibly in the wrong direction.


=head1 CONFIGURATION

This policy is not configurable except for the standard options.


=head1 CAVEATS

There will be false negatives if the $VERSION appears on the left-hand side of
a list assignment that assigns to more than one variable, or to C<undef>.

There may be false positives if the $VERSION is assigned the value of a here
document. This will probably remain the case until
L<PPI::Token::HereDoc|PPI::Token::HereDoc> acquires the relevant portions of
the L<PPI::Token::Quote|PPI::Token::Quote> interface.

There will be false positives if $VERSION is assigned the value of a constant
created by the L<Readonly|Readonly> module or the L<constant|constant> pragma,
because the necessary infrastructure appears not to exist, and the author of
the present module lacked the knowledge/expertise/gumption to put it in place.

Currently the idiom

 our $VERSION = '1.005_05';
 $VERSION = eval $VERSION;

will produce a violation on the second line of the example.


=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT

Copyright 2009 Tom Wyant.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :

