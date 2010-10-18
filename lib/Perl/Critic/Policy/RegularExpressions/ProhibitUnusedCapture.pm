##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitUnusedCapture;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use List::MoreUtils qw(none);
use Readonly;
use Scalar::Util qw(refaddr);

use Perl::Critic::Exception::Fatal::Internal qw{ throw_internal };
use Perl::Critic::Utils qw{ :booleans :severities hashify split_nodes_on_comma };
use base 'Perl::Critic::Policy';

our $VERSION = '1.110';

#-----------------------------------------------------------------------------

Readonly::Scalar my $WHILE => q{while};

Readonly::Hash my %CAPTURE_REFERENCE => hashify( qw{ $+ $- } );
Readonly::Hash my %CAPTURE_REFERENCE_ENGLISH => (
    hashify( qw{ $LAST_PAREN_MATCH $LAST_MATCH_START $LAST_MATCH_END } ),
    %CAPTURE_REFERENCE );

Readonly::Scalar my $DESC => q{Only use a capturing group if you plan to use the captured value};
Readonly::Scalar my $EXPL => [252];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                       }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           {
    return qw< PPI::Token::Regexp::Match PPI::Token::Regexp::Substitute >
}

#-----------------------------------------------------------------------------

Readonly::Scalar my $NUM_CAPTURES_FOR_GLOBAL => 100; # arbitrarily large number

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # optimization: don't bother parsing the regexp if there are no parens
    return if 0 > index $elem->content(), '(';

    my $re = $doc->ppix_regexp_from_element( $elem ) or return;
    $re->failures() and return;

    my $ncaptures = $re->max_capture_number() or return;

    my @captures;  # List of expected captures
    $#captures = $ncaptures - 1;

    my %named_captures; # List of expected named captures.
                        # Unlike the numbered capture logic, %named_captures
                        # entries are made undefined when a use of the name is
                        # found. Otherwise two hashes would be needed, one to
                        # become defined when a use is found, and one to hold
                        # the mapping of name to number.
    foreach my $struct ( @{ $re->find( 'PPIx::Regexp::Structure::NamedCapture'
                ) || [] } ) {
        # There can be more than one capture with the same name, so we need to
        # record all of them. There will be duplications if the 'branch reset'
        # "(?| ... )" pattern is used, but this is benign given how numbered
        # captures are recorded.
        push @{ $named_captures{ $struct->name() } ||= [] }, $struct->number();
    }

    # Look for references to the capture in the regex itself
    return if _enough_uses_in_regexp( $re, \@captures, \%named_captures, $doc );

    my $mod = $re->modifier();
    if ($mod and $mod->asserts( 'g' )
            and not _check_if_in_while_condition_or_block( $elem ) ) {
        $ncaptures = $NUM_CAPTURES_FOR_GLOBAL;
        $#captures = $ncaptures - 1;
    }

    return if _enough_assignments($elem, \@captures) && !%named_captures;
    return if _is_in_slurpy_array_context($elem) && !%named_captures;
    return if _enough_magic($elem, $re, \@captures, \%named_captures, $doc);

    return $self->violation( $DESC, $EXPL, $elem );
}

# Find uses of both numbered and named capture variables in the regexp itself.
# Return true if all are used.
sub _enough_uses_in_regexp {
    my ( $re, $captures, $named_captures, $doc ) = @_;

    # Look for references to the capture in the regex itself. Note that this
    # will also find backreferences in the replacement string of s///.
    foreach my $token ( @{ $re->find( 'PPIx::Regexp::Token::Reference' )
            || [] } ) {
        if ( $token->is_named() ) {
            _record_named_capture( $token->name(), $captures, $named_captures );
        } else {
            _record_numbered_capture( $token->absolute(), $captures );
        }
    }

    foreach my $token ( @{ $re->find(
        'PPIx::Regexp::Token::Code' ) || [] } ) {
        my $ppi = $token->ppi() or next;
        my $start = $ppi->schild( 0 ) or next;
        $start = $start->schild( 0 ) or next;
        _mark_magic( $start, $re, $captures, $named_captures, $doc );
        _enough_magic( $start, $re, $captures, $named_captures, $doc );
    }

    return ( none {not defined $_} @{$captures} )
        && ( !%{$named_captures} ||
            none {defined $_} values %{$named_captures} );
}

