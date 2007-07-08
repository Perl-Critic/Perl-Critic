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

our $VERSION = 1.06;

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
    if ($elem->content =~ m/(?<!\\)(?:\\\\)*(?:\\x[0-9A-F]|\\[01][0-7])/mx) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::ProhibitEscapedCharacters

=head1 DESCRIPTION

Escaped numeric values are hard to read and debug.  Instead, use named
values.  The syntax is less compact, but dramatically more readable.

  $str = "\X7F\x06\x22Z";                         # not ok

  use charnames ':full';
  $str = "\N{DELETE}\N{ACKNOWLEDGE}\N{CANCEL}Z";  # ok

=head1 SEE ALSO


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

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
