package Perl::Critic::Policy::RegularExpressions::ProhibitComplexRegexes;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use List::Util qw{ min };
use Readonly;

use Perl::Critic::Utils qw{ :booleans :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Split long regexps into smaller qr// chunks};
Readonly::Scalar my $EXPL => [261];

Readonly::Scalar my $MAX_LITERAL_LENGTH => 7;
Readonly::Scalar my $MAX_VARIABLE_LENGTH => 4;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'max_characters',
            description     =>
                'The maximum number of characters to allow in a regular expression.',
            default_string  => '60',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

sub default_severity     { return $SEVERITY_MEDIUM           }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # Optimization: if its short enough now, parsing won't make it longer
    return if $self->{_max_characters} >= length $elem->get_match_string();

    my $re = $document->ppix_regexp_from_element( $elem )
        or return;  # Abort on syntax error.
    $re->failures()
        and return; # Abort if parse errors found.
    my $qr = $re->regular_expression()
        or return;  # Abort if no regular expression.

    my $length = 0;
    # We use map { $_->tokens() } qr->children() rather than just
    # $qr->tokens() because we are not interested in the delimiters.
    foreach my $token ( map { $_->tokens() } $qr->children() ) {

        # Do not count whitespace or comments
        $token->significant() or next;

        if ( $token->isa( 'PPIx::Regexp::Token::Interpolation' ) ) {

            # Do not penalize long variable names
            $length += min( $MAX_VARIABLE_LENGTH, length $token->content() );

        } elsif ( $token->isa( 'PPIx::Regexp::Token::Literal' ) ) {

            # Do not penalize long literals like \p{...}
            $length += min( $MAX_LITERAL_LENGTH, length $token->content() );

        } else {

            # Take everything else at face value
            $length += length $token->content();

        }

    }

    return if $self->{_max_characters} >= $length;

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords BNF Tatsuhiko Miyagawa

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller C<qr//> chunks.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Big regexps are hard to read, perhaps even the hardest part of Perl.
A good practice to write digestible chunks of regexp and put them
together.  This policy flags any regexp that is longer than C<N>
characters, where C<N> is a configurable value that defaults to 60.
If the regexp uses the C<x> flag, then the length is computed after
parsing out any comments or whitespace.

Unfortunately the use of descriptive (and therefore longish) variable
names can cause regexps to be in violation of this policy, so
interpolated variables are counted as 4 characters no matter how long
their names actually are.


=head1 CASE STUDY

As an example, look at the regexp used to match email addresses in
L<Email::Valid::Loose|Email::Valid::Loose> (tweaked lightly to wrap
for POD)

    (?x-ism:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]
    \000-\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n\015
    "]*)*")(?:(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[
    \]\000-\037\x80-\xff])|"[^\\\x80-\xff\n\015"]*(?:\\[^\x80-\xff][^\\\x80-\xff\n
    \015"]*)*")|\.)*\@(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,
    ;:".\\\[\]\000-\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]
    )(?:\.(?:[^(\040)<>@,;:".\\\[\]\000-\037\x80-\xff]+(?![^(\040)<>@,;:".\\\[\]\000
    -\037\x80-\xff])|\[(?:[^\\\x80-\xff\n\015\[\]]|\\[^\x80-\xff])*\]))*)

which is constructed from the following code:

    my $esc         = '\\\\';
    my $period      = '\.';
    my $space       = '\040';
    my $open_br     = '\[';
    my $close_br    = '\]';
    my $nonASCII    = '\x80-\xff';
    my $ctrl        = '\000-\037';
    my $cr_list     = '\n\015';
    my $qtext       = qq/[^$esc$nonASCII$cr_list\"]/; # "
    my $dtext       = qq/[^$esc$nonASCII$cr_list$open_br$close_br]/;
    my $quoted_pair = qq<$esc>.qq<[^$nonASCII]>;
    my $atom_char   = qq/[^($space)<>\@,;:\".$esc$open_br$close_br$ctrl$nonASCII]/;# "
    my $atom        = qq<$atom_char+(?!$atom_char)>;
    my $quoted_str  = qq<\"$qtext*(?:$quoted_pair$qtext*)*\">; # "
    my $word        = qq<(?:$atom|$quoted_str)>;
    my $domain_ref  = $atom;
    my $domain_lit  = qq<$open_br(?:$dtext|$quoted_pair)*$close_br>;
    my $sub_domain  = qq<(?:$domain_ref|$domain_lit)>;
    my $domain      = qq<$sub_domain(?:$period$sub_domain)*>;
    my $local_part  = qq<$word(?:$word|$period)*>; # This part is modified
    $Addr_spec_re   = qr<$local_part\@$domain>;

If you read the code from bottom to top, it is quite readable.  And,
you can even see the one violation of RFC822 that Tatsuhiko Miyagawa
deliberately put into Email::Valid::Loose to allow periods.  Look for
the C<|\.> in the upper regexp to see that same deviation.

One could certainly argue that the top regexp could be re-written more
legibly with C<m//x> and comments.  But the bottom version is
self-documenting and, for example, doesn't repeat C<\x80-\xff> 18
times.  Furthermore, it's much easier to compare the second version
against the source BNF grammar in RFC 822 to judge whether the
implementation is sound even before running tests.


=head1 CONFIGURATION

This policy allows regexps up to C<N> characters long, where C<N>
defaults to 60.  You can override this to set it to a different number
with the C<max_characters> setting.  To do this, put entries in a
F<.perlcriticrc> file like this:

    [RegularExpressions::ProhibitComplexRegexes]
    max_characters = 40


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
