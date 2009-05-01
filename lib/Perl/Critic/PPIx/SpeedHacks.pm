##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic/lib/Perl/Critic.pm $
#     $Date: 2009-02-01 18:11:13 -0800 (Sun, 01 Feb 2009) $
#   $Author: clonezone $
# $Revision: 3099 $
##############################################################################

package Perl::Critic::PPIx::SpeedHacks;

use strict;
use warnings;
use Scalar::Util qw(weaken);

#-----------------------------------------------------------------------------

no warnings qw(redefine);     ## no critic (NoWarnings)
no warnings qw(ambiguous);    ## no critic (NoWarnings)
no strict qw(refs);           ## no critic (NoStrict ProlongedStrictureOverride)

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------
# Calling subs that install our caching methods in the PPI namespace...

__install_ppi_document_serialize();
__install_ppi_node_content();
__install_ppi_node_find();
__install_ppi_node_find_first();
__install_ppi_node_find_any();
__install_ppi_element_sprevious_sibling();
__install_ppi_element_snext_sibling();
__install_ppi_element_isa();

#-----------------------------------------------------------------------------
# Our Document is immutable, so the serialized version will always be
# the same.  So here we replace Document::serialize() with a caching
# one.

sub __install_ppi_document_serialize {

    require PPI::Document;

    my $original_method = *PPI::Document::serialize{CODE};
    *{'PPI::Document::serialize'} = sub { return $_[0]->{_serialize} ||= $original_method->(@_); };

    return;
}

#----------------------------------------------------------------------------
# And since our Document is immutable, the content of any given Node
# is always going to be the same as well.  So here we replace
# Node::content() with a caching one.

sub __install_ppi_node_content {

    require PPI::Node;

    my $original_method = *PPI::Node::content{CODE};
    *{'PPI::Node::content'} = sub { return $_[0]->{_content} ||= $original_method->(@_); };

    return;
}

#----------------------------------------------------------------------------
# The following is based on the caching find() method that was
# originally created for Perl::Critic::Document.  The idea is: for any
# given Node, cache references to each descendent, and key them by
# type.  Subsequent requests to find a type will be answered by
# looking in the cache.

