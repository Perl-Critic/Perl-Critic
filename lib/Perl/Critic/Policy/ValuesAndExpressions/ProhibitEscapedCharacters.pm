##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_006';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC     => q{Numeric escapes in interpolated string};
Readonly::Scalar my $EXPL     => [ 56 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return qw(PPI::Token::Quote::Double
                                     PPI::Token::Quote::Interpolate) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $not_escaped = qr/(?<!\\)(?:\\\\)*/mx;
    my $hex         = qr/\\x[\dA-Fa-f]{2}/mx;
    my $widehex     = qr/\\x[{][\dA-Fa-f]+[}]/mx;
    my $oct         = qr/\\[01][0-7]/mx;
    if ($elem->content =~ m/$not_escaped (?:$hex|$widehex|$oct)/mxo) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters - Write C<"\N{DELETE}"> instead of C<"\x7F">, etc.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic> distribution.


=head1 DESCRIPTION

Escaped numeric values are hard to read and debug.  Instead, use named
values.  The syntax is less compact, but dramatically more readable.

  $str = "\x7F\x06\x22Z";                         # not ok

  use charnames ':full';
  $str = "\N{DELETE}\N{ACKNOWLEDGE}\N{CANCEL}Z";  # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Chris Dolan.  All rights reserved.

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
