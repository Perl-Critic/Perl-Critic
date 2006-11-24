########################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Document;

use strict;
use warnings;
use PPI::Document;

#----------------------------------------------------------------------------

our $VERSION = 0.22;

#----------------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {  ## no critic(ProhibitAutoloading)
   my ( $function_name ) = $AUTOLOAD =~ m/ ([^:\']+) \z /xms;
   return if $function_name eq 'DESTROY';
   my $self = shift;
   return $self->{_doc}->$function_name(@_);
}

#----------------------------------------------------------------------------

sub new {
    my ($class, $doc) = @_;
    return bless { _doc => $doc }, $class;
}

#----------------------------------------------------------------------------

sub isa {
    my $self = shift;
    return $self->SUPER::isa(@_)
        || ( (ref $self) && $self->{_doc} && $self->{_doc}->isa(@_) );
}

#----------------------------------------------------------------------------

sub find {
    my ($self, $wanted) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find($wanted, @_);
    }

    # Build the class cache if it doesn't exist.  This happens at most
    # once per Perl::Critic::Document instance.  %elements of will be
    # populated as a side-effect of calling the $finder_sub coderef
    # that is produced by the caching_finder() closure.
    if ( !$self->{_elements_of} ) {
        my %cache = ( 'PPI::Document' => [ $self ] );
        my $finder_coderef = _caching_finder( \%cache );
        $self->{_doc}->find( $finder_coderef );
        $self->{_elements_of} = \%cache;
    }

    # find() must return false-but-defined on fail
    return $self->{_elements_of}->{$wanted} || q{};
}

#----------------------------------------------------------------------------

sub find_first {
    my ($self, $wanted) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_first($wanted, @_);
    }

    my $result = $self->find($wanted);
    return $result ? $result->[0] : $result;
}

#----------------------------------------------------------------------------

sub find_any {
    my ($self, $wanted) = @_;

    # This method can only find elements by their class names.  For
    # other types of searches, delegate to the PPI::Document
    if ( ( ref $wanted ) || !$wanted || $wanted !~ m/ \A PPI:: /xms ) {
        return $self->{_doc}->find_any($wanted, @_);
    }

    my $result = $self->find($wanted);
    return $result ? 1 : $result;
}

#----------------------------------------------------------------------------

sub filename {
    my ($self) = @_;
    return $self->{_doc}->can('filename') ? $self->{_doc}->filename : undef;
}

#----------------------------------------------------------------------------

sub _caching_finder {

    my $cache_ref = shift;  # These vars will persist for the life
    my %isa_cache = ();     # of the code ref that this sub returns


    # Gather up all the PPI elements and sort by @ISA.  Note: if any
    # instances used multiple inheritance, this implementation would
    # lead to multiple copies of $element in the $elements_of lists.
    # However, PPI::* doesn't do multiple inheritance, so we are safe

    return sub {
        my $element = $_[1];
        my $classes = $isa_cache{ref $element};
        if ( !$classes ) {
            $classes = [ ref $element ];
            # Use a C-style loop because we append to the classes array inside
            for ( my $i = 0; $i < @{$classes}; $i++ ) { ## no critic(ProhibitCStyleForLoops)
                no strict 'refs';                       ## no critic(ProhibitNoStrict)
                push @{$classes}, @{"$classes->[$i]::ISA"};
                $cache_ref->{$classes->[$i]} ||= [];
            }
            $isa_cache{$classes->[0]} = $classes;
        }

        for my $class ( @{$classes} ) {
            push @{$cache_ref->{$class}}, $element;
        }

        return 0; # 0 tells find() to keep traversing, but not to store this $element
    };
}

#----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords pre-caches

=head1 NAME

Perl::Critic::Document - Caching wrapper around PPI::Document

=head1 SYNOPSIS

    use PPI::Document;
    use Perl::Critic::Document;
    my $doc = PPI::Document->new('Foo.pm');
    $doc = Perl::Critic::Document->new($doc);
    ## Then use the instance just like a PPI::Document

=head1 DESCRIPTION

Perl::Critic does a lot of iterations over the PPI document tree via
the C<PPI::Document::find()> method.  To save some time, this class
pre-caches a lot of the common C<find()> calls in a single traversal.
Then, on subsequent requests we return the cached data.

This is implemented as a facade, where method calls are handed to the
stored C<PPI::Document> instance.

=head1 CAVEATS

This facade does not implement the overloaded operators from
L<PPI::Document> (that is, the C<use overload ...> work). Therefore,
users of this facade must not rely on that syntactic sugar.  So, for
example, instead of C<my $source = "$doc";> you should write C<my
$source = $doc->content();>

Perhaps there is a CPAN module out there which implements a facade
better than we do here?

=head1 METHODS

=over

=item $pkg->new($doc)

Create a new instance referencing a PPI::Document instance.

=item $self->find($wanted)

=item $self->find_first($wanted)

=item $self->find_any($wanted)

If C<$wanted> is a simple PPI class name, then the cache is employed.
Otherwise we forward the call to the corresponding method of the
C<PPI::Document> instance.

=item $self->filename()

Returns the filename for the source code if applicable
(PPI::Document::File) or C<undef> otherwise (PPI::Document).

=item $self->isa( $classname )

To be compatible with other modules that expect to get a PPI::Document, the
Perl::Critic::Document class masqerades as the PPI::Document class.

=back

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006 Chris Dolan.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 expandtab :
