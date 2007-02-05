##############################################################################
#      $URL: $
#     $Date: $
#   $Author: $
# $Revision: $
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireCheckedClose;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 1.01;

#-----------------------------------------------------------------------------

my $desc = q{Return value of "close" ignored};
my $expl = q{Check the return value of "close" for success};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity  { return $SEVERITY_LOW          }
sub default_themes    { return qw( core maintenance ) }
sub applies_to        { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'close';
    return if ! is_unchecked_call( $elem );

    return $self->violation( $desc, $expl, $elem );

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireCheckedClose

=head1 DESCRIPTION

The perl builtin I/O function C<close> returns a false value on failure. That
value should be checked to ensure that the close was successful.


  my $error = close $filehanle;                   # ok
  close $filehanle or die "unable to close: $!";  # ok
  close $filehanle;                               # not ok

=head1 AUTHOR

Andrew Moore <amoore@mooresystems.com>

=head1 ACKNOWLEDGMENTS

This policy module is based heavily on policies written by Jeffrey Ryan
Thalhammer <thaljef@cpan.org>.

=head1 COPYRIGHT

Copyright (c) 2007 Andrew Moore.  All rights reserved.

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
