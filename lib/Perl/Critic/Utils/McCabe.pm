##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::McCabe;

use strict;
use warnings;

use Perl::Critic::Utils qw{ :data_conversion :classification };

use base 'Exporter';

our $VERSION = 1.052;

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw( &calculate_mccabe_of_sub );

#-----------------------------------------------------------------------------

my @logic_ops = qw( && || ||= &&= or and xor ? <<= >>= );
my %logic_ops = hashify( @logic_ops );

my @logic_keywords = qw( if else elsif unless until while for foreach );
my %logic_keywords = hashify( @logic_keywords );

#-----------------------------------------------------------------------------

sub calculate_mccabe_of_sub {
    my ( $sub ) = @_;

    my $count = 1; # Minimum score is 1
    $count += _count_logic_keywords( $sub );
    $count += _count_logic_operators( $sub );

    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_keywords {
    my $sub = shift;
    my $count = 0;

    my $keywords_ref = $sub->find('PPI::Token::Word');
    if ( $keywords_ref ) { # should always be true due to "sub" keyword
        my @filtered = grep { ! is_hash_key($_) } @{ $keywords_ref };
        $count = grep { exists $logic_keywords{$_} } @filtered;
    }
    return $count;
}

#-----------------------------------------------------------------------------

sub _count_logic_operators {
    my $sub = shift;
    my $count = 0;

    my $operators_ref = $sub->find('PPI::Token::Operator');
    if ( $operators_ref ) {
        $count = grep { exists $logic_ops{$_} }  @{ $operators_ref };
    }

    return $count;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords McCabe

=head1 NAME

Perl::Critic::Utils::McCabe

=head1 DESCRIPTION

Provides approximations of McCabe scores.  The McCabe score of a set
of code describes the number of possible paths through it.  The
functions here approximate the McCabe score by summing the number of
conditional statements and operators within a set of code.  See
L<http://www.sei.cmu.edu/str/descriptions/cyclomatic_body.html> for
some discussion about the McCabe number and other complexity metrics.


=head1 IMPORTABLE SUBS

=over

=item C<calculate_mccabe_of_sub( $sub )>

Calculates an approximation of the McCabe number of the code in a
L<PPI::Statement::Sub>.

=back


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

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
