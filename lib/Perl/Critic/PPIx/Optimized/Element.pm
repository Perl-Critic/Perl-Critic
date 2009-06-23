##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Element;

use strict;
use warnings;

use PPI::Element;
use Perl::Critic::PPIx::Optimized::Caches qw(%SPREVIOUS_SIBLING %SNEXT_SIBLING);
#use Scalar::Util qw(weaken);

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

__install_sprevious_sibling();
__install_snext_sibling();

#-----------------------------------------------------------------------------

sub __install_sprevious_sibling {

    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Element::sprevious_sibling{CODE};
    *{'PPI::Element::sprevious_sibling'} = sub {

        my ($self) = @_;
	my $refaddr = refaddr $self;
	return $SPREVIOUS_SIBLING{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_snext_sibling {


    no strict 'refs';
    no warnings qw(once redefine);
    my $original_method = *PPI::Element::snext_sibling{CODE};
    *{'PPI::Element::snext_sibling'} = sub {

        my ($self) = @_;
        my $refaddr = refaddr $self;
	return $SNEXT_SIBLING{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#-----------------------------------------------------------------------------

sub PPI::Element::descendants { return }  # An Element has no descendants

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::PPIx::Optimized::Element - Optimizations for PPI::Elements

=head1 SYNOPSIS

  use Perl::Critic::PPIx::Optimized::Element;

=head1 DESCRIPTION

This module replaces methods in L<PPI::Element> with custom versions
that use caching to improve performance.  There are no user-servicable
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