sub _enough_assignments {
    my ($elem, $captures) = @_;

    # look backward for the assignment operator
    my $psib = $elem->sprevious_sibling;
  SIBLING:
    while (1) {
        return if !$psib;
        if ($psib->isa('PPI::Token::Operator')) {
            last SIBLING if q{=} eq $psib;
            return if q{!~} eq $psib;
        }
        $psib = $psib->sprevious_sibling;
    }

    $psib = $psib->sprevious_sibling;
    return if !$psib;  # syntax error: '=' at the beginning of a statement???

    if ($psib->isa('PPI::Token::Symbol')) {
        # @foo = m/(foo)/
        # @$foo = m/(foo)/
        # %foo = m/(foo)/
        # %$foo = m/(foo)/
        return $TRUE if _symbol_is_slurpy($psib);

    } elsif ($psib->isa('PPI::Structure::Block')) {
        # @{$foo} = m/(foo)/
        # %{$foo} = m/(foo)/
        return $TRUE if _block_is_slurpy($psib);

    } elsif ($psib->isa('PPI::Structure::List')) {
        # () = m/(foo)/
        # ($foo) = m/(foo)/
        # ($foo,$bar) = m/(foo)(bar)/
        # (@foo) = m/(foo)(bar)/
        # ($foo,@foo) = m/(foo)(bar)/
        # ($foo,@$foo) = m/(foo)(bar)/
        # ($foo,@{$foo}) = m/(foo)(bar)/

        my @args = $psib->schildren;
        return $TRUE if not @args;   # empty list (perhaps the "goatse" operator) is slurpy

        # Forward looking: PPI might change in v1.200 so schild(0) is a
        # PPI::Statement::Expression.
        if ( 1 == @args && $args[0]->isa('PPI::Statement::Expression') ) {
            @args = $args[0]->schildren;
        }

        my @parts = split_nodes_on_comma(@args);
      PART:
        for my $i (0 .. $#parts) {
            if (1 == @{$parts[$i]}) {
                my $var = $parts[$i]->[0];
                if ($var->isa('PPI::Token::Symbol') || $var->isa('PPI::Token::Cast')) {
                    return $TRUE if _has_array_sigil($var);
                }
            }
            _record_numbered_capture( $i + 1, $captures );
                    # ith variable capture
        }
    }

    return none {not defined $_} @{$captures};
}

sub _symbol_is_slurpy {
    my ($symbol) = @_;

    return $TRUE if _has_array_sigil($symbol);
    return $TRUE if _has_hash_sigil($symbol);
    return $TRUE if _is_preceded_by_array_or_hash_cast($symbol);
    return;
}

sub _has_array_sigil {
    my ($elem) = @_;  # Works on PPI::Token::Symbol and ::Cast

    return q{@} eq substr $elem->content, 0, 1;
}

sub _has_hash_sigil {
    my ($elem) = @_;  # Works on PPI::Token::Symbol and ::Cast

    return q{%} eq substr $elem->content, 0, 1;
}

sub _block_is_slurpy {
    my ($block) = @_;

    return $TRUE if _is_preceded_by_array_or_hash_cast($block);
    return;
}

sub _is_preceded_by_array_or_hash_cast {
    my ($elem) = @_;
    my $psib = $elem->sprevious_sibling;
    my $cast;
    while ($psib && $psib->isa('PPI::Token::Cast')) {
        $cast = $psib;
        $psib = $psib->sprevious_sibling;
    }
    return if !$cast;
    my $sigil = substr $cast->content, 0, 1;
    return q{@} eq $sigil || q{%} eq $sigil;
}

