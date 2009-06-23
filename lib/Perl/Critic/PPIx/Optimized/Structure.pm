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

=head1 NAME

Perl::Critic::PPIx::Optimized::Structure - Optimizations for PPI::Structures

=head1 SYNOPSIS

  use Perl::Critic::PPIx::Optimized::Structure;

=head1 DESCRIPTION

This module replaces methods in L<PPI::Structure> with custom versions
that use caching to improve performance.  There are no user-serviceable
parts in here.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2009 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

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
