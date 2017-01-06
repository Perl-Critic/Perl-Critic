package Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline;

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

Readonly::Scalar my $DESC => q<Use '{' and '}' to delimit multi-line regexps>;
Readonly::Scalar my $EXPL => [242];

Readonly::Array my @EXTRA_BRACKETS => qw{ () [] <> };

#-----------------------------------------------------------------------------

sub supported_parameters {
    return (
        {
            name               => 'allow_all_brackets',
            description        =>
                q[In addition to allowing '{}', allow '()', '[]', and '{}'.],
            behavior           => 'boolean',
        },
    );
}

sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp cosmetic ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    my %delimiters = ( q<{}> => 1 );
    if ( $self->{_allow_all_brackets} ) {
        @delimiters{ @EXTRA_BRACKETS } = (1) x @EXTRA_BRACKETS;
    }

    $self->{_allowed_delimiters} = \%delimiters;

    return $TRUE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $re = $elem->get_match_string();
    return if $re !~ m/\n/xms;

    my ($match_delim) = $elem->get_delimiters();
    return if $self->{_allowed_delimiters}{$match_delim};

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireBracesForMultiline - Use C<{> and C<}> to delimit multi-line regexps.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


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

Is that an improvement?  Marginally, but yes.  The curly braces lead
the eye better.


=head1 CONFIGURATION

There is one option for this policy, C<allow_all_brackets>.  If this
is true, then, in addition to allowing C<{}>, the other matched pairs
of C<()>, C<[]>, and C<< <> >> are allowed.


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
