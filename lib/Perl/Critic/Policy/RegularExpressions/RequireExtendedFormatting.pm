package Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/x" flag};
Readonly::Scalar my $EXPL => [ 236 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'minimum_regex_length_to_complain_about',
            description        =>
                q<The number of characters that a regular expression must contain before this policy will complain.>,
            behavior           => 'integer',
            default_string     => '0',
            integer_minimum    => 0,
        },
        {
            name               => 'strict',
            description        =>
                q<Should regexes that only contain whitespace and word characters be complained about?>,
            behavior           => 'boolean',
            default_string     => '0',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw< core pbp maintenance > }
sub applies_to           {
    return qw<
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $match = $elem->get_match_string();
    return if length $match <= $self->{_minimum_regex_length_to_complain_about};
    return if not $self->{_strict} and $match =~ m< \A [\s\w]* \z >xms;

    my $re = $doc->ppix_regexp_from_element( $elem )
        or return;
    $re->modifier_asserted( 'x' )
        or return $self->violation( $DESC, $EXPL, $elem );

    return; # ok!;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting - Always use the C</x> modifier with regular expressions.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Extended regular expression formatting allows you mix whitespace and
comments into the pattern, thus making them much more readable.

    # Match a single-quoted string efficiently...

    m{'[^\\']*(?:\\.[^\\']*)*'};  #Huh?

    # Same thing with extended format...

    m{
        '           # an opening single quote
        [^\\']      # any non-special chars (i.e. not backslash or single quote)
        (?:         # then all of...
            \\ .    #    any explicitly backslashed char
            [^\\']* #    followed by an non-special chars
        )*          # ...repeated zero or more times
        '           # a closing single quote
    }x;


=head1 CONFIGURATION

You might find that putting a C</x> on short regular expressions to be
excessive.  An exception can be made for them by setting
C<minimum_regex_length_to_complain_about> to the minimum match length
you'll allow without a C</x>.  The length only counts the regular
expression, not the braces or operators.

    [RegularExpressions::RequireExtendedFormatting]
    minimum_regex_length_to_complain_about = 5

    $num =~ m<(\d+)>;              # ok, only 5 characters
    $num =~ m<\d\.(\d+)>;          # not ok, 9 characters

This option defaults to 0.

Because using C</x> on a regex which has whitespace in it can make it
harder to read (you have to escape all that innocent whitespace), by
default, you can have a regular expression that only contains
whitespace and word characters without the modifier.  If you want to
restrict this, turn on the C<strict> option.

    [RegularExpressions::RequireExtendedFormatting]
    strict = 1

    $string =~ m/Basset hounds got long ears/;  # no longer ok

This option defaults to false.


=head1 NOTES

For common regular expressions like e-mail addresses, phone numbers,
dates, etc., have a look at the L<Regexp::Common|Regexp::Common> module.
Also, be cautions about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.


=head1 TO DO

Add an exemption for regular expressions that contain C<\Q> at the
front and don't use C<\E> until the very end, if at all.


=head1 AUTHOR

Jeffrey Ryan Thalhammer  <jeff@imaginative-software.com>


=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems. All rights reserved.

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
