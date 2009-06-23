##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::PPIx::Optimized::Node;

use strict;
use warnings;

use PPI::Node;
use Perl::Critic::Utils::PPI qw(class_ancestry);
use Perl::Critic::PPIx::Optimized::Caches qw(%CONTENT %FINDER);

#-----------------------------------------------------------------------------

our $VERSION = '1.098';

#-----------------------------------------------------------------------------

__install_content();
__install_find_first();
__install_find_any();
__install_find();

#-----------------------------------------------------------------------------

sub __install_content {

    no strict 'refs';                 ## no critic (ProhibitNoStrict Prolonged);
    no warnings qw(once redefine);    ## no critic (ProhibitNoWarnings);
    my $original_method = *PPI::Node::content{CODE};
    *{'PPI::Node::content'} = sub {

        my ($self) = @_;
        my $refaddr = refaddr $self;
        return $CONTENT{$refaddr} ||= $original_method->(@_);
    };

    return;
}

#----------------------------------------------------------------------------

sub __install_find {

    no strict 'refs';                ## no critic (ProhibitNoStrict Prolonged);
    no warnings qw(once redefine);   ## no critic (ProhibitNoWarnings);
    my $original_method = *PPI::Node::find{CODE};
    *{'PPI::Node::find'} = sub {

        my ( $self, $wanted, @more_args ) = @_;
        my $refaddr = refaddr $self;

        # This method can only find elements by their class names.  For
        # other types of searches, delegate to the PPI::Node
        if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
            return $original_method->(@_);
        }

        # Build the cache of descendants if it doesn't exist.  This happens at
        # most once per Perl::Critic::Node instance.  The cache will be
        # populated with arrays of elements, keyed by the type of element
        $FINDER{$refaddr} ||= __build_finder_cache($self);

        # find() must return false-but-defined on failure.
        return $FINDER{$refaddr}->{$wanted} || q{};
    };

    return;
}

#-----------------------------------------------------------------------------

sub __install_find_first {

    no strict 'refs';                ## no critic (ProhibitNoStrict Prolonged);
    no warnings qw(once redefine);   ## no critic (ProhibitNoWarnings);
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

sub __install_find_any {

    no strict 'refs';                ## no critic (ProhibitNoStrict Prolonged);
    no warnings qw(once redefine);   ## no critic (ProhibitNoWarnings);
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

my %ISA_CACHE;

#----------------------------------------------------------------------------

sub __build_finder_cache {

    my $node = shift;
    my %token_cache = ();

    for my $descendant ( $node->descendants() ) {

        my $this_class = ref $descendant;
        my $parent_classes = $ISA_CACHE{$this_class} ||= class_ancestry($this_class);

        for my $class ( @{$parent_classes} ) {
            $token_cache{$class} ||= [];
            push @{ $token_cache{$class} }, $descendant;
        }
    }

    return \%token_cache;
}

#-----------------------------------------------------------------------------

sub PPI::Node::descendants {
    my ($node) = @_;
    return map { ( $_ => $_->descendants() ) } @{ $node->{children} };
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::PPIx::Optimized::Node - Optimizations for PPI::Nodes

=head1 SYNOPSIS

  use Perl::Critic::PPIx::Optimized::Node;

=head1 DESCRIPTION

This module replaces methods in L<PPI::Node> with custom versions
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

