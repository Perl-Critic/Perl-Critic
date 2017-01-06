package Perl::Critic::Policy::Documentation::RequirePodAtEnd;

use 5.006001;
use strict;
use warnings;
use Readonly;

use List::Util qw(first);

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $POD_RX => qr{\A = (?: for|begin|end ) }xms;
Readonly::Scalar my $DESC => q{POD before __END__};
Readonly::Scalar my $EXPL => [139, 140];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                      }
sub default_severity     { return $SEVERITY_LOWEST        }
sub default_themes       { return qw( core cosmetic pbp ) }
sub applies_to           { return 'PPI::Document'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # No POD means no violation
    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if !$pods_ref;

    # Look for first POD tag that isn't =for, =begin, or =end
    my $pod = first { $_ !~ $POD_RX} @{ $pods_ref };
    return if !$pod;

    my $end = $doc->find_first('PPI::Statement::End');
    if ($end) {  # No __END__ means definite violation
        my $pod_loc = $pod->location();
        my $end_loc = $end->location();
        if ( $pod_loc->[0] > $end_loc->[0] ) {
            # POD is after __END__, or relative position couldn't be determined
            return;
        }
    }

    return $self->violation( $DESC, $EXPL, $pod );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePodAtEnd - All POD should be after C<__END__>.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Perl stops processing code when it sees an C<__END__> statement.  So,
to save processing time, it's faster to put documentation after the
C<__END__>.  Also, writing all the POD in one place usually leads to a
more cohesive document, rather than being forced to follow the layout
of your code.  This policy issues violations if any POD is found
before an C<__END__>.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

Some folks like to use C<=for>, and C<=begin>, and C<=end> tags to
create block comments in-line with their code.  Since those tags
aren't usually part of the documentation, this Policy does allows them
to appear before the C<__END__> statement.

    =begin comments

    frobulate()
    Accepts:  A list of things to frobulate
    Returns:  True if successful

    =end comments

    sub frobulate { ... }

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

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
