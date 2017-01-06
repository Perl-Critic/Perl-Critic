package Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements;

use 5.006001;
use strict;
use warnings;
use Readonly;


use Perl::Critic::Utils qw{ :booleans :characters :severities :classification };
use Perl::Critic::Utils::PPI qw{ is_ppi_statement_subclass };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Comma used to separate statements};
Readonly::Scalar my $EXPL => [ 68, 71 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name           => 'allow_last_statement_to_be_comma_separated_in_map_and_grep',
            description    => 'Allow map and grep blocks to return lists.',
            default_string => $FALSE,
            behavior       => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp certrule ) }
sub applies_to           { return 'PPI::Statement'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Grrr... PPI instantiates non-leaf nodes in its class hierarchy...
    return if is_ppi_statement_subclass($elem);

    # Now, if PPI hasn't introduced any new PPI::Statement subclasses, we've
    # got an element who's class really is PPI::Statement.

    return if _is_parent_a_constructor_or_list($elem);
    return if _is_parent_a_for_loop($elem);

    if (
        $self->{_allow_last_statement_to_be_comma_separated_in_map_and_grep}
    ) {
        return if not _is_direct_part_of_map_or_grep_block($elem);
    }

    foreach my $child ( $elem->schildren() ) {
        if (
                not $self->{_allow_last_statement_to_be_comma_separated_in_map_and_grep}
            and not _is_last_statement_in_a_block($child)
        ) {
            if ( $child->isa('PPI::Token::Word') ) {
                return if _succeeding_commas_are_list_element_separators($child);
            }
            elsif ( $child->isa('PPI::Token::Operator') ) {
                if ( $child->content() eq $COMMA ) {
                    return $self->violation($DESC, $EXPL, $elem);
                }
            }
        }
    }

    return;
}

sub _is_parent_a_constructor_or_list {
    my ($elem) = @_;

    my $parent = $elem->parent();

    return if not $parent;

    return (
            $parent->isa('PPI::Structure::Constructor')
        or  $parent->isa('PPI::Structure::List')
    );
}

sub _is_parent_a_for_loop {
    my ($elem) = @_;

    my $parent = $elem->parent();

    return if not $parent;

    return if not $parent->isa('PPI::Structure::For');

    return 1 == scalar $parent->schildren(); # Multiple means C-style loop.
}

sub _is_direct_part_of_map_or_grep_block {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return if not $parent;
    return if not $parent->isa('PPI::Structure::Block');

    my $block_prior_sibling = $parent->sprevious_sibling();
    return if not $block_prior_sibling;
    return if not $block_prior_sibling->isa('PPI::Token::Word');

    return $block_prior_sibling eq 'map' || $block_prior_sibling eq 'grep';
}

sub _is_last_statement_in_a_block {
    my ($elem) = @_;

    my $parent = $elem->parent();
    return if not $parent;
    return if not $parent->isa('PPI::Structure::Block');

    my $next_sibling = $elem->snext_sibling();
    return if not $next_sibling;

    return 1;
}

sub _succeeding_commas_are_list_element_separators {
    my ($elem) = @_;

    if (
            is_perl_builtin_with_zero_and_or_one_arguments($elem)
        and not is_perl_builtin_with_multiple_arguments($elem)
    ) {
        return;
    }

    my $sibling = $elem->snext_sibling();

    return 1 if not $sibling;  # There won't be any succeeding commas.

    return not $sibling->isa('PPI::Structure::List');
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements - Don't use the comma operator as a statement separator.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl's comma statement separator has really low precedence, which
leads to code that looks like it's using the comma list element
separator not actually doing so.  Conway suggests that the statement
separator not be used in order to prevent this situation.

The confusion that the statement separator causes is primarily due to
the assignment operators having higher precedence.

For example, trying to combine two arrays into another like this won't
work:

    @x = @y, @z;

because it is equivalent to

    @x = @y;
    @z;

Conversely, there are the built-in functions, like C<print>, that
normally force the rest of the statement into list context, but don't
when called like a subroutine.

This is not likely to produce what is intended:

    print join q{, }, 2, 3, 5, 7, ": the single-digit primes.\n";

The obvious fix is to add parentheses.  Placing them like

    print join( q{, }, 2, 3, 5, 7 ), ": the single-digit primes.\n";

will work, but

    print ( join q{, }, 2, 3, 5, 7 ), ": the single-digit primes.\n";

will not, because it is equivalent to

    print( join q{, }, 2, 3, 5, 7 );
    ": the single-digit primes.\n";


=head1 CONFIGURATION

This policy can be configured to allow the last statement in a C<map>
or C<grep> block to be comma separated.  This is done via the
C<allow_last_statement_to_be_comma_separated_in_map_and_grep> option
like so:

    [ValuesAndExpressions::ProhibitCommaSeparatedStatements]
    allow_last_statement_to_be_comma_separated_in_map_and_grep = 1

With this option off (the default), the following code violates this
policy.

    %hash = map {$_, 1} @list;

With this option on, this statement is allowed.  Even if this option
is off, using a fat comma C<< => >> works, but that forces
stringification on the first value, which may not be what you want.


=head1 BUGS

Needs to check for C<scalar( something, something )>.


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
