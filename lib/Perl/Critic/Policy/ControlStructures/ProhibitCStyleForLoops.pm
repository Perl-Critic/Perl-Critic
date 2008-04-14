##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops;

use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :characters :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.083_001';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{C-style "for" loop used};
Readonly::Scalar my $EXPL => [ 100 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_LOW              }
sub default_themes       { return qw( core pbp maintenance ) }
sub applies_to           { return 'PPI::Structure::ForLoop'  }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    if ( _is_cstyle($elem) ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

sub _is_cstyle {
    my $elem      = shift;
    my $nodes_ref = $elem->find('PPI::Token::Structure');
    return if !$nodes_ref;
    my @semis     = grep { $_ eq $SCOLON } @{$nodes_ref};
    return scalar @semis == 2;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ControlStructures::ProhibitCStyleForLoops - Write C<for(0..20)> instead of C<for($i=0; $i<=20; $i++)>.

=head1 DESCRIPTION

The 3-part C<for> loop that Perl inherits from C is butt-ugly, and only
really necessary if you need irregular counting.  The very Perlish
C<..> operator is much more elegant and readable.

  for($i=0; $i<=$max; $i++){      #ick!
      do_something($i);
  }

  for(0..$max){                   #very nice
    do_something($_);
  }

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2008 Jeffrey Ryan Thalhammer.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
