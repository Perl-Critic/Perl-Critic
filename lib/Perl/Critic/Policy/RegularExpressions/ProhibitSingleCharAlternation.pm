package Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation;

use 5.006001;
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use List::MoreUtils qw(all);
use Readonly;

use Perl::Critic::Utils qw{ :booleans :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $EXPL => [265];

#-----------------------------------------------------------------------------

sub supported_parameters { return qw()                    }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core pbp performance ) }
sub applies_to           { return qw(PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp) }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $document ) = @_;

    # optimization: don't bother parsing the regexp if there are no pipes
    return if $elem !~ m/[|]/xms;

    my $re = $document->ppix_regexp_from_element( $elem ) or return;
    $re->failures() and return;

    my @violations;
    foreach my $node ( @{ $re->find_parents( sub {
                return $_[1]->isa( 'PPIx::Regexp::Token::Operator' )
                && $_[1]->content() eq q<|>;
            } ) || [] } ) {

        my @singles;
        my @alternative;
        foreach my $kid ( $node->children() ) {
            if ( $kid->isa( 'PPIx::Regexp::Token::Operator' )
                && $kid->content() eq q<|>
            ) {
                @alternative == 1
                    and $alternative[0]->isa( 'PPIx::Regexp::Token::Literal' )
                    and push @singles, map { $_->content() } @alternative;
                @alternative = ();
            } elsif ( $kid->significant() ) {
                push @alternative, $kid;
            }
        }
        @alternative == 1
            and $alternative[0]->isa( 'PPIx::Regexp::Token::Literal' )
            and push @singles, map { $_->content() } @alternative;

        if ( 1 < @singles ) {
            my $description =
                  'Use ['
                . join( $EMPTY, @singles )
                . '] instead of '
                . join q<|>, @singles;
            push @violations, $self->violation( $description, $EXPL, $elem );
        }
    }

    return @violations;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation - Use C<[abc]> instead of C<a|b|c>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Character classes (like C<[abc]>) are significantly faster than single
character alternations (like C<(?:a|b|c)>).  This policy complains if
you have more than one instance of a single character in an
alternation.  So C<(?:a|the)> is allowed, but C<(?:a|e|i|o|u)> is not.

NOTE: Perl 5.10 (not released as of this writing) has major regexp
optimizations which may mitigate the performance penalty of
alternations, which will be rewritten behind the scenes as something
like character classes.  Consequently, if you are deploying
exclusively on 5.10, yo might consider ignoring this policy.


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
