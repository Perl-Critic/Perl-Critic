##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Utilities::Statement;

use 5.006001;
use strict;
use warnings;

use Carp;
use Readonly;
use English qw(-no_match_vars);
use Perl::Critic::Utils qw< :characters hashify >;
use Perl::Critic::Utils::PPI qw< is_ppi_generic_statement >;

use base 'Exporter';

our $VERSION = '1.099_002';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    get_constant_name_elements_from_declaring_statement
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

Readonly::Hash my %IS_COMMA => hashify( $COMMA, $FATCOMMA );

#-----------------------------------------------------------------------------

sub get_constant_name_elements_from_declaring_statement {
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

sub _constant_name_from_constant_pragma {
    my ($include) = @_;

    my @arguments = $include->arguments() or return;

    my $follower = $arguments[0];
    return if not defined $follower;

    if ( $follower->isa( 'PPI::Structure::Constructor' )
            or $follower->isa( 'PPI::Structure::Block' ) ) {

        my $statement = $follower->schild( 0 ) or return;
        $statement->isa( 'PPI::Statement' ) or return;

        my @elements;
        my $inx = 0;
        foreach my $child ( $statement->schildren() ) {
            $inx % 2
                or push @{ $elements[ $inx ] ||= [] }, $child;
            $IS_COMMA{ $child->content() }
                and $inx++;
        }
        return ( map { ( $_ && @{ $_ } == 2 &&
                    $FATCOMMA eq $_->[1]->content() &&
                    $_->[0]->isa( 'PPI::Token::Word' ) ) ? $_->[0] : () }
            @elements );
    } else {
        return $follower;
    }

    return $follower;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::PPIx::Utilities::Statement - Utility functions for dealing with
PPI statement objects.


=head1 DESCRIPTION

Provides classification of L<PPI::Elements|PPI::Elements>.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBS

=over


=item C<get_constant_name_elements_from_declaring_statement($statement)>

Given a L<PPI::Statement|PPI::Statement>, if the statement is a C<use
constant> or L<Readonly|Readonly> declaration statement, return the names of
the things being defined. If called in scalar context, return the number of
names defined.

Given

    use constant 1.16 FOO => 'bar';

this will return ("FOO"). Given

    use constant 1.16 { FOO => 'bar', 'BAZ' => 'burfle' };

this will return ("FOO", "BAZ"). Similarly, given

    Readonly::Hash my %FOO => ( bar => 'baz' );

this will return ("%FOO").


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2009 Elliot Shank.  All rights reserved.

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
