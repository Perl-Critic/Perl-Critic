##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline;

use strict;
use warnings;
use Readonly;

use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities };
use Perl::Critic::Utils::PPIRegexp qw{ get_match_string get_delimiters };
use base 'Perl::Critic::Policy';

our $VERSION = '1.079_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use '{' and '}' to delimit multi-line regexps};
Readonly::Scalar my $EXPL => [242];

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

    my $re = get_match_string($elem);
    return if $re !~ m/\n/xms;

    my ($match_delim) = get_delimiters($elem);
    return if '{}' eq $match_delim;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline

=head1 DESCRIPTION

Long regular expressions are hard to read.  A good practice is to use
the C<x> modifier and break the regex into multiple lines with
comments explaining the parts.  But, with the usual C<//> delimiters,
the beginning and end can be hard to match, especially in a C<s///>
regexp.  Instead, try using C<{}> characters to delimit your
expressions.

Compare these:

    s/
       <a \s+ href="([^"]+)">
        (.*?)
       </a>
     /link=$1, text=$2/xms;

vs.

    s{
       <a \s+ href="([^"]+)">
        (.*?)
       </a>
     }
     {link=$1, text=$2}xms;

Is that an improvement?  Marginally, but yes.  The curly braces lead the eye better.

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
