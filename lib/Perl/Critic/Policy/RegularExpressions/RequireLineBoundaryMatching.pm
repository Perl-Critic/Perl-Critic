##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use Perl::Critic::Utils::PPIRegexp qw{ &get_modifiers };
use base 'Perl::Critic::Policy';

our $VERSION = '1.080';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/m" flag};
Readonly::Scalar my $EXPL => [ 237 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw(core pbp cosmetic) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my %mods = get_modifiers($elem);
    if ( ! $mods{m} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return; #ok!;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireLineBoundaryMatching

=head1 DESCRIPTION

Folks coming from a C<sed> or C<awk> background tend to assume that
C<'$'> and C<'^'> match the beginning and and of the line, rather than
then beginning and ed of the string.  Adding the '/m' flag to your
regex makes it behave as most people expect it should.

  my $match = m{ ^ $pattern $ }x;  #not ok
  my $match = m{ ^ $pattern $ }xm; #ok

=head1 NOTES

For common regular expressions like e-mail addresses, phone numbers,
dates, etc., have a look at the L<Regex::Common> module.  Also, be
cautions about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.

=head1 AUTHOR

Jeffrey Ryan Thalhammer  <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2007 Jeffrey Ryan Thalhammer. All rights reserved.

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
