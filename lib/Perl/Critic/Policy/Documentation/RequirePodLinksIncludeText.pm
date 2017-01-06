package Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText;

use 5.006001;

use strict;
use warnings;

use Readonly;
use English qw{ -no_match_vars };
use Perl::Critic::Utils qw{ :booleans :characters :severities };
use base 'Perl::Critic::Policy';

use Perl::Critic::Utils::POD::ParseInteriorSequence;

#-----------------------------------------------------------------------------

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => 'Without text, you are at the mercy of the POD translator';

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name            => 'allow_external_sections',
            description     => 'Allow external sections without text',
            default_string  => '1',
            behavior        => 'boolean',
        },
        {
            name            => 'allow_internal_sections',
            description     => 'Allow internal sections without text',
            default_string  => '1',
            behavior        => 'boolean',
        },
    );
}
sub default_severity { return $SEVERITY_LOW            }
sub default_themes   { return qw(core maintenance)     }
sub applies_to       { return 'PPI::Token::Pod'        }

#-----------------------------------------------------------------------------

Readonly::Scalar my $INCREMENT_NESTING => 1;
Readonly::Scalar my $DECREMENT_NESTING => -1;
Readonly::Hash my %ESCAPE_NESTING => (
    '<' => $INCREMENT_NESTING,
    '>' => $DECREMENT_NESTING,
);

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my @violations;

=begin comment

    my $pod = $elem->content();

    # We look for _any_ POD escape, not just L<>. This way we can avoid false
    # positives on constructions like C<< L<Foo> >>. In an attempt to be
    # upward compatible (and at a slight (I hope!) risk of false negatives),
    # we accept any upper case letter as beginning a formatting sequence, not
    # just [IBCLEFSXZ].
    SCAN_POD:
    while ( $pod =~ m/ ( [[:upper:]] ) ( <+ )   /smxg ) {

        # Collect the results of the match.
        my $formatter = $1;
        my $link_start = $LAST_MATCH_START[0];
        my $content_start = $LAST_MATCH_END[0];
        my $num_brkt = length $2;

        # The only way to handle arbitrarily-nested brackets before Perl
        # 5.10 is the (??{}) construction, which is _still_ marked
        # 'experimental' as of 5.12.3 and 5.13.9. Taking them at their
        # word, I'm going to find the end of the POD escape the hard
        # way.
        my $link_end = $link_start + 1;
        my $nest = 0;
        while ( 1 ) {
            $nest += $ESCAPE_NESTING{ substr $pod, $link_end++, 1 } || 0;
            $nest or last;
            $link_end < length $pod
                or last SCAN_POD;
        }

        # Manually advance past the end of the link so the regular
        # expression does not find any possible nested formatting.
        pos $pod = $link_end;

        # If it's not an 'L' formatter, we are not interested.
        'L' eq $formatter or next;

        # Save both the link itself and its contents for further analysis.
        my $link = substr $pod, $link_start, $link_end - $link_start;
        my $content = substr $pod, $content_start,
            $link_end - $num_brkt - $content_start;

        # If the link is allowed, pass on to the next one.
        $self->_allowed_link( $content ) and next;

        # A-Hah! Gotcha!
        my $line_number = $elem->line_number() + (
            substr( $pod, 0, $link_start ) =~ tr/\n/\n/ );
        push @violations, $self->violation(
            "Link $link on line $line_number does not specify text",
            $EXPL, $elem );

    }

=end comment

=cut

    my $parser = Perl::Critic::Utils::POD::ParseInteriorSequence->new();
    $parser->errorsub( sub { return 1 } );  # Suppress error messages.

    foreach my $seq ( $parser->get_interior_sequences( $elem->content() ) ) {

        # Not interested in nested thing like C<< L<Foo> >>. I think.
        $seq->nested() and next;

        # Not interested in anything but L<...>.
        'L' eq $seq->cmd_name() or next;

        # If the link is allowed, pass on to the next one.
        $self->_allowed_link( $seq ) and next;

        # A-Hah! Gotcha!
        my $line_number = $elem->line_number() + ( $seq->file_line() )[1] - 1;
        push @violations, $self->violation(
            join( $SPACE, 'Link', $seq->raw_text(),
                "on line $line_number does not specify text" ),
            $EXPL, $elem );
    }

    return @violations;
}

sub _allowed_link {

=begin comment

    my ( $self, $content ) = @_;

=end comment

=cut

    my ( $self, $pod_seq ) = @_;

    # Extract the content of the sequence.
    my $content = $pod_seq->raw_text();
    $content = substr $content, 0, - length $pod_seq->right_delimiter();
    $content = substr $content, length( $pod_seq->cmd_name() ) + length(
        $pod_seq->left_delimiter() );

    # Not interested in hyperlinks.
    $content =~ m{ \A \w+ : (?! : ) }smx
        and return $TRUE;

    # Links with text specified are good.
    $content =~ m/ [|] /smx
        and return $TRUE;

    # Internal sections without text are either good or bad, depending on how
    # we are configured.
    $content =~ m{ \A [/"] }smx
        and return $self->{_allow_internal_sections};

    # External sections without text are either good or bad, depending on how
    # we are configured.
    $content =~ m{ / }smx
        and return $self->{_allow_external_sections};

    # Anything else without text is bad.
    return $FALSE;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords licence

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText - Provide text to display with your pod links.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

This Policy requires your POD links to contain text to override your POD
translator's default link text, where this is possible.  Failure to provide
your own text leaves you at the mercy of the POD translator, which may
display something like C<< LE<lt>Foo> >> as C<the Foo manpage>.

By default, links that specify a documentation section (for example, C<<
LE<lt>Foo/bar> >>, or C<< LE<lt>/bar> >>) are exempt from this Policy.


=head1 CONFIGURATION

This Policy has two boolean options to configure the handling of links that
specify a documentation section.

The C<allow_external_sections> option configures the handling of links of the
form C<< LE<lt>Foo/bar> >>.  If true, such links are accepted even without a text
specification.  Such links tend to be turned into something like C<bar in
Foo>.

By default, this option is asserted.  If you want to prohibit things like
C<< LE<lt>Foo/bar> >> (while allowing things like C<<< LE<lt>E<lt> Foo->bar()|Foo/bar >>
>>>), put something like this in your F<.perlcriticrc>:

 [Documentation::RequirePodLinksIncludeText]
 allow_external_sections = 0

The C<allow_internal_sections> option configures the handling of links of the
form C<< LE<lt>/bar> >>.  If true, such links are accepted even without a text
specification.  Such links tend to be turned into something like C<bar>.

By default, this option is asserted.  If you want to prohibit things like
C<< LE<lt>/bar> >> (while allowing things like C<< LE<lt>bar()|/bar> >>), put
something like this in your F<.perlcriticrc>:

 [Documentation::RequirePodLinksIncludeText]
 allow_internal_sections = 0


=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>


=head1 COPYRIGHT

Copyright (c) 2009-2011 Thomas R. Wyant, III.

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
