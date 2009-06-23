##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Caches;

use strict;
use warnings;

use base qw(Exporter);

#------------------------------------------------------------------------------

use vars qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT %FINDER);
our @EXPORT_OK = qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING %SERIALIZE %CONTENT %FINDER);

#------------------------------------------------------------------------------

sub flush_all {
    %SPREVIOUS_SIBLING = ();
    %SNEXT_SIBLING     = ();
    %SERIALIZE         = ();
    %CONTENT           = ();
    %FINDER            = ();
    return;
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::PPIx::Optimized::Caches - Caches used to optimize Perl::Critic

=head1 SYNOPSIS

  use Perl::Critic::PPIx::Optimized::Caches qw( NAMES_OF_CACHE_VARIABLES );
  Perl::Critic::PPIx::Optimized::Caches::flush_all();

=head1 DESCRIPTION

This module provides access to various hashes that are used to optimize the
performance of L<PPI|PPI>.  There are no user-servicable parts in here.

All hashes are keyed by the refaddr of the L<PPI::Node> or <PPI::Element>.
The hash values are the same as those returned by the PPI methods with the
same name as the cache variable.  Available caches are:

=over

=item %SPREVIOUS_SIBLING

Points to the previous signifigant sibling of the node or element.

=item %SNEXT_SIBLING

Points to the next significant sibling of the node or element.

=item %SERIALIZE

Points to the fully strigified representation of the node or element.
This usually only applies to a L<PPI::Document>.

=item %CONTENT

Points to the textual representation of the node or element.  This
applies to a L<PPI::Node> or L<PPI::Element>.

=item %FINDER

This one is a differnt, the keys are the PPI class names of all the children
of a node, and the values are array of references to all the children of
a particular class.  This is used to expedite searching for elements by type,
which is the most common type of search that we do.

=back

=head1 METHODS

=over

=item flush_all()

Cleares all caches.  This method is not exported.

=back

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
