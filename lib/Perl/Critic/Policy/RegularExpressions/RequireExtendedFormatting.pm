##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use Perl::Critic::Utils::PPIRegexp qw{ &get_modifiers &get_match_string };
use base 'Perl::Critic::Policy';

our $VERSION = '1.090';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/x" flag};
Readonly::Scalar my $EXPL => [ 236 ];

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow_short_regex',
            description        =>
                q[Regexes below a given length are ok.],
            behavior           => 'integer',
            default_string     => '0',
            integer_minimum    => 0,
        },
        {
            name               => 'allow_with_whitespace',
            description        =>
                q[Regexes with spaces can be harder to read with /x],
            behavior           => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM         }
sub default_themes       { return qw(core pbp maintenance) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $match = get_match_string($elem);
    return if length $match <= $self->{_allow_short_regex};
    return if $self->{_allow_with_whitespace} and $match =~ /\s/;

    my %mods = get_modifiers($elem);
    if ( ! $mods{x} ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return; #ok!;
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

    #Same thing with extended format...

    m{ '           #an opening single quote
       [^\\']      #any non-special chars (i.e. not backslash or single quote)
       (?:         #then all of...
          \\ .     #   any explicitly backslashed char
          [^\\']*  #   followed by an non-special chars
       )*          #...repeated zero or more times
       '           # a closing single quote
     }x;


=head1 CONFIGURATION

Because using C</x> on a regex which has whitespace in it can make it harder
to read, you have to escape all that innocent whitespace, you can add an
exception by turning on C<allow_with_whitespace>.

    [RegularExpressions::RequireExtendedFormatting]
    allow_with_whitespace = 1

    $string =~ /Basset hounds got long ears/;  # ok

You might find that putting a C</x> on short regexes to be excessive.  An
exception can be made for them by setting C<allow_short_regex> to the minimum
match length you'll allow without a C</x>.  The length only counts the regular
expression, not the braces or operators.

    [RegularExpressions::RequireExtendedFormatting]
    allow_short_regex = 5

    $num =~ m{(\d+)};              # ok, only 5 characters
    $num =~ m{\d\.(\d+)};          # not ok, 9 characters


=head1 NOTES

For common regular expressions like e-mail addresses, phone numbers,
dates, etc., have a look at the L<Regex::Common|Regex::Common> module.
Also, be cautions about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.


=head1 AUTHOR

Jeffrey Ryan Thalhammer  <thaljef@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer. All rights reserved.

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