sub _is_in_slurpy_array_context {
    my ($elem) = @_;

    # return true is the result of the regexp is passed to a subroutine.
    # doesn't check for array context due to assignment.

    # look backward for explict regex operator
    my $psib = $elem->sprevious_sibling;
    if ($psib && $psib eq q{=~}) {
        # Track back through value
        $psib = _skip_lhs($psib);
    }

    if (!$psib) {
        my $parent = $elem->parent;
        return if !$parent;
        if ($parent->isa('PPI::Statement')) {
            $parent = $parent->parent;
            return if !$parent;
        }

        # Return true if we have a list that isn't part of a foreach loop.
        # TECHNICAL DEBT: This code is basically shared with
        # RequireCheckingReturnValueOfEval.  I don't want to put this code
        # into Perl::Critic::Utils::*, but I don't have time to sort out
        # PPIx::Utilities::Structure::List yet.
        if ( $parent->isa('PPI::Structure::List') ) {
            my $parent_statement = $parent->statement() or return $TRUE;
            return $TRUE if not
                $parent_statement->isa('PPI::Statement::Compound');
            return $TRUE if $parent_statement->type() ne 'foreach';
        }

        return $TRUE if $parent->isa('PPI::Structure::Constructor');
        if ($parent->isa('PPI::Structure::Block')) {
            return $TRUE
                if
                        refaddr($elem->statement)
                    eq  refaddr([$parent->schildren]->[-1]);
        }
        return;
    }
    if ($psib->isa('PPI::Token::Operator')) {
        # most operators kill slurpiness (except assignment, which is handled elsewhere)
        return $TRUE if q{,} eq $psib;
        return;
    }
    return $TRUE;
}

sub _skip_lhs {
    my ($elem) = @_;

    # TODO: better implementation to handle casts, expressions, subcalls, etc.
    $elem = $elem->sprevious_sibling();

    return $elem;
}

sub _enough_magic {
    my ($elem, $re, $captures, $named_captures, $doc) = @_;

    _check_for_magic($elem, $re, $captures, $named_captures, $doc);

    return ( none {not defined $_} @{$captures} )
        && ( !%{$named_captures} ||
            none {defined $_} values %{$named_captures} );
}

# void return
sub _check_for_magic {
    my ($elem, $re, $captures, $named_captures, $doc) = @_;

    # Search for $1..$9 in :
    #  * the rest of this statement
    #  * subsequent sibling statements
    #  * if this is in a conditional boolean, the if/else bodies of the conditional
    #  * if this is in a while/for condition, the loop body
    # But NO intervening regexps!

    return if ! _check_rest_of_statement(
        $elem, $re, $captures, $named_captures, $doc);

    my $parent = $elem->parent();
    while ($parent && ! $parent->isa('PPI::Statement::Sub')) {
        return if ! _check_rest_of_statement($parent, $re, $captures,
            $named_captures, $doc);
        $parent = $parent->parent();
    }

    return;
}

# Check if we are in the condition or block of a 'while'
sub _check_if_in_while_condition_or_block {
    my ( $elem ) = @_;
    $elem or return;

    my $parent = $elem->parent() or return;
    $parent->isa( 'PPI::Statement' ) or return;

    my $item = $parent = $parent->parent() or return;
    if ( $item->isa( 'PPI::Structure::Block' ) ) {
        $item = $item->sprevious_sibling() or return;
    }
    $item->isa( 'PPI::Structure::Condition' ) or return;

    $item = $item->sprevious_sibling() or return;
    $item->isa( 'PPI::Token::Word' ) or return;

    return $WHILE eq $item->content();
}

# false if we hit another regexp
sub _check_rest_of_statement {
    my ($elem, $re, $captures, $named_captures, $doc) = @_;

    my $nsib = $elem->snext_sibling;
    while ($nsib) {
        return if $nsib->isa('PPI::Token::Regexp');
        if ($nsib->isa('PPI::Node')) {
            return if ! _check_node_children(
                $nsib, $re, $captures, $named_captures, $doc);
        } else {
            _mark_magic($nsib, $re, $captures, $named_captures, $doc);
        }
        $nsib = $nsib->snext_sibling;
    }
    return $TRUE;
}

# false if we hit another regexp
sub _check_node_children {
    my ($elem, $re, $captures, $named_captures, $doc) = @_;

    # caveat: this will descend into subroutine definitions...

    for my $child ($elem->schildren) {
        return if $child->isa('PPI::Token::Regexp');
        if ($child->isa('PPI::Node')) {
            return if ! _check_node_children($child, $re, $captures,
                $named_captures, $doc);
        } else {
            _mark_magic($child, $re, $captures, $named_captures, $doc);
        }
    }
    return $TRUE;
}

