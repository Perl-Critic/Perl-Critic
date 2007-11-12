##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitUnusualDelimiters;

use strict;
use warnings;
use Readonly;

use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities };
use Perl::Critic::Utils::PPIRegexp qw{ get_delimiters };
use base 'Perl::Critic::Policy';

our $VERSION = '1.080';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use only '//' or '{}' to delimit regexps};
Readonly::Scalar my $EXPL => [246];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    for my $delim (get_delimiters($elem)) {
       next if '//' eq $delim;   ## no critic(ProhibitNoisyQuotes)
       next if '{}' eq $delim;
       return $self->violation( $DESC, $EXPL, $elem );
    }

    return;  # OK
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitUnusualDelimiters

=head1 DESCRIPTION

Perl lets you delimit regular expressions with almost any character,
but most choices are illegible.  Compare these equivalent expressions:

  s/foo/bar/;   # good
  s{foo}{bar};  # good
  s#foo#bar#;   # bad
  s;foo;bar;;   # worse
  s|\|\||\||;   # eye-gouging bad

=head1 CREDITS

Initial development of this policy was supported by a grant from the Perl Foundation.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Chris Dolan.  Many rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
