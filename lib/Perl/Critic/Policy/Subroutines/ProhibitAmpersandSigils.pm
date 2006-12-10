##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.22;

#-----------------------------------------------------------------------------

my $desc  = q{Subroutine called with "&" sigil};
my $expl  = [ 175 ];

#-----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW        }
sub default_themes   { return qw(core pbp maintenance)  }
sub applies_to       { return 'PPI::Token::Symbol' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    my $psib = $elem->sprevious_sibling();
    if ( $psib ) {
        #Sigil is allowed if taking a reference, e.g. "\&my_sub"
        return if $psib->isa('PPI::Token::Cast') && $psib eq q{\\};
    }

    return if ( $elem !~ m{\A [&] }mx ); # ok

    $psib = $elem->sprevious_sibling();
    return if ( $psib eq 'goto'
                or $psib eq 'exists'
                or $psib eq 'defined' ); # ok

    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils

=head1 DESCRIPTION

Since Perl 5, the ampersand sigil is completely optional when invoking
subroutines.  And it's easily confused with the bitwise 'and' operator.

  @result = &some_function(); #Not ok
  @result = some_function();  #ok

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
