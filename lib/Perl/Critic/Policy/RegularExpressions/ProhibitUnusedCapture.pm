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
use Readonly;
use List::MoreUtils qw(none);
use Scalar::Util qw(refaddr);

use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities split_nodes_on_comma };
use Perl::Critic::Utils::PPIRegexp qw{ parse_regexp get_match_string get_substitute_string get_modifiers };
use base 'Perl::Critic::Policy';

our $VERSION = '1.093_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Only use a capturing group if you plan to use the captured value};
Readonly::Scalar my $EXPL => [252];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                       }
sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute) }

#-----------------------------------------------------------------------------

Readonly::Scalar my $NUM_CAPTURES_FOR_GLOBAL => 100; # arbitrarily large number

sub violates {
    my ( $self, $elem, undef ) = @_;

    # optimization: don't bother parsing the regexp if there are no parens
    return if $elem !~ m/[(]/xms;

    my $re = parse_regexp($elem);
    return if ! $re;
    my $ncaptures = @{$re->captures};
    return if 0 == $ncaptures;

    my @captures;  # List of expected captures
    $#captures = $ncaptures - 1;

    # Look for references to the capture in the regex itself
    my $iter = $re->walker;
    while (my $token = $iter->()) {
        if ($token->isa('Regexp::Parser::ref')) {
            my ($num) = $token->raw =~ m/ (\d+) /xms;
            $captures[$num-1] = 1;
        }
    }
    my $subst = get_substitute_string($elem);
    if ($subst) {

        # TODO: This is a quick hack.  Really, we should parse the string.  It could
        # be false positive (s///e) or false negative (s/(.)/\$1/)

        for my $num ($subst =~ m/\$(\d+)/xmsg) {
            $captures[$num-1] = 1;
        }
    }
    return if none {! defined $_} @captures;

    my %modifiers = get_modifiers($elem);
    if ($modifiers{g}) {
        $ncaptures = $NUM_CAPTURES_FOR_GLOBAL;
        $#captures = $ncaptures - 1;
    }

    return if _enough_assignments($elem, \@captures);
    return if _is_in_slurpy_array_context($elem);
    return if _enough_magic($elem, \@captures);

    return $self->violation( $DESC, $EXPL, $elem );
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
        return 1 if _symbol_is_slurpy($psib);

    } elsif ($psib->isa('PPI::Structure::Block')) {
        # @{$foo} = m/(foo)/
        # %{$foo} = m/(foo)/
        return 1 if _block_is_slurpy($psib);

    } elsif ($psib->isa('PPI::Structure::List')) {
        # () = m/(foo)/
        # ($foo) = m/(foo)/
        # ($foo,$bar) = m/(foo)(bar)/
        # (@foo) = m/(foo)(bar)/
        # ($foo,@foo) = m/(foo)(bar)/
        # ($foo,@$foo) = m/(foo)(bar)/
        # ($foo,@{$foo}) = m/(foo)(bar)/

        my @args = $psib->schildren;
        return 1 if !@args;   # empty list (perhaps the "goatse" operator) is slurpy

        # Forward looking: PPI might change in v1.200 so schild(0) is a PPI::Statement::Expression
        if ( 1 == @args && $args[0]->isa('PPI::Statement::Expression') ) {
            @args = $args[0]->schildren;
        }

        my @parts = split_nodes_on_comma(@args);
      PART:
        for my $i (0 .. $#parts) {
            if (1 == @{$parts[$i]}) {
                my $var = $parts[$i]->[0];
                if ($var->isa('PPI::Token::Symbol') || $var->isa('PPI::Token::Cast')) {
                    return 1 if _has_array_sigil($var);
                }
            }
            $captures->[$i] = 1;  # ith evariable captures
        }
    }

    return none {! defined $_} @{$captures};
}

sub _symbol_is_slurpy {
    my ($symbol) = @_;

    return 1 if _has_array_sigil($symbol);
    return 1 if _has_hash_sigil($symbol);
    return 1 if _is_preceded_by_array_or_hash_cast($symbol);
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

    return 1 if _is_preceded_by_array_or_hash_cast($block);
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
        return 1 if $parent->isa('PPI::Structure::List');
        return 1 if $parent->isa('PPI::Structure::Constructor');
        if ($parent->isa('PPI::Structure::Block')) {
            return 1 if refaddr($elem->statement) eq refaddr([$parent->schildren]->[-1]);
        }
        return;
    }
    if ($psib->isa('PPI::Token::Operator')) {
        # most operators kill slurpiness (except assignment, which is handled elsewhere)
        return 1 if q{,} eq $psib;
        return;
    }
    return 1;
}

sub _skip_lhs {
    my ($elem) = @_;

    # TODO: better implementation to handle casts, expressions, subcalls, etc.
    $elem = $elem->sprevious_sibling;

    return $elem;
}

sub _enough_magic {
    my ($elem, $captures) = @_;

    _check_for_magic($elem, $captures);

    return none {! defined $_} @{$captures};
}

# void return
sub _check_for_magic {
    my ($elem, $captures) = @_;

    # Search for $1..$9 in :
    #  * the rest of this statement
    #  * subsequent sibling statements
    #  * if this is in a conditional boolean, the if/else bodies of the conditional
    #  * if this is in a while/for condition, the loop body
    # But NO intervening regexps!

    return if ! _check_rest_of_statement($elem, $captures);

    my $parent = $elem->parent;
    while ($parent && ! $parent->isa('PPI::Statement::Sub')) {
        return if ! _check_rest_of_statement($parent, $captures);
        $parent = $parent->parent;
    }

    return;
}

# false if we hit another regexp
sub _check_rest_of_statement {
    my ($elem, $captures) = @_;

    my $nsib = $elem->snext_sibling;
    while ($nsib) {
        return if $nsib->isa('PPI::Token::Regexp');
        if ($nsib->isa('PPI::Node')) {
            return if ! _check_node_children($nsib, $captures);
        } else {
            _mark_magic($nsib, $captures);
        }
        $nsib = $nsib->snext_sibling;
    }
    return 1;
}

# false if we hit another regexp
sub _check_node_children {
    my ($elem, $captures) = @_;

    # caveat: this will descend into subroutine definitions...

    for my $child ($elem->schildren) {
        return if $child->isa('PPI::Token::Regexp');
        if ($child->isa('PPI::Node')) {
            return if ! _check_node_children($child, $captures);
        } else {
            _mark_magic($child, $captures);
        }
    }
    return 1;
}

sub _mark_magic {
    my ($elem, $captures) = @_;

    # Record if we see $1, $2, $3, ...

    if ($elem->isa('PPI::Token::Magic') && $elem =~ m/\A \$ (\d+) /xms) {
        my $num = $1;
        if (0 < $num) { # don't mark $0
            # Only mark the captures we really need -- don't mark superfluous magic vars
            if ($num <= @{$captures}) {
                $captures->[$num-1] = 1;
            }
        }
    }
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

=head2 Regexp::Parser

We use L<Regexp::Parser|Regexp::Parser> to analyze the regular
expression syntax.  This is an optional module for Perl::Critic, so it
will not be automatically installed by CPAN for you.  If you wish to
use this policy, you must install that module first.


=head2 C<qr//> interpolation

This policy can be confused by interpolation of C<qr//> elements, but
those are always false negatives.  For example:

    my $foo_re = qr/(foo)/;
    my ($foo) = m/$foo_re (bar)/x;

A human can tell that this should be a violation because there are two
captures but only the first capture is used, not the second.  The
policy only notices that there is one capture in the regexp and
remains happy.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2008 Chris Dolan.  Many rights reserved.

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
