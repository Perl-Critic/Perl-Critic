package Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< refaddr >;

use Perl::Critic::Utils qw< :booleans :characters :severities hashify
    precedence_of >;
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => 'Return value of eval not tested.';
## no critic (RequireInterpolationOfMetachars)
Readonly::Scalar my $EXPL =>
    q<You can't depend upon the value of $@/$EVAL_ERROR to tell whether an eval failed.>;
## use critic

Readonly::Hash my %BOOLEAN_OPERATORS => hashify qw< || && // or and >;
Readonly::Hash my %POSTFIX_OPERATORS =>
    hashify qw< for foreach if unless while until >;

Readonly::Scalar my $PRECEDENCE_OF_EQUALS => precedence_of( q{=} );

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

    return if _scan_backwards_for_grep( $elem );    # RT 69489

    if ( $following and $following->isa('PPI::Token::Operator') ) {
        return if $BOOLEAN_OPERATORS{ $following->content() };
        return if q{?} eq $following->content;
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
                return $TRUE if $previous->content() =~ m/= \Z/xms;
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

        # TECHNICAL DEBT: This code is basically shared with
        # ProhibitUnusedCapture.  I don't want to put this code
        # into Perl::Critic::Utils::*, but I don't have time to sort out
        # PPIx::Utilities::Structure::List yet.
        if (
                $parent->isa('PPI::Structure::List')
            and my $parent_statement = $parent->statement()
        ) {
            return $TRUE if
                    $parent_statement->isa('PPI::Statement::Compound')
                and $parent_statement->type() eq 'foreach';
        }

        if ( $parent->isa('PPI::Structure::For') ) {
            my @for_loop_components = $parent->schildren();

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

    my $current_base = $elem;
    while ($TRUE) {
        my $previous = $current_base->sprevious_sibling();
        while ($previous) {
            if (
                    $previous->isa('PPI::Token::Word')
                and $POSTFIX_OPERATORS{ $previous->content() }
            ) {
                return $TRUE
            }
            $previous = $previous->sprevious_sibling();
        } # end while

        my $parent = $current_base->parent() or return;
        if ( $parent->isa('PPI::Statement') ) {
            return if $parent->specialized();

            my $grandparent = $parent->parent() or return;
            return if not $grandparent->isa('PPI::Structure::List');

            $current_base = $grandparent;
        } else {
            $current_base = $parent;
        }

        return if not $current_base->isa('PPI::Structure::List');
    }

    return;
}

#-----------------------------------------------------------------------------

sub _scan_backwards_for_grep {
    my ( $elem ) = @_;

    while ( $elem ) {

        my $parent = $elem->parent();

        while ( $elem = $elem->sprevious_sibling() ) {
            $elem->isa( 'PPI::Token::Word' )
                and 'grep' eq $elem->content()
                and return $TRUE;
            $elem->isa( 'PPI::Token::Operator' )
                and precedence_of( $elem ) >= $PRECEDENCE_OF_EQUALS
                and return $FALSE;
        }

        $elem = $parent;
    }

    return $FALSE;

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

=for stopwords destructors

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireCheckingReturnValueOfEval - You can't depend upon the value of C<$@>/C<$EVAL_ERROR> to tell whether an C<eval> failed.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

A common idiom in perl for dealing with possible errors is to use
C<eval> followed by a check of C<$@>/C<$EVAL_ERROR>:

    eval {
        ...
    };
    if ($EVAL_ERROR) {
        ...
    }

There's a problem with this: the value of C<$EVAL_ERROR> can change
between the end of the C<eval> and the C<if> statement.  The issue is
object destructors:

    package Foo;

    ...

    sub DESTROY {
        ...
        eval { ... };
        ...
    }

    package main;

    eval {
        my $foo = Foo->new();
        ...
    };
    if ($EVAL_ERROR) {
        ...
    }

Assuming there are no other references to C<$foo> created, when the
C<eval> block in C<main> is exited, C<Foo::DESTROY()> will be invoked,
regardless of whether the C<eval> finished normally or not.  If the
C<eval> in C<main> fails, but the C<eval> in C<Foo::DESTROY()>
succeeds, then C<$EVAL_ERROR> will be empty by the time that the C<if>
is executed.  Additional issues arise if you depend upon the exact
contents of C<$EVAL_ERROR> and both C<eval>s fail, because the
messages from both will be concatenated.

Even if there isn't an C<eval> directly in the C<DESTROY()> method
code, it may invoke code that does use C<eval> or otherwise affects
C<$EVAL_ERROR>.

The solution is to ensure that, upon normal exit, an C<eval> returns a
true value and to test that value:

    # Constructors are no problem.
    my $object = eval { Class->new() };

    # To cover the possiblity that an operation may correctly return a
    # false value, end the block with "1":
    if ( eval { something(); 1 } ) {
        ...
    }

    eval {
        ...
        1;
    }
        or do {
            # Error handling here
        };

Unfortunately, you can't use the C<defined> function to test the
result; C<eval> returns an empty string on failure.

Various modules have been written to take some of the pain out of
properly localizing and checking C<$@>/C<$EVAL_ERROR>. For example:

    use Try::Tiny;
    try {
        ...
    } catch {
        # Error handling here;
        # The exception is in $_/$ARG, not $@/$EVAL_ERROR.
    };  # Note semicolon.

"But we don't use DESTROY() anywhere in our code!" you say.  That may
be the case, but do any of the third-party modules you use have them?
What about any you may use in the future or updated versions of the
ones you already use?


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

See thread on perl5-porters starting here:
L<http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2008-06/msg00537.html>.

For a nice, easy, non-magical way of properly handling exceptions, see
L<Try::Tiny|Try::Tiny>.


=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2008-2011 Elliot Shank.

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
