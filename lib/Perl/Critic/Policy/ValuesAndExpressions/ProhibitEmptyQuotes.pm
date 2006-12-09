##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

my $empty_rx = qr{\A ["|'] \s* ['|"] \z}x;
my $desc     = q{Quotes used with an empty string};
my $expl     = [ 53 ];

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW       }
sub default_themes   { return qw(core pbp readability) }
sub applies_to       { return 'PPI::Token::Quote' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    if ( $elem =~ $empty_rx ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitEmptyQuotes

=head1 DESCRIPTION

Don't use quotes for an empty string or any string that is pure whitespace.
Instead, use C<q{}> to improve legibility.  Better still, created named values
like this.  Use the C<x> operator to repeat characters.

  $message = '';      #not ok
  $message = "";      #not ok
  $message = "     "; #not ok

  $message = q{};     #better
  $message = q{     } #better

  $EMPTY = q{};
  $message = $EMPTY;      #best

  $SPACE = q{ };
  $message = $SPACE x 5;  #best

=head1 SEE ALSO

L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitNoisyStrings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
