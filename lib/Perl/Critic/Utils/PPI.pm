package Perl::Critic::Utils::PPI;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< blessed readonly >;

use Exporter 'import';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    is_ppi_expression_or_generic_statement
    is_ppi_generic_statement
    is_ppi_statement_subclass
    is_ppi_simple_statement
    is_ppi_constant_element
    is_subroutine_declaration
    is_in_subroutine
    get_constant_name_element_from_declaring_statement
    get_next_element_in_same_simple_statement
    get_previous_module_used_on_same_line
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub is_ppi_expression_or_generic_statement {
    my $element = shift;

    return if not $element;
    return if not $element->isa('PPI::Statement');
    return 1 if $element->isa('PPI::Statement::Expression');

    my $element_class = blessed($element);

    return if not $element_class;
    return $element_class eq 'PPI::Statement';
}

#-----------------------------------------------------------------------------

sub is_ppi_generic_statement {
    my $element = shift;

    my $element_class = blessed($element);

    return if not $element_class;
    return if not $element->isa('PPI::Statement');

    return $element_class eq 'PPI::Statement';
}

#-----------------------------------------------------------------------------

sub is_ppi_statement_subclass {
    my $element = shift;

    my $element_class = blessed($element);

    return if not $element_class;
    return if not $element->isa('PPI::Statement');

    return $element_class ne 'PPI::Statement';
}

#-----------------------------------------------------------------------------

# Can not use hashify() here because Perl::Critic::Utils already depends on
# this module.
Readonly::Hash my %SIMPLE_STATEMENT_CLASS => map { $_ => 1 } qw<
    PPI::Statement
    PPI::Statement::Break
    PPI::Statement::Include
    PPI::Statement::Null
    PPI::Statement::Package
    PPI::Statement::Variable
>;

sub is_ppi_simple_statement {
    my $element = shift or return;

    my $element_class = blessed( $element ) or return;

    return $SIMPLE_STATEMENT_CLASS{ $element_class };
}

#-----------------------------------------------------------------------------

sub is_ppi_constant_element {
    my $element = shift or return;

    blessed( $element ) or return;

    # TODO implement here documents once PPI::Token::HereDoc grows the
    # necessary PPI::Token::Quote interface.
    return
            $element->isa( 'PPI::Token::Number' )
        ||  $element->isa( 'PPI::Token::Quote::Literal' )
        ||  $element->isa( 'PPI::Token::Quote::Single' )
        ||  $element->isa( 'PPI::Token::QuoteLike::Words' )
        ||  (
                $element->isa( 'PPI::Token::Quote::Double' )
            ||  $element->isa( 'PPI::Token::Quote::Interpolate' ) )
            &&  $element->string() !~ m< (?: \A | [^\\] ) (?: \\\\)* [\$\@] >smx
        ;
}

#-----------------------------------------------------------------------------

sub is_subroutine_declaration {
    my $element = shift;

    return if not $element;

    return 1 if $element->isa('PPI::Statement::Sub');

    if ( is_ppi_generic_statement($element) ) {
        my $first_element = $element->first_element();

        return 1 if
                $first_element
            and $first_element->isa('PPI::Token::Word')
            and $first_element->content() eq 'sub';
    }

    return;
}

#-----------------------------------------------------------------------------

sub is_in_subroutine {
    my ($element) = @_;

    return if not $element;
    return 1 if is_subroutine_declaration($element);

    while ( $element = $element->parent() ) {
        return 1 if is_subroutine_declaration($element);
    }

    return;
}

#-----------------------------------------------------------------------------

sub get_constant_name_element_from_declaring_statement {
    my ($element) = @_;

    warnings::warnif(
        'deprecated',
        'Perl::Critic::Utils::PPI::get_constant_name_element_from_declaring_statement() is deprecated. Use PPIx::Utilities::Statement::get_constant_name_elements_from_declaring_statement() instead.',
    );

    return if not $element;
    return if not $element->isa('PPI::Statement');

    if ( $element->isa('PPI::Statement::Include') ) {
        my $pragma;
        if ( $pragma = $element->pragma() and $pragma eq 'constant' ) {
            return _constant_name_from_constant_pragma($element);
        }
    }
    elsif (
            is_ppi_generic_statement($element)
        and $element->schild(0)->content() =~ m< \A Readonly \b >xms
    ) {
        return $element->schild(2);
    }

    return;
}

sub _constant_name_from_constant_pragma {
    my ($include) = @_;

    my @arguments = $include->arguments() or return;

    my $follower = $arguments[0];
    return if not defined $follower;

    return $follower;
}

#-----------------------------------------------------------------------------

sub get_next_element_in_same_simple_statement {
    my $element = shift or return;

    while ( $element and (
            not is_ppi_simple_statement( $element )
            or $element->parent()
            and $element->parent()->isa( 'PPI::Structure::List' ) ) ) {
        my $next;
        $next = $element->snext_sibling() and return $next;
        $element = $element->parent();
    }
    return;

}

#-----------------------------------------------------------------------------

