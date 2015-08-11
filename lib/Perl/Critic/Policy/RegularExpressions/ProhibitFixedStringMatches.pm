package Perl::Critic::Policy::RegularExpressions::ProhibitFixedStringMatches;

use 5.006001;
use strict;
use warnings;
use Readonly;

use English qw(-no_match_vars);
use Carp;

use Perl::Critic::Utils qw{ :booleans :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use 'eq' or hash instead of fixed-pattern regexps};
Readonly::Scalar my $EXPL => [271,272];

Readonly::Scalar my $RE_METACHAR => qr/[\\#\$()*+.?\@\[\]^{|}]/xms;

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                       }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $re = $elem->get_match_string();

    # only flag regexps that are anchored front and back
    if ($re =~ m{\A \s*
                 (\\A|\^)  # front anchor == $1
                 (.*?)
                 (\\z|\$)  # end anchor == $2
                 \s* \z}xms) {

        my ($front_anchor, $words, $end_anchor) = ($1, $2, $3);

        # If it's a multiline match, then end-of-line anchors don't represent the whole string
        if ($front_anchor eq q{^} || $end_anchor eq q{$}) {
            my $regexp = $doc->ppix_regexp_from_element( $elem )
                or return;
            return if $regexp->modifier_asserted( 'm' );
        }

        # check for grouping and optional alternation.  Grouping may or may not capture
        if ($words =~ m{\A \s*
                        [(]              # start group
                          (?:[?]:)?      # optional non-capturing indicator
                          \s* (.*?) \s*  # interior of group
                        [)]              # end of group
                        \s* \z}xms) {
            $words = $1;
            $words =~ s/[|]//gxms; # ignore alternation inside of parens -- just look at words
        }

        # Regexps that contain metachars are not fixed strings
        return if $words =~ m/$RE_METACHAR/oxms;

        return $self->violation( $DESC, $EXPL, $elem );

    } else {
        return; # OK
    }
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitFixedStringMatches - Use C<eq> or hash instead of fixed-pattern regexps.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

A regular expression that matches just a fixed set of constant strings
is wasteful of performance and is hard on maintainers.  It is much
more readable and often faster to use C<eq> or a hash to match such
strings.

    # Bad
    my $is_file_function = $token =~ m/\A (?: open | close | read ) \z/xms;

    # Faster and more readable
    my $is_file_function = $token eq 'open' ||
                           $token eq 'close' ||
                           $token eq 'read';

For larger numbers of strings, a hash is superior:

    # Bad
    my $is_perl_keyword =
        $token =~ m/\A (?: chomp | chop | chr | crypt | hex | index
                           lc | lcfirst | length | oct | ord | ... ) \z/xms;

    # Better
    Readonly::Hash my %PERL_KEYWORDS => map {$_ => 1} qw(
        chomp chop chr crypt hex index lc lcfirst length oct ord ...
    );
    my $is_perl_keyword = $PERL_KEYWORD{$token};

Conway also suggests using C<lc()> instead of a case-insensitive match.


=head2 VARIANTS

This policy detects both grouped and non-grouped strings.  The
grouping may or may not be capturing.  The grouped body may or may not
be alternating.  C<\A> and C<\z> are always considered anchoring which
C<^> and C<$> are considered anchoring is the C<m> regexp option is
not in use.  Thus, all of these are violations:

    m/^foo$/;
    m/\A foo \z/x;
    m/\A foo \z/xm;
    m/\A(foo)\z/;
    m/\A(?:foo)\z/;
    m/\A(foo|bar)\z/;
    m/\A(?:foo|bar)\z/;

Furthermore, this policy detects violations in C<m//>, C<s///> and
C<qr//> constructs, as you would expect.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Chris Dolan.  Many rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
