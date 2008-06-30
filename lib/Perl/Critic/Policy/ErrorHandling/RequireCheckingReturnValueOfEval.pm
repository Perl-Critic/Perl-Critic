##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< refaddr >;

use Perl::Critic::Utils qw< :booleans :characters :severities hashify >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.087';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => 'Return value of eval not tested.';
Readonly::Scalar my $EXPL =>    ## no critic (RequireInterpolationOfMetachars)
    q<You can't depend upon the value of $@/$EVAL_ERROR to tell whether an eval failed.>;

Readonly::Hash my %BOOLEAN_OPERATORS => hashify qw< || && // or and >;
Readonly::Hash my %POSTFIX_OPERATORS =>
    hashify qw< for foreach if unless while until >;

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_MEDIUM   }
sub default_themes       { return qw( core bugs )    }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'eval';

    my $evaluated = $elem->snext_sibling() or return; # Nothing to eval!
    my $following = $evaluated->snext_sibling();

    return if _is_in_right_hand_side_of_assignment($elem);
    return if _is_in_postfix_expression($elem);
    return if
        _is_in_correct_position_in_a_condition_or_foreach_loop_collection(
            $elem,
            $following,
        );

    if (
            $following
        and $following->isa('PPI::Token::Operator')
        and $BOOLEAN_OPERATORS{ $following->content() }
    ) {
        return;
    }

    return $self->violation($DESC, $EXPL, $elem);
}

#-----------------------------------------------------------------------------

sub _is_in_right_hand_side_of_assignment {
    my ($elem) = @_;

    my $previous = $elem->sprevious_sibling();

    if (not $previous) {
        $previous =
            _grandparent_for_is_in_right_hand_side_of_assignment($elem);
    }

    while ($previous) {
        my $base_previous = $previous;

        EQUALS_SCAN:
        while ($previous) {
            if ( $previous->isa('PPI::Token::Operator') ) {
                return $TRUE if $previous->content() eq q<=>;
                last EQUALS_SCAN if _is_effectively_a_comma($previous);
            }
            $previous = $previous->sprevious_sibling();
        }

        $previous =
            _grandparent_for_is_in_right_hand_side_of_assignment($base_previous);
    }

    return;
}

sub _grandparent_for_is_in_right_hand_side_of_assignment {
    my ($elem) = @_;

    my $parent = $elem->parent() or return;
    $parent->isa('PPI::Statement') or return;

    my $grandparent = $parent->parent() or return;

    if (
            $grandparent->isa('PPI::Structure::Constructor')
        or  $grandparent->isa('PPI::Structure::List')
    ) {
        return $grandparent;
    }

    return;
}

#-----------------------------------------------------------------------------

Readonly::Scalar my $CONDITION_POSITION_IN_C_STYLE_FOR_LOOP => 1;

sub _is_in_correct_position_in_a_condition_or_foreach_loop_collection {
    my ($elem, $following) = @_;

    my $parent = $elem->parent();
    while ($parent) {
        if ( $parent->isa('PPI::Structure::Condition') ) {
            return
                _is_in_correct_position_in_a_structure_condition(
                    $elem, $parent, $following,
                );
        }

        if ( $parent->isa('PPI::Structure::ForLoop') ) {
            my @for_loop_components = $parent->schildren();

            return $TRUE if 1 == @for_loop_components;
            my $condition =
                $for_loop_components[$CONDITION_POSITION_IN_C_STYLE_FOR_LOOP]
                or return;

            return _descendant_of($elem, $condition);
        }

        $parent = $parent->parent();
    }

    return;
}

sub _is_in_correct_position_in_a_structure_condition {
    my ($elem, $parent, $following) = @_;

    my $level = $elem;
    while ($level and refaddr $level != $parent) {
        my $cursor = refaddr $elem == refaddr $level ? $following : $level;

        IS_FINAL_EXPRESSION_AT_DEPTH:
        while ($cursor) {
            if ( _is_effectively_a_comma($cursor) ) {
                $cursor = $cursor->snext_sibling();
                while ( _is_effectively_a_comma($cursor) ) {
                    $cursor = $cursor->snext_sibling();
                }

                # Semicolon would be a syntax error here.
                return if $cursor;
                last IS_FINAL_EXPRESSION_AT_DEPTH;
            }

            $cursor = $cursor->snext_sibling();
        }

        my $statement = $level->parent();
        return $TRUE if not $statement; # Shouldn't happen.
        return $TRUE if not $statement->isa('PPI::Statement'); # Shouldn't happen.

        $level = $statement->parent();
        if (
                not $level
            or  (
                    not $level->isa('PPI::Structure::List')
                and not $level->isa('PPI::Structure::Condition')
            )
        ) {
            # Shouldn't happen.
            return $TRUE;
        }
    }

    return $TRUE;
}

# Replace with PPI implementation once it is released.
sub _descendant_of {
    my ($cursor, $potential_ancestor) = @_;

    return $EMPTY if not $potential_ancestor;

    while ( refaddr $cursor != refaddr $potential_ancestor ) {
        $cursor = $cursor->parent() or return $EMPTY;
    }

    return 1;
}

#-----------------------------------------------------------------------------

sub _is_in_postfix_expression {
    my ($elem) = @_;

    my $previous = $elem->sprevious_sibling();
    while ($previous) {
        if (
                $previous->isa('PPI::Token::Word')
            and $POSTFIX_OPERATORS{ $previous->content() }
        ) {
            return $TRUE
        }
        $previous = $previous->sprevious_sibling();
    }

    return;
}

#-----------------------------------------------------------------------------

sub _is_effectively_a_comma {
    my ($elem) = @_;

    return if not $elem;

    return
            $elem->isa('PPI::Token::Operator')
        &&  (
                $elem->content() eq $COMMA
            ||  $elem->content() eq $FATCOMMA
        );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval - You can't depend upon the value of C<$@>/C<$EVAL_ERROR> to tell whether an C<eval> failed.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

See thread on perl5-porters starting here:
L<http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-06/msg00537.html>.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2008 Elliot Shank.  All rights reserved.

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
