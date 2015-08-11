package Perl::Critic::Policy::ValuesAndExpressions::RequireConstantVersion;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Perl::Critic::Utils qw<
    :booleans :characters :classification :data_conversion :language
    :severities
>;
use Perl::Critic::Utils::PPI qw{
    is_ppi_constant_element
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
};
use Readonly;

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $BIND_REGEX => q<=~>;
Readonly::Scalar my $DOLLAR => q<$>;
# All uses of the $DOLLAR variable below are to prevent false failures in
# xt/author/93_version.t.
Readonly::Scalar my $QV => q<qv>;
Readonly::Scalar my $VERSION_MODULE => q<version>;
Readonly::Scalar my $VERSION_VARIABLE => $DOLLAR . q<VERSION>;

# Operators which would make a new value our of our $VERSION, and therefore
# not modify it. I'm sure this list is not exhaustive. The logical operators
# generally do not qualify for this list. At least, I think not.
Readonly::Hash my %OPERATOR_WHICH_MAKES_NEW_VALUE => hashify( qw{
    = . + - * ** / % ^ ~ & | > < == != >= <= eq ne gt lt ge le
    } );

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
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( core maintenance )     }
sub applies_to           { return 'PPI::Token::Symbol'       }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # Any variable other than $VERSION is ignored.
    return if $VERSION_VARIABLE ne $elem->content();

    # Get the next thing (presumably an operator) after $VERSION. The $VERSION
    # might be in a list, so if we get nothing we move upwards until we hit a
    # simple statement. If we have nothing at this point, we do not understand
    # the code, and so we return.
    my $operator;
    return if
        not $operator = get_next_element_in_same_simple_statement( $elem );

    # If the next operator is a regex binding, and its other operand is a
    # substitution operator, it is an attempt to modify $VERSION, so we
    # return an error to that effect.
    return $self->violation( $DESC, $EXPL, $elem )
        if $self->_validate_operator_bind_regex( $operator, $elem );

    # If the presumptive operator is not an assignment operator of some sort,
    # we are not modifying $VERSION at all, and so we just return.
    return if not $operator = _check_for_assignment_operator( $operator );

    # If there is no operand to the right of the assignment, we do not
    # understand the code; simply return.
    my $value;
    return if not $value = $operator->snext_sibling();

    # If the value is symbol '$VERSION', just return as we will see it again
    # later.
    return if
            $value->isa( 'PPI::Token::Symbol' )
        and $value->content() eq $VERSION_VARIABLE;

    # If the value is a word, there are a number of acceptable things it could
    # be. Check for these. If there was a problem, return it.
    $value = $self->_validate_word_token( $elem, $value );
    return $value if $value->isa( 'Perl::Critic::Exception' );

    # If the value is anything but a constant, we cry foul.
    return $self->violation( $DESC, $EXPL, $elem )
        if not is_ppi_constant_element( $value );

    # If we have nothing after the value, it is OK.
    my $structure;
    return if
        not $structure = get_next_element_in_same_simple_statement( $value );

    # If we have a semicolon after the value, it is OK.
    return if $SCOLON eq $structure->content();

    # If there is anything else after the value, we cry foul.
    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# Check if the element is an assignment operator. 

sub _check_for_assignment_operator {
    my ( $operator ) = @_;

    return if not $operator->isa( 'PPI::Token::Operator' );
    return $operator if is_assignment_operator($operator->content());
    return;
}

#-----------------------------------------------------------------------------

# Validate a bind_regex ('=~') operator appearing after $VERSION. We return
# true if the operator is in fact '=~', and its next sibling isa
# PPI::Token::Regexp::Substitute. Otherwise we return false.