sub get_previous_module_used_on_same_line {
    my $element = shift or return;

    my ( $line ) = @{ $element->location() || []};

    while (not is_ppi_simple_statement( $element )) {
        $element = $element->parent() or return;
    }

    while ( $element = $element->sprevious_sibling() ) {
        ( @{ $element->location() || []} )[0] == $line or return;
        $element->isa( 'PPI::Statement::Include' )
            and return $element->schild( 1 );
    }

    return;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::PPI - Utility functions for dealing with PPI objects.


=head1 DESCRIPTION

Provides classification of L<PPI::Elements|PPI::Elements>.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over

=item C<is_ppi_expression_or_generic_statement( $element )>

Answers whether the parameter is an expression or an undifferentiated
statement.  I.e. the parameter either is a
L<PPI::Statement::Expression|PPI::Statement::Expression> or the class
of the parameter is L<PPI::Statement|PPI::Statement> and not one of
its subclasses other than C<Expression>.


=item C<is_ppi_generic_statement( $element )>

Answers whether the parameter is an undifferentiated statement, i.e.
the parameter is a L<PPI::Statement|PPI::Statement> but not one of its
subclasses.


=item C<is_ppi_statement_subclass( $element )>

Answers whether the parameter is a specialized statement, i.e. the
parameter is a L<PPI::Statement|PPI::Statement> but the class of the
parameter is not L<PPI::Statement|PPI::Statement>.


=item C<is_ppi_simple_statement( $element )>

Answers whether the parameter represents a simple statement, i.e. whether the
parameter is a L<PPI::Statement|PPI::Statement>,
L<PPI::Statement::Break|PPI::Statement::Break>,
L<PPI::Statement::Include|PPI::Statement::Include>,
L<PPI::Statement::Null|PPI::Statement::Null>,
L<PPI::Statement::Package|PPI::Statement::Package>, or
L<PPI::Statement::Variable|PPI::Statement::Variable>.


=item C<is_ppi_constant_element( $element )>

Answers whether the parameter represents a constant value, i.e. whether the
parameter is a L<PPI::Token::Number|PPI::Token::Number>,
L<PPI::Token::Quote::Literal|PPI::Token::Quote::Literal>,
L<PPI::Token::Quote::Single|PPI::Token::Quote::Single>, or
L<PPI::Token::QuoteLike::Words|PPI::Token::QuoteLike::Words>, or is a
L<PPI::Token::Quote::Double|PPI::Token::Quote::Double> or
L<PPI::Token::Quote::Interpolate|PPI::Token::Quote::Interpolate> which does
not in fact contain any interpolated variables.

This subroutine does B<not> interpret any form of here document as a constant
value, and may not until L<PPI::Token::HereDoc|PPI::Token::HereDoc> acquires
the relevant portions of the L<PPI::Token::Quote|PPI::Token::Quote> interface.

This subroutine also does B<not> interpret entities created by the
L<Readonly|Readonly> module or the L<constant|constant> pragma as constants,
because the infrastructure to detect these appears not to be present, and the
author of this subroutine (B<not> Mr. Shank or Mr. Thalhammer) lacks the
knowledge/expertise/gumption to put it in place.


=item C<is_subroutine_declaration( $element )>

Is the parameter a subroutine declaration, named or not?


=item C<is_in_subroutine( $element )>

Is the parameter a subroutine or inside one?


=item C<get_constant_name_element_from_declaring_statement($statement)>

B<This subroutine is deprecated.> You should use
L<PPIx::Utilities::Statement/get_constant_name_elements_from_declaring_statement()>
instead.

Given a L<PPI::Statement|PPI::Statement>, if the statement is a C<use
constant> or L<Readonly|Readonly> declaration statement, return the name of
the thing being defined.

Given

    use constant 1.16 FOO => 'bar';

this will return "FOO".  Similarly, given

    Readonly::Hash my %FOO => ( bar => 'baz' );

this will return "%FOO".

B<Caveat:> in the case where multiple constants are declared using the same
C<use constant> statement (e.g. C<< use constant { FOO => 1, BAR => 2 }; >>,
this subroutine will return the declaring
L<PPI::Structure::Constructor|PPI::Structure::Constructor>. In the case of
C<< use constant 1.16 { FOO => 1, BAR => 2 }; >> it may return a
L<PPI::Structure::Block|PPI::Structure::Block> instead of a
L<PPI::Structure::Constructor|PPI::Structure::Constructor>, due to a parse
error in L<PPI|PPI>.


=item C<get_next_element_in_same_simple_statement( $element )>

Given a L<PPI::Element|PPI::Element>, this subroutine returns the next element
in the same simple statement as defined by is_ppi_simple_statement(). If no
next element can be found, this subroutine simply returns.

If the $element is undefined or unblessed, we simply return.

If the $element satisfies C<is_ppi_simple_statement()>, we return, B<unless>
it has a parent which is a L<PPI::Structure::List|PPI::Structure::List>.

If the $element is the last significant element in its L<PPI::Node|PPI::Node>,
we replace it with its parent and iterate again.

Otherwise, we return C<< $element->snext_sibling() >>.


=item C<get_previous_module_used_on_same_line( $element )>

Given a L<PPI::Element|PPI::Element>, returns the L<PPI::Element|PPI::Element>
representing the name of the module included by the previous C<use> or
C<require> on the same line as the $element. If none is found, simply returns.

For example, with the line

    use version; our $VERSION = ...;

given the L<PPI::Token::Symbol|PPI::Token::Symbol> instance for C<$VERSION>, this will return
"version".

If the given element is in a C<use> or <require>, the return is from the
previous C<use> or C<require> on the line, if any.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


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
