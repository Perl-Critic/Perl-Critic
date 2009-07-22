##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::PPI;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Scalar::Util qw< blessed >;

use base 'Exporter';

our $VERSION = '1.101_002';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    is_ppi_expression_or_generic_statement
    is_ppi_generic_statement
    is_ppi_statement_subclass
    is_subroutine_declaration
    is_in_subroutine
    get_constant_name_element_from_declaring_statement
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

# Clean this up once PPI with module_version() is released.
sub _constant_name_from_constant_pragma {
    my ($include) = @_;

    my $name_slot = 2;
    my $argument_or_version = $include->schild($name_slot);
    return if not $argument_or_version;                     # "use constant"
    return if
        $argument_or_version->isa('PPI::Token::Structure'); # "use constant;"

    return $argument_or_version
        if not $argument_or_version->isa('PPI::Token::Number');

    my $follower = $include->schild($name_slot + 1);
    return if not $follower;                            # "use constant 123"
    return if $follower->isa('PPI::Token::Structure');  # "use constant 123;"
    return $argument_or_version if $follower->isa('PPI::Token::Operator');
    return $follower;
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


=item C<is_subroutine_declaration( $element )>

Is the parameter a subroutine declaration, named or not?


=item C<is_in_subroutine( $element )>

Is the parameter a subroutine or inside one?


=item C<get_constant_name_element_from_declaring_statement($statement)>

Given a L<PPI::Statement|PPI::Statement>, if the statement is a C<use
constant> or L<Readonly|Readonly> declaration statement, return the name of
the thing being defined.

Given

    use constant 1.16 FOO => 'bar';

this will return "FOO".  Similarly, given

    Readonly::Hash my %FOO => ( bar => 'baz' );

this will return "%FOO".


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Elliot Shank.  All rights reserved.

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
