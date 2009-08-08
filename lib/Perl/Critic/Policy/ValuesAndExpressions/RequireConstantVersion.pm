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
use Perl::Critic::Utils qw{ :booleans :characters :data_conversion
    :language :severities };
use Perl::Critic::Utils::PPI qw{
    is_ppi_constant_element
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
};
use Readonly;

use base 'Perl::Critic::Policy';

our $VERSION = '1.103';

#-----------------------------------------------------------------------------

Readonly::Scalar my $BIND_REGEX => q<=~>;
Readonly::Scalar my $DOLLAR => q<$>;
# All uses of the $DOLLAR variable below are to prevent false failures in
# xt/author/93_version.t.
Readonly::Scalar my $QV => q<qv>;
Readonly::Scalar my $VERSION_MODULE => q<version>;
Readonly::Scalar my $VERSION_VARIABLE => $DOLLAR . q<VERSION>;

Readonly::Scalar my $DESC => $DOLLAR . q<VERSION value must be a constant>;
Readonly::Scalar my $EXPL => qq<Computed ${DOLLAR}VERSION may tie the code to a single repository, or cause spooky action from a distance>;

#-----------------------------------------------------------------------------

sub supported_parameters { return (
        {
            name    => 'allow_version_without_use_on_same_line',
            description =>
                q{Allow qv() and version->new() without a 'use version' on the same line.},
            default_string => $FALSE,
            behavior => 'boolean',
        }
    );
}
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Token::Symbol'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Any variable other than $VERSION is ignored.
    $elem or return;
    $VERSION_VARIABLE eq $elem->content() or return;

    # Get the next thing (presumably an operator) after $VERSION. The $VERSION
    # might be in a list, so if we get nothing we move upwards until we hit a
    # simple statement. If we have nothing at this point, we do not understand
    # the code, and so we return.
    my $operator;
    $operator = get_next_element_in_same_simple_statement( $elem ) or return;

    # If the next operator is a regex binding, and its other operand is a
    # substitution operator, it is an attempt to modify $VERSION, so we
    # return an error to that effect.
    $self->_validate_operator_bind_regex( $operator, $elem )
        and return $self->violation( $DESC, $EXPL, $elem );

    # If the presumptive operator is not an assignment operator of some sort,
    # we are not modifying $VERSION at all, and so we just return.
    $operator = _check_for_assignment_operator( $operator )
        or return;

    # If there is no operand to the right of the assignment, we do not
    # understand the code; simply return.
    my $value = $operator->snext_sibling() or return;

    # If the value is symbol '$VERSION', just return as we will see it again
    # later.
    $value->isa( 'PPI::Token::Symbol' )
        and $value->content() eq $VERSION_VARIABLE
        and return;

    # If the value is a word, there are a number of acceptable things it could
    # be. Check for these. If there was a problem, return it.
    $value = $self->_validate_word_token( $elem, $value );
    $value->isa( 'Perl::Critic::Exception' ) and return $value;

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

#-----------------------------------------------------------------------------

# Check for an assignment operator. This is made more complicated by the fact
# that PPI parses things like '||=' as two PPI::Token::Operators: '||' and
# '='. So we take the first presumptive operator as an argument. If it is not
# a PPI::Token::Operator, we return. If it's '=', we return it. If it is any
# other operator, we see if the next significant token is '=', and if so
# return that.

sub _check_for_assignment_operator {
    my ( $operator ) = @_;

    $operator->isa( 'PPI::Token::Operator' ) or return;
    $EQUAL eq $operator->content() and return $operator;

    my $next = $operator->snext_sibling() or return;
    $next->isa( 'PPI::Token::Operator' ) or return;
    $EQUAL eq $next->content() and return $next;

    return;
}

#-----------------------------------------------------------------------------

# Validate a bind_regex ('=~') operator appearing after $VERSION. We return
# true if the operator is in fact '=~', and its next sibling isa
# PPI::Token::Regexp::Substitute. Otherwise we return false.

sub _validate_operator_bind_regex {
    my ( $self, $operator, $elem ) = @_;

    # We are not interested in anything but '=~ s/../../'.
    $BIND_REGEX eq $operator->content() or return;
    my $operand = $operator->snext_sibling() or return;
    $operand->isa( 'PPI::Token::Regexp::Substitute' ) or return;

    # The substitution is OK if it is of the form
    # '($var = $VERSION) =~ s/../../'.
    my $thing;
    not $elem->snext_sibling()
        and $thing = $elem->sprevious_sibling()
        and $thing->isa( 'PPI::Token::Operator' )
        and $EQUAL eq $thing
        and $thing = $elem->parent()
        and $thing->isa( 'PPI::Statement' )
        and $thing = $thing->parent()
        and $thing->isa( 'PPI::Structure::List' )
        and return;

    # Anything left is presumed a violation.
    return $TRUE;
}

#-----------------------------------------------------------------------------

# Validating a PPI::Token::Word is a complicated business, so we split it out
# into its own subroutine. The $elem is to be used in forming the error
# message, and the $value is the PPI::Token::Word we just encountered. The
# return is either a PPI::Element for further analysis, or a
# Perl::Critic::Exception to be returned.