sub _validate_operator_bind_regex {
    my ( $self, $operator, $elem ) = @_;

    # We are not interested in anything but '=~ s/../../'.
    return if $BIND_REGEX ne $operator->content();
    my $operand;
    return if not $operand = $operator->snext_sibling();
    return if not $operand->isa( 'PPI::Token::Regexp::Substitute' );

    # The substitution is OK if it is of the form
    # '($var = $VERSION) =~ s/../../'.

    # We can't look like the desired form if we have a next sig. sib.
    return $TRUE if $elem->snext_sibling();

    # We can't look like the desired form if we are not in a list.
    my $containing_list;
    $containing_list = $elem->parent()
        and $containing_list->isa( 'PPI::Statement' )
        and $containing_list = $containing_list->parent()
        and $containing_list->isa( 'PPI::Structure::List' )
        or return $TRUE;

    # If we have no prior element, we're ( $VERSION ) =~ s/../../,
    # which flunks.
    my $prior = $elem->sprevious_sibling() or return $TRUE;

    # If the prior element is an operator which makes a new value, we pass.
    return if $prior->isa( 'PPI::Token::Operator' )
        && $OPERATOR_WHICH_MAKES_NEW_VALUE{ $prior->content() };

    # Now things get complicated, as RT #55600 shows. We need to grub through
    # the entire list, looking for something that looks like a subroutine
    # call, but without parens around the argument list. This catches the
    # ticket's case, which was
    # ( $foo = sprintf '%s/%s', __PACKAGE__, $VERSION ) =~ s/../../.
    my $current = $prior;
    while( $prior = $current->sprevious_sibling() ) {
        $prior->isa( 'PPI::Token::Word' ) or next;
        is_function_call( $prior) or next;
        # If this function has its own argument list, we need to keep looking;
        # otherwise we have found a function with no parens, and we can
        # return.
        $current->isa( 'PPI::Structure::List' )
            or return;
    } continue {
        $current = $prior;
    }

    # Maybe the whole list was arguments for a subroutine or method call.
    $prior = $containing_list->sprevious_sibling()
        or return $TRUE;
    if ( $prior->isa( 'PPI::Token::Word' ) ) {
        return if is_method_call( $prior );
        return if is_function_call( $prior );
    }

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
        }
        elsif ( $QV eq $content ) {
            # If the word is 'qv' we suspect use of the version module. If
            # 'use version' appears on the same line, _and_ the remainder of
            # the expression is of the form '(value)', we extract the value
            # for further analysis.

            $value = $self->_validate_word_qv( $elem, $value );
        }
        elsif ( $VERSION_MODULE eq $content ) {
            # If the word is 'version' we suspect use of the version module.
            # Check to see if it is properly used.
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
    return $self->violation( $DESC, $EXPL, $elem )
        if
                not $next = $value->snext_sibling()
            or  not $next->isa( 'PPI::Token::Number' );

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
    $self->{_allow_version_without_use_on_same_line}
        or do {
            my $module;
            return $self->violation( $DESC, $EXPL, $elem )
                if not
                    $module = get_previous_module_used_on_same_line($value);
            return $self->violation( $DESC, $EXPL, $elem )
                if $VERSION_MODULE ne $module->content();
        };

    # Dig out the first argument of 'qv()', flunking if we can not find it.
    my $next;
    return $self->violation( $DESC, $EXPL, $elem )
        if not (
                $next = $value->snext_sibling()
            and $next->isa( 'PPI::Structure::List' )
            and $next = $next->schild( 0 )
            and $next->isa( 'PPI::Statement::Expression' )
            and $next = $next->schild( 0 )
        );

    # Return the qv() argument for further analysis.
    return $next;
}

#-----------------------------------------------------------------------------

# Validate $VERSION = version->new();

# TODO: Fix this EVIL dual-purpose return value.  This is ugggggleeeee.
sub _validate_word_version {
    my ( $self, $elem, $value ) = @_;

    # Unless we are specifically allowing this construction without the
    # 'use version;' on the same line, check for it and flunk if we do not
    # find it.
    $self->{_allow_version_without_use_on_same_line}
        or do {
            my $module;
            return $self->violation( $DESC, $EXPL, $elem )
                if not
                    $module = get_previous_module_used_on_same_line($value);
            return $self->violation( $DESC, $EXPL, $elem )
                if $VERSION_MODULE ne $module->content();
        };

    # Dig out the first argument of '->new()', flunking if we can not find it.
    my $next;
    return $next if
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
        and $next = $next->schild( 0 );

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

Copyright (c) 2009-2011 Tom Wyant.

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
