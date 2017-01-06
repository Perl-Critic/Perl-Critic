package Perl::Critic::Policy::ValuesAndExpressions::ProhibitMismatchedOperators;
use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q<Mismatched operator>;
Readonly::Scalar my $EXPL => q<Numeric/string operators and operands should match>;

# token compatibility [ numeric, string ]
Readonly::Hash my %TOKEN_COMPATIBILITY => (
    'PPI::Token::Number' => [$TRUE,  $FALSE],
    'PPI::Token::Symbol' => [$TRUE,  $TRUE ],
    'PPI::Token::Quote'  => [$FALSE, $TRUE ],
);

Readonly::Hash my %FILE_OPERATOR_COMPATIBILITY =>
    map {; "-$_" => [$TRUE, $FALSE] }
        qw< r w x o R W X O e z s f d l p S b c t u g k T B M A >;

Readonly::Scalar my $TOKEN_COMPATIBILITY_INDEX_NUMERIC => 0;
Readonly::Scalar my $TOKEN_COMPATIBILITY_INDEX_STRING  => 1;

Readonly::Hash my %OPERATOR_TYPES => (
    # numeric
    (
        map { $_ => $TOKEN_COMPATIBILITY_INDEX_NUMERIC }
            qw[ == != > >= < <= + - * / += -= *= /= ]
    ),
    # string
    map { $_ => $TOKEN_COMPATIBILITY_INDEX_STRING }
        qw< eq ne lt gt le ge . .= >,
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_MEDIUM       }
sub default_themes       { return qw< core bugs certrule >        }
sub applies_to           { return 'PPI::Token::Operator' }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem) = @_;

    my $elem_text = $elem->content();

    return if not exists $OPERATOR_TYPES{$elem_text};

    my $leading_operator = $self->_get_potential_leading_operator($elem)
        or return;

    my $next_elem = $elem->snext_sibling() or return;

    if ( $next_elem->isa('PPI::Token::Operator') ) {
        $elem_text .= $next_elem->content();
        $next_elem = $next_elem->snext_sibling();
    }

    return if not exists $OPERATOR_TYPES{$elem_text};
    my $operator_type = $OPERATOR_TYPES{$elem_text};

    my $leading_operator_compatibility =
        $self->_get_token_compatibility($leading_operator);
    my $next_compatibility = $self->_get_token_compatibility($next_elem);

    return if
            (
                    ! defined $leading_operator_compatibility
                ||  $leading_operator_compatibility->[$operator_type]
            )
        &&  (
                    ! defined $next_compatibility
                ||  $next_compatibility->[$operator_type]
            );

    return if
            $operator_type
        &&  defined $leading_operator_compatibility
        &&  ! $leading_operator_compatibility->[$operator_type]
        &&  $self->_have_stringy_x($leading_operator); # RT 54524

    return $self->violation($DESC, $EXPL, $elem);
}

#-----------------------------------------------------------------------------

sub _get_token_compatibility {
    my ($self, $elem) = @_;

    return $FILE_OPERATOR_COMPATIBILITY{ $elem->content() }
        if $self->_is_file_operator($elem);

    for my $class (keys %TOKEN_COMPATIBILITY) {
        return $TOKEN_COMPATIBILITY{$class} if $elem->isa($class);
    }

    return;
}

#-----------------------------------------------------------------------------

sub _have_stringy_x {
    my ($self, $elem) = @_;

    return if not $elem;

    my $prev_oper = $elem->sprevious_sibling() or return;

    return if not $prev_oper->isa('PPI::Token::Operator');
    return if 'x' ne $prev_oper->content();

    return !! $prev_oper->sprevious_sibling();
}

#-----------------------------------------------------------------------------

sub _get_potential_leading_operator {
    my ($self, $elem) = @_;

    my $previous_element = $elem->sprevious_sibling() or return;

    if ( $self->_get_token_compatibility($previous_element) ) {
        my $previous_sibling = $previous_element->sprevious_sibling();
        if (
            $previous_sibling and $self->_is_file_operator($previous_sibling)
        ) {
            $previous_element = $previous_sibling;
        }
    }

    return $previous_element;
}

#-----------------------------------------------------------------------------

sub _is_file_operator {
    my ($self, $elem) = @_;

    return if not $elem;
    return if not $elem->isa('PPI::Token::Operator');
    return !! $FILE_OPERATOR_COMPATIBILITY{ $elem->content() }
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitMismatchedOperators - Don't mix numeric operators with string operands, or vice-versa.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using the wrong operator type for a value can obscure coding intent
and possibly lead to subtle errors.  An example of this is mixing a
string equality operator with a numeric value, or vice-versa.

    if ($foo == 'bar') {}     #not ok
    if ($foo eq 'bar') {}     #ok
    if ($foo eq 123) {}       #not ok
    if ($foo == 123) {}       #ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

If L<warnings|warnings> are enabled, the Perl interpreter usually
warns you about using mismatched operators at run-time.  This Policy
does essentially the same thing, but at author-time.  That way, you
can find out about them sooner.


=head1 AUTHOR

Peter Guzis <pguzis@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Peter Guzis.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
