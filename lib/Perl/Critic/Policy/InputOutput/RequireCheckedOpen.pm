##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::InputOutput::RequireCheckedOpen;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

my $desc = q{Return value of "open" ignored};
my $expl = q{Check the return value of "open" for success};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity  { return $SEVERITY_MEDIUM       }
sub default_themes    { return qw( core maintenance ) }
sub applies_to        { return 'PPI::Token::Word'     }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'open';
    return if ! is_unchecked_call( $elem );

    return $self->violation( $desc, $expl, $elem );

}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireCheckedOpen

=head1 DESCRIPTION

The perl builtin I/O function C<open> returns a false value on failure. That
value should always be checked to ensure that the open was successful.


  my $error = open( $filehanle, $mode, $filname );                  # ok
  open( $filehanle, $mode, $filname ) or die "unable to open: $!";  # ok
  open( $filehanle, $mode, $filname );                              # not ok

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

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
