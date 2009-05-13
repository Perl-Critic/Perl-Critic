##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Structure;

use strict;
use warnings;

use PPI::Structure;

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

sub PPI::Structure::descendants {

    my ($self) = @_;

    return (

            ( $self->finish() || () ),

            ( map { ( $_ => $_->descendants() ) } @{ $self->{children} } ),

            ( $self->start() || () ),
    );
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
