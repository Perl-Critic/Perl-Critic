##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitCommaSeparatedStatements;

use strict;
use warnings;

use Perl::Critic::Utils qw{ :characters :severities :classification };

use base 'Perl::Critic::Policy';

our $VERSION = 1.051;

#-----------------------------------------------------------------------------

my $desc = q{Comma used to separate statements};
my $expl = [ 68, 71 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_HIGH        }
sub default_themes       { return qw( core bugs pbp )   }
sub applies_to           { return 'PPI::Statement'      }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # Grrr... PPI instantiates non-leaf nodes in its class hierarchy...
    return if _is_ppi_statement_subclass($elem);

    # Now, if PPI hasn't introduced any new PPI::Statement subclasses, we've
    # got an element who's class really is PPI::Statement.

    return if _is_parent_a_constructor_or_list($elem);

    foreach my $child ( $elem->schildren() ) {
        if ( $child->isa('PPI::Token::Word') ) {
            return if _succeeding_commas_are_list_element_separators($child);
        } elsif ( $child->isa('PPI::Token::Operator') ) {
            if ( $child->content() eq $COMMA ) {
                return $self->violation($desc, $expl, $elem);
            };

            # Handle hash constructors that PPI incorrectly reports as
            # blocks.
            if ( $child->content() eq q{=>} ) {
                return;
            }
        }
    }

    return;
}

sub _is_ppi_statement_subclass {
    my $elem = shift;

    return 1 if $elem->isa('PPI::Statement::Package');
    return 1 if $elem->isa('PPI::Statement::Include');
    return 1 if $elem->isa('PPI::Statement::Sub');
    return 1 if $elem->isa('PPI::Statement::Compound');
    return 1 if $elem->isa('PPI::Statement::Break');
    return 1 if $elem->isa('PPI::Statement::Data');
    return 1 if $elem->isa('PPI::Statement::End');
    return 1 if $elem->isa('PPI::Statement::Expression');
    return 1 if $elem->isa('PPI::Statement::Null');
    return 1 if $elem->isa('PPI::Statement::UnmatchedBrace');
    return 1 if $elem->isa('PPI::Statement::Unknown');

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

sub _succeeding_commas_are_list_element_separators {
    my $elem = shift;

    return if is_perl_builtin_with_zero_and_or_one_arguments($elem);

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
