##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements;

use strict;
use warnings;
use Readonly;


use Perl::Critic::Utils qw{ :characters :severities :classification };
use Perl::Critic::Utils::PPI qw{ is_ppi_statement_subclass };

use base 'Perl::Critic::Policy';

our $VERSION = '1.079_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Comma used to separate statements};
Readonly::Scalar my $EXPL => [ 68, 71 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGH      }
sub default_themes       { return qw( core bugs pbp ) }
sub applies_to           { return 'PPI::Statement'    }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Grrr... PPI instantiates non-leaf nodes in its class hierarchy...
    return if is_ppi_statement_subclass($elem);

    # Now, if PPI hasn't introduced any new PPI::Statement subclasses, we've
    # got an element who's class really is PPI::Statement.

    return if _is_parent_a_constructor_or_list($elem);
    return if _is_parent_a_foreach_loop($elem);

    foreach my $child ( $elem->schildren() ) {
        if ( $child->isa('PPI::Token::Word') ) {
            return if _succeeding_commas_are_list_element_separators($child);
        } elsif ( $child->isa('PPI::Token::Operator') ) {
            if ( $child->content() eq $COMMA ) {
                return $self->violation($DESC, $EXPL, $elem);
            };
        }
    }

    return;
}

sub _is_parent_a_constructor_or_list {
    my $elem = shift;

    my $parent = $elem->parent();

    return if not $parent;

    return (
            $parent->isa('PPI::Structure::Constructor')
        or  $parent->isa('PPI::Structure::List')
    );
}

sub _is_parent_a_foreach_loop {
    my $elem = shift;

    my $parent = $elem->parent();

    return if not $parent;

    return if not $parent->isa('PPI::Structure::ForLoop');

    return 1 == scalar $parent->schildren(); # Multiple means C-style loop.
}

sub _succeeding_commas_are_list_element_separators {
    my $elem = shift;

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

Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements

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

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.com> >>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
