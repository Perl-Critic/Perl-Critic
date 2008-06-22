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

use base 'Exporter';

our $VERSION = '1.087';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    is_ppi_expression_or_generic_statement
    is_ppi_generic_statement
    is_ppi_statement_subclass
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub is_ppi_expression_or_generic_statement {
    my $element = shift;

    my $element_class = ref $element;

    return 0 if not $element_class;
    return 0 if not $element->isa('PPI::Statement');

    return 1 if $element->isa('PPI::Statement::Expression');

    return $element_class eq 'PPI::Statement';
}

#-----------------------------------------------------------------------------

sub is_ppi_generic_statement {
    my $element = shift;

    my $element_class = ref $element;

    return 0 if not $element_class;
    return 0 if not $element->isa('PPI::Statement');

    return $element_class eq 'PPI::Statement';
}

#-----------------------------------------------------------------------------

sub is_ppi_statement_subclass {
    my $element = shift;

    my $element_class = ref $element;

    return 0 if not $element_class;
    return 0 if not $element->isa('PPI::Statement');

    return $element_class ne 'PPI::Statement';
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::PPI - Utility functions for dealing with PPI objects.


=head1 DESCRIPTION

Provides classification of L<PPI::Elements>.


=head1 IMPORTABLE SUBS

=over

=item C<is_ppi_expression_or_generic_statement( $element )>

Answers whether the parameter is an expression or an undifferentiated
statement.  I.e. the parameter either is a
L<PPI::Statement::Expression> or the class of the parameter is
L<PPI::Statement> and not one of its subclasses other than
C<Expression>.


=item C<is_ppi_generic_statement( $element )>

Answers whether the parameter is an undifferentiated statement, i.e.
the parameter is a L<PPI::Statement> but not one of its subclasses.


=item C<is_ppi_statement_subclass( $element )>

Answers whether the parameter is a specialized statement, i.e. the
parameter is a L<PPI::Statement> but the class of the parameter is not
L<PPI::Statement>.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Elliot Shank.  All rights reserved.

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
