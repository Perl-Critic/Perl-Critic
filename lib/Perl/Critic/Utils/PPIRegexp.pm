##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::PPIRegexp;

use strict;
use warnings;

use base 'Exporter';

our $VERSION = 1.072;

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    &get_match_string
    &get_substitute_string
    &get_modifiers
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub get_match_string {
    my ($elem) = @_;
    return if !$elem->{sections};
    my $section = $elem->{sections}->[0];
    return if !$section;
    return substr $elem->content, $section->{position}, $section->{size};
}

#-----------------------------------------------------------------------------

sub get_substitute_string {
    my ($elem) = @_;
    return if !$elem->{sections};
    my $section = $elem->{sections}->[1];
    return if !$section;
    return substr $elem->content, $section->{position}, $section->{size};
}

#-----------------------------------------------------------------------------

sub get_modifiers {
    my ($elem) = @_;
    return if !$elem->{modifiers};
    return %{ $elem->{modifiers} };
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::PPIRegexp - Utility functions for dealing with PPI regexp tokens.

=head1 SYNOPSIS

   use Perl::Critic::Utils::PPIRegexp qw(:all);
   use PPI::Document;
   my $doc = PPI::Document->new(\'m/foo/');
   my $elem = $doc->find('PPI::Token::Regexp::Match')->[0];
   print get_match_string($elem);  # yields 'foo'

=head1 DESCRIPTION

As of PPI v1.1xx, the PPI regexp token classes
(L<PPI::Token::Regexp::Match>, L<PPI::Token::Regexp::Substitute> and
L<PPI::Token::QuoteLike::Regexp>) has a very weak interface, so it is
necessary to dig into internals to learn anything useful.  This
package contains subroutines to encapsulate that excess intimacy.  If
future versions of PPI gain better accessors, this package will start
using those.

=head1 IMPORTABLE SUBS

=over

=item C<get_match_string( $token )>

Returns the match portion of the regexp or undef if the specified
token is not a regexp.  Examples:

  m/foo/;         # yields 'foo'
  s/foo/bar/;     # yields 'foo'
  / \A a \z /xms; # yields ' \\A a \\z '
  qr{baz};        # yields 'baz'

=item C<get_substitute_string( $token )>

Returns the substitution portion of a search-and-replace regexp or
undef if the specified token is not a valid regexp.  Examples:

  m/foo/;         # yields undef
  s/foo/bar/;     # yields 'bar'

=item C<get_modifiers( $token )>

Returns a hash containing booleans for the modifiers of the regexp, or
undef if the token is not a regexp.

  /foo/xms;  # yields (m => 1, s => 1, x => 1)
  s/foo//;   # yields ()
  qr/foo/i;  # yields (i => 1)

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Chris Dolan.  Many rights reserved.

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
