package Perl::Critic::Policy::ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions;

use 5.006001;
use strict;
use warnings;
use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Utils qw< :characters :severities :classification hashify >;

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [99];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw< >                      }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core maintenance pbp ) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $token, undef ) = @_;

    return if $token->content() ne 'until' && $token->content() ne 'unless';

    return if is_hash_key($token);
    return if is_subroutine_name($token);
    return if is_method_call($token);
    return if is_included_module_name($token);

    return
        map
            { $self->_violation_for_operator( $_, $token ) }
            _get_negative_operators( $token );
}

#-----------------------------------------------------------------------------

sub _get_negative_operators {
    my ($token) = @_;

    my @operators;
    foreach my $element ( _get_condition_elements($token) ) {
        if ( $element->isa('PPI::Node') ) {
            my $operators = $element->find( \&_is_negative_operator );
            if ($operators) {
                push @operators, @{$operators};
            }
        }
        else {
            if ( _is_negative_operator( undef, $element ) ) {
                push @operators, $element;
            }
        }
    }

    return @operators;
}

#-----------------------------------------------------------------------------

sub _get_condition_elements {
    my ($token) = @_;

    my $statement = $token->statement();
    return if not $statement;

    if ($statement->isa('PPI::Statement::Compound')) {
        my $condition = $token->snext_sibling();

        return if not $condition;
        return if not $condition->isa('PPI::Structure::Condition');

        return ( $condition );
    }

    my @condition_elements;
    my $element = $token;
    while (
            $element = $element->snext_sibling()
        and $element->content() ne $SCOLON
    ) {
        push @condition_elements, $element;
    }

    return @condition_elements;
}

#-----------------------------------------------------------------------------

Readonly::Hash my %NEGATIVE_OPERATORS => hashify(
    qw/
        ! not
        !~ ne !=
        <   >   <=  >=  <=>
        lt  gt  le  ge  cmp
    /
);

sub _is_negative_operator {
    my (undef, $element) = @_;

    return
            $element->isa('PPI::Token::Operator')
        &&  $NEGATIVE_OPERATORS{$element};
}

#-----------------------------------------------------------------------------

sub _violation_for_operator {
    my ($self, $operator, $control_structure) = @_;

    return
        $self->violation(
            qq<Found "$operator" in condition for an "$control_structure">,
            $EXPL,
            $control_structure,
        );
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions - Don't use operators like C<not>, C<!~>, and C<le> within C<until> and C<unless>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

    until ($foo ne 'blah') {          #not ok
        ...
    }

    while ($foo eq 'blah') {          #ok
        ...
    }

A number of people have problems figuring out the meaning of doubly
negated expressions.  C<unless> and C<until> are both negative
constructs, so any negative (e.g. C<!~>) or reversible operators (e.g.
C<le>) included in their conditional expressions are double negations.
Conway considers the following operators to be difficult to understand
within C<unless> and C<until>:

  ! not
  !~ ne !=
  <   >   <=  >=  <=>
  lt  gt  le  ge  cmp



=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks|Perl::Critic::Policy::ControlStructures::ProhibitUnlessBlocks>

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