sub _mark_magic {
    my ($elem, $re, $captures, $named_captures, $doc) = @_;

    # Only interested in magic, or known English equivalent.
    my $content = $elem->content();
    my $capture_ref = $doc->uses_module( 'English' ) ?
        \%CAPTURE_REFERENCE_ENGLISH :
        \%CAPTURE_REFERENCE;
    $elem->isa( 'PPI::Token::Magic' )
        or $capture_ref->{$content}
        or return;

    if ( $content =~ m/ \A \$ ( \d+ ) /xms ) {

        # Record if we see $1, $2, $3, ...
        my $num = $1;
        if (0 < $num) { # don't mark $0
            # Only mark the captures we really need -- don't mark superfluous magic vars
            if ($num <= @{$captures}) {
                _record_numbered_capture( $num, $captures );
            }
        }
    } elsif ( $capture_ref->{$content} ) {
        _mark_magic_subscripted_code( $elem, $re, $captures, $named_captures );
    }
    return;
}

# Record a named capture referenced by a hash or array found in code.
# The arguments are:
#    $elem - The element that represents a subscripted capture variable;
#    $re - The PPIx::Regexp object;
#    $captures - A reference to the numbered capture array;
#    $named_captures - A reference to the named capture hash.
sub _mark_magic_subscripted_code {
    my ( $elem, $re, $captures, $named_captures ) = @_;
    my $subscr = $elem->snext_sibling() or return;
    $subscr->isa( 'PPI::Structure::Subscript' ) or return;
    my $subval = $subscr->content();
    _record_subscripted_capture(
        $elem->content(), $subval, $re, $captures, $named_captures );
    return;
}

# Record a subscripted capture, either hash dereference or array
# dereference. We assume that an array represents a numbered capture and
# a hash represents a named capture, since we have to handle (e.g.) both
# @+ and %+.
sub _record_subscripted_capture {
    my ( $variable_name, $suffix, $re, $captures, $named_captures ) = @_;
    if ( $suffix =~ m/ \A [{] ( .*? ) [}] /smx ) {
        ( my $name = $1 ) =~ s/ \A ( ["'] ) ( .*? ) \1 \z /$2/smx;
        _record_named_capture( $name, $captures, $named_captures );
    } elsif ( $suffix =~ m/ \A [[] \s* ( [-+]? \d+ ) \s* []] /smx ) {
        _record_numbered_capture( $1 . q{}, $captures, $re );
    }
    return;
}

# Because a named capture is also one or more numbered captures, the recording
# of the use of a named capture seemed complex enough to wrap in a subroutine.
sub _record_named_capture {
    my ( $name, $captures, $named_captures ) = @_;
    defined ( my $numbers = $named_captures->{$name} ) or return;
    foreach my $capnum ( @{ $numbers } ) {
        _record_numbered_capture( $capnum, $captures );
    }
    $named_captures->{$name} = undef;
    return;
}

sub _record_numbered_capture {
    my ( $number, $captures, $re ) = @_;
    $re and $number < 0
        and $number = $re->max_capture_number() + $number + 1;
    return if $number <= 0;
    $captures->[ $number - 1 ] = 1;
    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords refactored

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitUnusedCapture - Only use a capturing group if you plan to use the captured value.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl regular expressions have multiple types of grouping syntax.  The
basic parentheses (e.g. C<m/(foo)/>) captures into the magic variable
C<$1>.  Non-capturing groups (e.g. C<m/(?:foo)/> are useful because
they have better runtime performance and do not copy strings to the
magic global capture variables.

It's also easier on the maintenance programmer if you consistently use
capturing vs. non-capturing groups, because that programmer can tell
more easily which regexps can be refactored without breaking
surrounding code which may use the captured values.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CAVEATS

=head2 C<qr//> interpolation

This policy can be confused by interpolation of C<qr//> elements, but
those are always false negatives.  For example:

    my $foo_re = qr/(foo)/;
    my ($foo) = m/$foo_re (bar)/x;

A human can tell that this should be a violation because there are two
captures but only the first capture is used, not the second.  The
policy only notices that there is one capture in the regexp and
remains happy.

=head2 C<@->, C<@+>, C<$LAST_MATCH_START> and C<$LAST_MATCH_END>

This policy will only recognize capture groups referred to by these
variables if the use is subscripted by a literal integer.

=head2 C<$^N> and C<$LAST_SUBMATCH_RESULT>

This policy will not recognize capture groups referred to only by these
variables, because there is in general no way by static analysis to
determine which capture group is referred to.  For example,

    m/ (?: (A[[:alpha:]]+) | (N\d+) ) (?{$foo=$^N}) /smx

makes use of the first capture group if it matches, or the second
capture group if the first does not match but the second does.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2010 Chris Dolan.  Many rights reserved.

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
