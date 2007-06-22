##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception;

use strict;
use warnings;

our $VERSION = 1.06;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception' => {
        isa         => 'Exception::Class::Base',
        description => 'A problem discovered by Perl::Critic.',
    },
);

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception - A problem identified by L<Perl::Critic>

=head1 DESCRIPTION

A base class for all problems discovered by L<Perl::Critic>.  This
exists to enable differentiating exceptions from L<Perl::Critic> code
from those originating in other modules.

This is an abstract class.  It should never be instantiated.


=head1 METHODS

Only the ones inherited from L<Exception::Class>.


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
