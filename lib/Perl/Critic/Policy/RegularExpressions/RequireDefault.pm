package Perl::Critic::Policy::RegularExpressions::RequireDefault;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.133_01';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/a" or "/aa" flag};
Readonly::Scalar my $EXPL => q{Use regular expression "/a" or "/aa" flag};
Readonly::Scalar my $TRUE => 1;
Readonly::Scalar my $FALSE => 0;

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'strict',
            description        => q[Enforces "/aa" over the default "/a".],
            behavior           => 'boolean',
        },
    );
}

sub default_severity { return $SEVERITY_MEDIUM }
sub default_themes   { return qw< security > }

sub applies_to {
    return qw<
        PPI::Token::Regexp::Match
        PPI::Token::Regexp::Substitute
        PPI::Token::QuoteLike::Regexp
        PPI::Statement::Include
    >;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( $self->_pragma_enabled($elem) ) {
        return;    # ok!;
    }

    my $re = $doc->ppix_regexp_from_element($elem)
        or return;

    if ( not $self->_allowed_modifier($re)) {
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return;        # ok!;
}

sub _allowed_modifier {
    my ( $self, $re ) = @_;

    if ( $re->modifier_asserted('a') and not $self->{_strict} ) {
        return $TRUE;
    }

    if ( $re->modifier_asserted('aa') ) {
        return $TRUE;
    }

    return $FALSE;
}


sub _correct_modifier {
    my ( $self, $elem ) = @_;

    if ( $elem->arguments eq 'a' and not $self->{_strict} ) {
        return $TRUE;
    }

    if ( $elem->arguments eq 'aa' ) {
        return $TRUE;
    }

    return $FALSE;
}

sub _pragma_enabled {
    my ( $self, $elem ) = @_;

    if (    $elem->can('type')
        and $elem->type() eq 'use'
        and $elem->pragma() eq 're'
        and $self->_correct_modifier($elem) )
    {
        return $TRUE;
    }

    return $FALSE;
}

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_strict} = $config->get('strict') || 0;

    return $TRUE;
}

1;

__END__

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireDefault - Always use the C</a> or C</aa> modifier with regular expressions.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic> distribution.

=head1 DESCRIPTION

This policy aims to help enforce Perl's protective measures against security vulnerabilities related to Unicode, such as:

=over

=item * Visual Spoofing

=item * Character and String Transformation Vulnerabilities

=back

The C</a> and C</aa> modifiers standing for ASCII-restrict or ASCII-safe, provides protection for applications that do not need to be exposed to all of Unicode and possible security issues with Unicode.

C</a> causes the sequences C<\d>, C<\s>, C<\w>, and the Posix character classes to match only in the ASCII range. Meaning:

=over

=item * C<\d> means the digits C<0> to C<9>

    my $ascii_letters =~ m/[A-Z]*/i;  # not ok
    my $ascii_letters =~ m/[A-Z]*/a;  # ok
    my $ascii_letters =~ m/[A-Z]*/aa; # ok

=item * C<\s> means the five characters C<[ \f\n\r\t]>, and starting in Perl v5.18, also the vertical tab

    my $characters =~ m/[ \f\n\r\t]*/;   # not ok
    my $characters =~ m/[ \f\n\r\t]*/a;  # ok
    my $characters =~ m/[ \f\n\r\t]*/aa; # ok

=item * C<\w> means the 63 characters C<[A-Za-z0-9_]> and all the Posix classes such as C<[[:print:]]> match only the appropriate ASCII-range characters

    my $letters =~ m/[A-Za-z0-9_]*/;   # not ok
    my $letters =~ m/[A-Za-z0-9_]*/a;  # ok
    my $letters =~ m/[A-Za-z0-9_]*/aa; # ok

=back

The policy also supports the pragma:

    use re 'a';

and:

    use re 'aa';

Which mean it will not evaluate the regular expressions any further:

    use re 'a';
    my $letters =~ m/[A-Za-z0-9_]*/;   # ok

Do note that the C</a> and C</aa> modifiers require Perl 5.14, so by using the recommended modifiers you indirectly introduce a requirement for Perl 5.14.

This policy is inspired by L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting|https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting> and many implementation details was lifted from this particular distribution.

=head1 CONFIGURATION

The policy has a single configuration parameter: C<strict>. The default is disabled (C<0>).

The policy, if enabled, allow for both C<'a'> and C<'aa'>, if strict however is enabled, C<'a'> will trigger a violation and C<'aa'> will not.

Example configuration:

    [RegularExpressions::RequireDefault]
    strict = 1

Do note that the policy also evaluates if the pragmas are enabled, meaning: C<use re 'a';> will trigger a violation and C<use re 'a';> will not if the policy is configured for strict evaluation.

=head1 INCOMPATIBILITIES

This distribution holds no known incompatibilities at this time, please see L</DEPENDENCIES AND REQUIREMENTS> for details on version requirements.

=head1 BUGS AND LIMITATIONS

=over

=item * The pragma handling does not take into consideration of a pragma is disabled.

=item * The pragma handling does not take lexical scope into consideration properly and only detects the definition once

=back

This distribution holds no other known limitations or bugs at this time, please refer to the L<the issue listing on GitHub|https://github.com/jonasbn/perl-critic-policy-regularexpressions-requiredefault/issues> for more up to date information.

=head1 SEE ALSO

=over

=item * L<Perl regular expression documentation: perlre|https://perldoc.perl.org/perlre.html>

=item * L<Perl delta file describing introduction of modifiers in Perl 5.14|https://perldoc.pl/perl5140delta#%2Fd%2C-%2Fl%2C-%2Fu%2C-and-%2Fa-modifiers>

=item * L<Unicode Security Issues FAQ|http://www.unicode.org/faq/security.html>

=item * L<Unicode Security Guide|http://websec.github.io/unicode-security-guide/>

=item * L<Presentation: "Unicode Transformations: Finding Elusive Vulnerabilities" by Chris Weber for OWASP AppSecDC November 2009|https://www.owasp.org/images/5/5a/Unicode_Transformations_Finding_Elusive_Vulnerabilities-Chris_Weber.pdf|>

=item * L<Perl::Critic|https://metacpan.org/pod/Perl::Critic>

=item * L<Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting|https://metacpan.org/pod/Perl::Critic::Policy::RegularExpressions::RequireExtendedFormatting>

=back

=head1 MOTIVATION

The motivation for this Perl::Critic policy came from a L<tweet|https://twitter.com/jmaslak/status/1008896883169751040> by L<@joel|https://twitter.com/jmaslak>

    | Perl folk: Looking for a PR challenge task? Check for \d in regexes
    | that really should be [0-9] or should have the /a regex modifier.
    | Perl is multinational by default! #TPCiSLC

=head1 AUTHOR

=over

=item * jonasbn <jonasbn@cpan.org>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item * L<Joelle Maslak (@joel)|https://twitter.com/jmaslak> / L<JMASLAK|https://metacpan.org/author/JMASLAK> for the initial idea, see link to original tweet under L</MOTIVATION>

=item * L<Dan Book (@Grinnz)|https://github.com/Grinnz> / L<DBOOK|https://metacpan.org/author/DBOOK|> for information on Pragma and requirement for Perl 5.14, when using the modifiers handled and mentioned by this policy

=back

=head1 COPYRIGHT

Perl::Critic::Policy::RegularExpressions::RequireDefault is (C) by jonasbn 2018-2019

Perl::Critic::Policy::RegularExpressions::RequireDefault is released under the Artistic License 2.0

Please see the LICENSE file included with the distribution of this module

=cut
