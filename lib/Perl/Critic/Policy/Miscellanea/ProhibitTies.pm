#######################################################################
#      $URL$
#     $Date: 2006-02-02 18:38:30 -0800 (Thu, 02 Feb 2006) $
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Miscellanea::ProhibitTies;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Tied variable used};
my $expl = [ 451 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW }
sub applies_to { return 'PPI::Token::Word' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if ($elem ne 'tie');
    return if is_hash_key( $elem );
    return if is_method_call( $elem );
    return if is_subroutine_name($elem);

    return $self->violation( $desc, $expl, $elem );
}


1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::ProhibitTies

=head1 DESCRIPTION

Conway discourages using C<tie> to bind Perl primitive variables to
user-defined objects.  Unless the tie is done close to where the
object is used, other developers probably won't know that the variable
has special behavior.  If you want to encapsulate complex behavior,
just use a proper object or subroutine.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
