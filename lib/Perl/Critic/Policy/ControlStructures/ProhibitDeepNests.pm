#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitDeepNests;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.19;

#----------------------------------------------------------------------------

my $desc = q{Code structure is deeply nested};
my $expl = q{Consider refactoring};

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Statement::Compound' }

#----------------------------------------------------------------------------

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, $class;

    #Set configuration
    $self->{_max_nests} = defined $args{max_nests} ? $args{max_nests} : 5;

    return $self;
}

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $nest_count = 1;  #For _this_ element
    my $parent = $elem;

    while ( $parent = $parent->parent() ){
        if( $parent->isa('PPI::Statement::Compound') ) {
            $nest_count++;
        }
    }

    if ( $nest_count > $self->{_max_nests} ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return;    #ok!
}


1;

__END__


#----------------------------------------------------------------------------

=pod

=for stopwords refactored

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitDeepNests

=head1 DESCRIPTION

Deeply nested code is often hard to understand and may be a sign that
it needs to be refactored.  There are several good books on how to
refactor code.  I like Martin Fowler's "Refactoring: Improving The
Design of Existing Code".


=head1 CONSTRUCTOR

This policy accepts an additional key-value pair in the C<new> method.
The key should be C<max_nests> and the value should be an integer
indicating the maximum number nested structures to allow.  Each for-loop,
if-else, while, and until block is counted as one nest.  Postfix forms
of these constructs are not counted.  The default maximum is 5.  When
using the L<Perl::Critic> engine, these can be configured in the
F<.perlcriticrc> file like this:

 [ControlStructures::ProhibitDeepNests]
 max_nests = 3

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

