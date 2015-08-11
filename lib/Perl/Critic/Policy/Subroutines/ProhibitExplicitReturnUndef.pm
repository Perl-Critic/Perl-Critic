package Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{"return" statement with explicit "undef"};
Readonly::Scalar my $EXPL => [ 199 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                 }
sub default_severity     { return $SEVERITY_HIGHEST  }
sub default_themes       { return qw(core pbp bugs certrec )  }
sub applies_to           { return 'PPI::Token::Word' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if $elem->content() ne 'return';
    return if is_hash_key($elem);

    my $sib = $elem->snext_sibling();
    return if !$sib;
    return if !$sib->isa('PPI::Token::Word');
    return if $sib->content() ne 'undef';

    # Must be 'return undef'
    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitExplicitReturnUndef - Return failure with bare C<return> instead of C<return undef>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


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


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

You can fool this policy pretty easily by hiding C<undef> in a boolean
expression.  But don't bother trying.  In fact, using return values to
indicate failure is pretty poor technique anyway.  Consider using
C<die> or C<croak> with C<eval>, or the L<Error|Error> module for a
much more robust exception-handling model.  Conway has a real nice
discussion on error handling in chapter 13 of PBP.


=head1 SEE ALSO

There's a discussion of the appropriateness of this policy at
L<http://perlmonks.org/index.pl?node_id=741847>.


=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
