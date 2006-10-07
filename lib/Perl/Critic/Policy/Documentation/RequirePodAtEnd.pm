#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Documentation::RequirePodAtEnd;

use strict;
use warnings;
use Perl::Critic::Utils;
use List::Util qw(first);
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $pod_rx = qr{\A = (?: for|begin|end ) }mx;
my $desc = q{POD before __END__};
my $expl = [139, 140];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST   }
sub default_themes    { return qw( cosmetic pbp ) }
sub applies_to       { return 'PPI::Document'    }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # No POD means no violation
    my $pods_ref = $doc->find('PPI::Token::Pod');
    return if !$pods_ref;

    # Look for first POD tag that isn't =for, =begin, or =end
    my $pod = first { $_ !~ $pod_rx} @{ $pods_ref };
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

    return $self->violation( $desc, $expl, $pod );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Documentation::RequirePodAtEnd

=head1 DESCRIPTION

Perl stops processing code when it sees an C<__END__> statement.  So,
to save processing time, it's faster to put
documentation after the C<__END__>.  Also, writing all the POD in one
place usually leads to a more cohesive document, rather than being
forced to follow the layout of your code.  This policy issues
violations if any POD is found before an C<__END__>.

=head1 NOTES

Some folks like to use C<=for>, and C<=begin>, and C<=end> tags to
create block comments in-line with their code.  Since those tags aren't
usually part of the documentation, this Policy does allows them to
appear before the C<__END__> statement.

  =begin comments

  frobulate()
  Accepts:  A list of things to frobulate
  Returns:  True if succesful

  =end comments

  sub frobulate { ... }

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module

=cut
