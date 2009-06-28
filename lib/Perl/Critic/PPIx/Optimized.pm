##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic.pm $
#     $Date: 2009-02-01 18:11:13 -0800 (Sun, 01 Feb 2009) $
#   $Author: clonezone $
# $Revision: 3099 $
##############################################################################

package Perl::Critic::PPIx::Optimized;

use strict;
use warnings;

#-----------------------------------------------------------------------------

our $VERSION = '1.099_002';

#-----------------------------------------------------------------------------

use vars qw($OPTIMIZATIONS_WERE_LOADED);

#-----------------------------------------------------------------------------


BEGIN {

    require PPI;
    return if $PPI::VERSION ne '1.203';

    require Perl::Critic::PPIx::Optimized::Caches;
    require Perl::Critic::PPIx::Optimized::Document;
    require Perl::Critic::PPIx::Optimized::Structure;
    require Perl::Critic::PPIx::Optimized::Element;
    require Perl::Critic::PPIx::Optimized::Node;

    $OPTIMIZATIONS_WERE_LOADED = 1;
}

#-----------------------------------------------------------------------------

sub flush_caches {

    if ( $OPTIMIZATIONS_WERE_LOADED ) {
        Perl::Critic::PPIx::Optimized::Caches::flush_all();
    }

    return;
}

#----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::PPIx::Optimized

=head1 SYNOPSIS

  use Perl::Critic::PPIx::SpeedHacks;
  # and that's all there is to it!

=head1 DESCRIPTION

This module replaces several methods in the PPI namespace with custom versions
that cache their results to improve performance.  There are no user-serviceable
parts in here.

=head1 DISCUSSION

I used L<Devel::NYTProf> to analyze the performance of L<perlcritic> as it
critiqued a large number of files.  The results showed that we were spending a
lot of time in L<PPI> searching and stringifying parts of the Document.  As
PPI was originally written each one of these operations is done from scratch,
even if it had already been done before.  And for a dynamic Document, this is
perfectly reasonable.  However, L<Perl::Critic> implicitly expects the
document to be immutable.  Therefore, it was possible to rewrite some of the
methods in PPI to use a cache.

When using these cached methods, performance improved by about 30%.  However,
this measurement can vary significantly, depending on which policies are
active (the more Policies you use, the more performance benefit you'll see).
Also, certain Policies like C<RequireTidyCode> and C<PodSpelling> are very slow
and rely on external code, so they tend to skew performance measurements.

=head1 METHODS

=over

=item flush_caches()

Completely flushes all caches.

=back

=head1 IMPLEMENTATION NOTES

I first attempted to use L<memoize> as the caching mechanism.  But it caused
segmentation faults (probably because I wasn't purging the cache after each
document).  Rather than fuss with that, I just decided to roll my own caching
mechanism.  So that's what you see here.

I also shopped around on CPAN for a module that would allow me to replace
subroutines without those nasty typeglobs.  But I couldn't find one that would
also give me a handle to the original subroutine.  I'm open to suggestions if
you know of a solution here.

=head1 TODO

I don't want this kind of module to become a habit.  We should talk to Adam
Kennedy about possibly extending PPI with a proper PPI::Document::Immutable
subclass that has these sorts of caching methods built into it.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009 Jeffrey Ryan Thalhammer.  All rights reserved.

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