sub __install_ppi_node_find {

    require PPI::Node;

    my $original_method = *PPI::Node::find{CODE};
    *{'PPI::Node::find'} = sub {

        my ( $self, $wanted, @more_args ) = @_;
        my $type = ref $self;

        # This method can only find elements by their class names.  For
        # other types of searches, delegate to the PPI::Node
        if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
            return $original_method->(@_);
        }

        # Build the class cache if it doesn't exist.  This happens at most
        # once per Perl::Critic::Node instance.  %elements_of will be
        # populated with arrays of elements, keyed by the type of element

        if ( !$self->{_elements_of} ) {

            my $cache = {};

            # For a PPI::Document node, the cache actually contains a reference
            # to the node itself.  This is to enable Perl::Critic::Document
            # to search itself.  We may be able to tweak P::C::D so that this
            # anomaly isn't necesssary.

            if ( $type eq 'PPI::Document' ) {
                $cache->{$type} = [$self];
                weaken( $cache->{$type}->[0] );
            }

            # _caching_finder() returns a reference to a function that populates
            # the cache that you specify.  We then call PPI's find() method,
            # using that function as the callback.  Thus, our cache is populated
            # as a side effect of the find().

            my $finder_coderef = _caching_finder($cache);
            $original_method->( $self, $finder_coderef );
            $self->{_elements_of} = $cache;
        }

        # find() must return false-but-defined on failure.
        return $self->{_elements_of}->{$wanted} || q{};
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_ppi_node_find_first {

    require PPI::Node;

    my $original_method = *PPI::Node::find_first{CODE};
    *{'PPI::Node::find_first'} = sub {

        my ( $self, $wanted, @more_args ) = @_;

        # This method can only find elements by their class names.  For
        # other types of searches, delegate to the PPI::Document
        if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
            return $original_method->(@_);
        }

        my $result = $self->find( $wanted, @more_args );
        return $result ? $result->[0] : $result;
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_ppi_node_find_any {

    require PPI::Node;

    my $original_method = *PPI::Node::find_any{CODE};
    *{'PPI::Node::find_any'} = sub {

        my ( $self, $wanted, @more_args ) = @_;

        # This method can only find elements by their class names.  For
        # other types of searches, delegate to the PPI::Document
        if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
            return $original_method->(@_);
        }

        my $result = $self->find( $wanted, @more_args );
        return $result ? 1 : $result;
    };

    return;
}

#----------------------------------------------------------------------------
# This sub generates the "wanted" callback function that is used to
# populate the cache for the various "find*" functions above.

sub _caching_finder {

    my $cache_ref = shift;    # These vars will persist for the life
    my %isa_cache = ();       # of the code ref that this sub returns

    # Gather up all the PPI elements and sort by @ISA.  Note: if any
    # instances used multiple inheritance, this implementation would
    # lead to multiple copies of $element in the $elements_of lists.
    # However, PPI::* doesn't do multiple inheritance, so we are safe

    return sub {
        my ( undef, $element ) = @_;
        my $classes = $isa_cache{ ref $element };
        if ( !$classes ) {
            $classes = [ ref $element ];

            # Use a C-style loop because we append to the classes array inside
            for ( my $i = 0; $i < @{$classes}; $i++ ) {    ## no critic(ProhibitCStyleForLoops)
                no strict 'refs';                          ## no critic(ProhibitNoStrict)
                push @{$classes}, @{"$classes->[$i]::ISA"};
                $cache_ref->{ $classes->[$i] } ||= [];
            }
            $isa_cache{ $classes->[0] } = $classes;
        }

        for my $class ( @{$classes} ) {
            push @{ $cache_ref->{$class} }, $element;
        }

        return 0;                                          # 0 tells find() to keep traversing,
                                                           # but not to store this $element
    };
}

#----------------------------------------------------------------------------
# These also replace commonly used methods on PPI::Element with versions
# that cache the results.  I'm not really sure how much of win these are.

sub __install_ppi_element_sprevious_sibling {

    require PPI::Element;

    my $original_method = *PPI::Element::sprevious_sibling{CODE};
    *{'PPI::Element::sprevious_sibling'} = sub {

        my ($self) = @_;

        if ( not exists $self->{_sprev} ) {
            my $sprev = $original_method->(@_);
            $self->{_sprev} = $sprev;
            $sprev && weaken( $self->{_sprev} );
        }

        return $self->{_sprev};
    };

    return;
}

#----------------------------------------------------------

sub __install_ppi_element_snext_sibling {

    require PPI::Element;

    my $original_method = *PPI::Element::snext_sibling{CODE};
    *{'PPI::Element::snext_sibling'} = sub {

        my ($self) = @_;

        if ( not exists $self->{_snext} ) {
            my $snext = $original_method->(@_);
            $self->{_snext} = $snext;
            $snext && weaken( $self->{_snext} );
        }

        return $self->{_snext};
    };

    return;
}

#----------------------------------------------------------------------------
# This injects a PPI::Element::isa() function that caches the results.

sub __install_ppi_element_isa {

    require PPI::Element;
    my %ISA_CACHE;

    *{'PPI::Element::isa'} = sub {

        my $type = ref $_[0];
        return $ISA_CACHE{$type}->{$_[1]} if defined $ISA_CACHE{$type}->{$_[1]};
        return $ISA_CACHE{$type}->{$_[1]} = $_[0]->SUPER::isa($_[1]);
    };

    return;
}

#----------------------------------------------------------------------------
1;

__END__

=pod

=head1 NAME

Perl::Critic::PPIx::SpeedHacks

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
