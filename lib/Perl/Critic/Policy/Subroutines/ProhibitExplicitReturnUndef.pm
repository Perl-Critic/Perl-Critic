#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#---------------------------------------------------------------------------

my $desc = q{"return" statement with explicit "undef"};
my $expl = [ 199 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes    { return qw(pbp danger)     }
sub applies_to       { return 'PPI::Token::Word' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if ($elem ne 'return');
    return if is_hash_key($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;
    return if !$sib->isa('PPI::Token::Word');
    return if $sib ne 'undef';

    # Must be 'return undef'
    return $self->violation( $desc, $expl, $elem );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef

=head1 DESCRIPTION

Returning C<undef> upon failure from a subroutine is pretty common.
But if the subroutine is called in list context, an explicit C<return
undef;> statement will return a one-element list containing
C<(undef)>.  Now if that list is subsequently put in a boolean context
to test for failure, then it evaluates to true.  But you probably
wanted it to be false.

  sub read_file {
      my $file = shift;
      -f $file || return undef;  #file doesn't exist!

      #Continue reading file...
  }

  #and later...

  if ( my @data = read_file($filename) ){

      # if $filename doesn't exist,
      # @data will be (undef),
      # but I'll still be in here!

      process(@data);
  }
  else{

      # This is my error handling code.
      # I probably want to be in here
      # if $filname doesn't exist.

      die "$filename not found";
  }

The solution is to just use a bare C<return> statement whenever you
want to return failure.  In list context, Perl will then give you an
empty list (which is false), and C<undef> in scalar context (which is
also false).

  sub read_file {
      my $file = shift;
      -f $file || return;  #DWIM!

      #Continue reading file...
  }

=head1 NOTES

You can fool this policy pretty easily by hiding C<undef> in a boolean
expression.  But don't bother trying.  In fact, using return values to
indicate failure is pretty poor technique anyway.  Consider using
C<die> or C<croak> with C<eval>, or the L<Error> module for a much
more robust exception-handling model.  Conway has a real nice
discussion on error handling in chapter 13 of PBP.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
