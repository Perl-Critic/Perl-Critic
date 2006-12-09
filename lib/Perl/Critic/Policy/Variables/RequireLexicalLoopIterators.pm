##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Variables::RequireLexicalLoopIterators;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

my $desc = q{Loop iterator is not lexical};
my $expl = [ 108 ];

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST          }
sub default_themes    { return qw(core pbp danger)             }
sub applies_to       { return 'PPI::Statement::Compound' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    # First child will be 'for' or 'foreach' keyword
    my $first_child = $elem->schild(0);
    return if !$first_child;
    return if $first_child ne 'for' and $first_child ne 'foreach';

    # The second child could be the iteration list
    my $second_child = $elem->schild(1);
    return if !$second_child;
    return if $second_child->isa('PPI::Structure::ForLoop');

    return if $second_child eq 'my';

    return $self->violation( $desc, $expl, $elem );
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Variables::RequireLexicalLoopIterators

=head1 DESCRIPTION

C<for>/C<foreach> loops I<always> create new lexical variables for named
iterators.  In other words

  for $zed (...) {
     ...
  }

is equivalent to

  for my $zed (...) {
     ...
  }

This may not seem like a big deal until you see code like

  my $bicycle;
  for $bicycle (@things_attached_to_the_bike_rack) {
      if (
              $bicycle->is_red()
          and $bicycle->has_baseball_card_in_spokes()
          and $bicycle->has_bent_kickstand()
      ) {
          $bicycle->remove_lock();

          last;
      }
  }

  if ( $bicycle and $bicycle->is_unlocked() ) {
      ride_home($bicycle);
  }

which is not going to allow you to arrive in time for  dinner with your family
because the C<$bicycle> outside the loop is different from the C<$bicycle>
inside the loop.  You may have freed your bicycle, but you can't remember
which one it was.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

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
