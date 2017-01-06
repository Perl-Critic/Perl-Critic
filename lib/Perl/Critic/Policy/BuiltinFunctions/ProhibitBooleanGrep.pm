package Perl::Critic::Policy::BuiltinFunctions::ProhibitBooleanGrep;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification hashify };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"grep" used in boolean context};
Readonly::Scalar my $EXPL => [71,72];

Readonly::Hash my %POSTFIX_CONDITIONALS => hashify( qw(if unless while until) );
Readonly::Hash my %BOOLEAN_OPERATORS => hashify( qw(&& || ! not or and));

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                     }
sub default_severity     { return $SEVERITY_LOW          }
sub default_themes       { return qw( core pbp performance certrec ) }
sub applies_to           { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem->content() ne 'grep';
    return if not is_function_call($elem);
    return if not _is_in_boolean_context($elem);

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

sub _is_in_boolean_context {
    my ($token) = @_;

    return _does_prev_sibling_cause_boolean($token) || _does_parent_cause_boolean($token);
}

sub _does_prev_sibling_cause_boolean {
    my ($token) = @_;

    my $prev = $token->sprevious_sibling;
    return if !$prev;
    return 1 if $prev->isa('PPI::Token::Word') and $POSTFIX_CONDITIONALS{$prev};
    return if not ($prev->isa('PPI::Token::Operator') and $BOOLEAN_OPERATORS{$prev});
    my $next = $token->snext_sibling;
    return 1 if not $next; # bizarre: grep with no arguments

    # loose heuristic: unparenthesized grep has no following non-boolean operators
    return 1 if not $next->isa('PPI::Structure::List');

    $next = $next->snext_sibling;
    return 1 if not $next;
    return 1 if $next->isa('PPI::Token::Operator') and $BOOLEAN_OPERATORS{$next};
    return;
}

sub _does_parent_cause_boolean {
    my ($token) = @_;

    my $prev = $token->sprevious_sibling;
    return if $prev;
    my $parent = $token->statement->parent;
    for (my $node = $parent; $node; $node = $node->parent) { ## no critic (CStyleForLoop)
        next if $node->isa('PPI::Structure::List');
        return 1 if $node->isa('PPI::Structure::Condition');
    }

    return;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitBooleanGrep - Use C<List::MoreUtils::any> instead of C<grep> in boolean context.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using C<grep> in boolean context is a common idiom for checking if any
elements in a list match a condition.  This works because boolean
context is a subset of scalar context, and grep returns the number of
matches in scalar context.  A non-zero number of matches means a
match.

But consider the case of a long array where the first element is a
match.  Boolean C<grep> still checks all of the rest of the elements
needlessly.  Instead, a better solution is to use the C<any> function
from L<List::MoreUtils|List::MoreUtils>, which short-circuits after
the first successful match to save time.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CAVEATS

The algorithm for detecting boolean context takes a LOT of shortcuts.
There are lots of known false negatives.  But, I was conservative in
writing this, so I hope there are no false positives.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

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
