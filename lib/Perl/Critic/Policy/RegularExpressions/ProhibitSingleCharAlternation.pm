##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::RegularExpressions::ProhibitSingleCharAlternation;

use 5.006001;
use strict;
use warnings;

use English qw(-no_match_vars);
use Readonly;
use Carp;
use List::MoreUtils qw(all);

use Perl::Critic::Utils qw{ :booleans :characters :severities };
use Perl::Critic::Utils::PPIRegexp qw{ ppiify parse_regexp };
use base 'Perl::Critic::Policy';

our $VERSION = '1.105';

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

sub initialize_if_enabled {
    return eval { require Regexp::Parser; 1 } ? $TRUE : $FALSE;
}

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # optimization: don't bother parsing the regexp if there are no pipes
    return if $elem !~ m/[|]/xms;

    my $re = ppiify(parse_regexp($elem));
    return if !$re;

    # Must pass a sub to find() because our node classes don't start with PPI::
    my $branches =
        $re->find(sub {$_[1]->isa('Perl::Critic::PPIRegexp::branch')});
    return if not $branches;

    my @violations;
    for my $branch (@{$branches}) {
        my @branch_children = $branch->children;
        if (all { $_->isa('Perl::Critic::PPIRegexp::exact') } @branch_children) {
            my @singles = grep { 1 == length $_ } @branch_children;
            if (1 < @singles) {
                my $description =
                      'Use ['
                    . join( $EMPTY, @singles )
                    . '] instead of '
                    . join q<|>, @singles;
                push @violations, $self->violation( $description, $EXPL, $elem );
            }
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


=head1 PREREQUISITES

This policy will disable itself if L<Regexp::Parser|Regexp::Parser> is not
installed.


=head1 CREDITS

Initial development of this policy was supported by a grant from the
Perl Foundation.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Chris Dolan.  Many rights reserved.

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
