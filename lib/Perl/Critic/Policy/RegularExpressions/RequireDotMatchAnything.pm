package Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything;

use 5.006001;
use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Regular expression without "/s" flag};
Readonly::Scalar my $EXPL => [ 240, 241 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                    }
sub default_severity     { return $SEVERITY_LOW         }
sub default_themes       { return qw<core pbp cosmetic> }
sub applies_to           { return qw<PPI::Token::Regexp::Match
                                     PPI::Token::Regexp::Substitute
                                     PPI::Token::QuoteLike::Regexp> }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $re = $doc->ppix_regexp_from_element( $elem )
        or return;
    $re->modifier_asserted( 's' )
        or return $self->violation( $DESC, $EXPL, $elem );

    return; #ok!;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::RegularExpressions::RequireDotMatchAnything - Always use the C</s> modifier with regular expressions.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

When asked what C<.> in a regular expression means, most people will
say that it matches any character, which isn't true.  It's actually
shorthand for C<[^\n]>.  Using the C<s> modifier makes C<.> act like
people expect it to.

    my $match = m< foo.bar >xm;  # not ok
    my $match = m< foo.bar >xms; # ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

Be cautious about slapping modifier flags onto existing regular
expressions, as they can drastically alter their meaning.  See
L<http://www.perlmonks.org/?node_id=484238> for an interesting
discussion on the effects of blindly modifying regular expression
flags.


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
