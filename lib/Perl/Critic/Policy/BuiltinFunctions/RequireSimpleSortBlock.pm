##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##################################################################

package Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION; ## no critic;

#----------------------------------------------------------------------------

my $desc = q{Sort blocks should have a single statement};
my $expl = [ 149 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem ne 'sort');
    return if is_method_call($elem);
    return if is_hash_key($elem);
    return if is_subroutine_name($elem);

    my $sib = $elem->snext_sibling() || return;
    my $arg = $sib->isa('PPI::Structure::List') ? $sib->schild(0) : $sib;
    return if !$arg || !$arg->isa('PPI::Structure::Block');

    # If we get here, we found a sort with a block as the first arg
    return if ( 1 >= $arg->schildren() );

    # more than one child statements
    return $self->violation( $desc, $expl, $elem );
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::RequireSimpleSortBlock

=head1 DESCRIPTION

Conway advises that sort functions should be simple.  Any complicated
operations on list elements should be computed and cached (perhaps via
a Schwartzian Transform) before the sort, rather than computed inside
the sort block, because the sort block is called C<N log N> times
instead of just C<N> times.

This policy prohibits the most blatant case of complicated sort
blocks: multiple statements.  Future policies may wish to examine the
sort block in more detail -- looking for subroutine calls or large
numbers of operations.

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Dolan.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