sub _validate_word_token {
    my ( $self, $elem, $value ) = @_;

    if ( $value->isa( 'PPI::Token::Word' ) ) {
        my $content = $value->content();

        # If the word is of the form 'v\d+' it may be the first portion of a
        # misparsed (by PPI) v-string. It is really a v-string if the next
        # element is a number. Unless v-strings are allowed, we return an
        # error.
        if ( $content =~ m/ \A v \d+ \z /smx ) {
            $value = $self->_validate_word_vstring( $elem, $value );

        # If the word is 'qv' we suspect use of the version module. If 'use
        # version' appears on the same line, _and_ the remainder of the
        # expression is of the form '(value)', we extract the value for
        # further analysis.
        } elsif ( $QV eq $content ) {
            $value = $self->_validate_word_qv( $elem, $value );

        # If the word is 'version' we suspect use of the version module. Check
        # to see if it is properly used.
        } elsif ( $VERSION_MODULE eq $content ) {
            $value = $self->_validate_word_version( $elem, $value );
        }
    }

    return $value;
}

#-----------------------------------------------------------------------------

# Validate $VERSION = v1.2.3;
# Note that this is needed because PPI mis-parses the 'v1.2.3' construct into
# a word ('v1') and a number of some sort ('.2.3'). This method should only be
# called if it is already known that the $value is a PPI::Token::Word matching
# m/ \A v \d+ \z /smx;

sub _validate_word_vstring {
    my ( $self, $elem, $value ) = @_;

    # Check for the second part of the mis-parsed v-string, flunking if it is
    # not found.
    my $next;
    $next = $value->snext_sibling()
        and $next->isa( 'PPI::Token::Number' )
        or return $self->violation( $DESC, $EXPL, $elem );

    # Return the second part of the v-string for further analysis.
    return $next;
}

#-----------------------------------------------------------------------------

# Validate $VERSION = qv();

sub _validate_word_qv {
    my ( $self, $elem, $value ) = @_;

    # Unless we are specifically allowing this construction without the
    # 'use version;' on the same line, check for it and flunk if we do not
    # find it.
    $self->{_allow_version_without_use_on_same_line} or do {
        my $module = get_previous_module_used_on_same_line( $value )
            or return $self->violation( $DESC, $EXPL, $elem );
        $VERSION_MODULE eq $module->content()
            or return $self->violation( $DESC, $EXPL, $elem );
    };

    # Dig out the first argument of 'qv()', flunking if we can not find it.
    my $next;
    $next = $value->snext_sibling()
        and $next->isa( 'PPI::Structure::List' )
        and $next = $next->schild( 0 )
        and $next->isa( 'PPI::Statement::Expression' )
        and $next = $next->schild( 0 )
        or return $self->violation( $DESC, $EXPL, $elem );

    # Return the qv() argument for further analysis.
    return $next;
}

#-----------------------------------------------------------------------------

# Validate $VERSION = version->new();

sub _validate_word_version {
    my ( $self, $elem, $value ) = @_;

    # Unless we are specifically allowing this construction without the
    # 'use version;' on the same line, check for it and flunk if we do not
    # find it.
    $self->{_allow_version_without_use_on_same_line} or do {
        my $module = get_previous_module_used_on_same_line( $value )
            or return $self->violation( $DESC, $EXPL, $elem );
        $VERSION_MODULE eq $module->content()
            or return $self->violation( $DESC, $EXPL, $elem );
    };

    # Dig out the first argument of '->new()', flunking if we can not find it.
    my $next;
    $next = $value->snext_sibling()
        and $next->isa( 'PPI::Token::Operator' )
        and q{->} eq $next->content()
        and $next = $next->snext_sibling()
        and $next->isa( 'PPI::Token::Word' )
        and q{new} eq $next->content()
        and $next = $next->snext_sibling()
        and $next->isa( 'PPI::Structure::List' )
        and $next = $next->schild( 0 )
        and $next->isa( 'PPI::Statement::Expression' )
        and $next = $next->schild( 0 )
        or return $self->violation( $DESC, $EXPL, $elem );

    # Return the version->new() argument for further analysis.
    return $next;
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
number, a single-quotish string, or a 'use version' object. In the latter case
the 'use version;' must appear on the same line as the object construction.

Computing the version has problems of various severities.

The most benign violation is computing the version from (e.g.) a Subversion
revision number:

 our ($VERSION) = q$REVISION: 42$ =~ /(\d+)/;

The problem here is that the version is tied to a single repository. The code
can not be moved to another repository (even of the same type) without
changing its version, possibly in the wrong direction.

This policy accepts v-strings (C<v1.2.3> or just plain C<1.2.3>), since these
are already flagged by
L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings|Perl::Critic::Policy::ValuesAndExpressions::ProhibitVersionStrings>.


=head1 CONFIGURATION

The proper way to set a module's $VERSION to a C<version> object is to
C<use version;> on the same line of code that assigns the value of $VERSION.
That way, L<ExtUtils::MakeMaker|ExtUtils::MakeMaker> and
L<Module::Build|Module::Build> can extract the version when packaging the
module for CPAN. By default, this policy declares an error if this is not
done.

Should you wish to allow version objects without loading the version module on
the same line, add the following to your configuration file:

 [ValuesAndExpressions::RequireConstantVersion]
 allow_version_without_use_on_same_line = 1


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

