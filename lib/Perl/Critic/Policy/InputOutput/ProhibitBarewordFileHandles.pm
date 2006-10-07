#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#--------------------------------------------------------------------------

my $desc = q{Bareword file handle opened};
my $expl = [ 202, 204 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes    { return qw( pbp danger )   }
sub applies_to       { return 'PPI::Token::Word' }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'open';
    return if ! is_function_call($elem);

    my $first_arg = ( parse_arg_list($elem) )[0];
    return if !$first_arg;
    my $first_token = $first_arg->[0];
    return if !$first_token;

    if( $first_token->isa('PPI::Token::Word') && $first_token ne 'my' ) {
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

__END__

#--------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles

=head1 DESCRIPTION

Using bareword symbols to refer to file handles is particularly evil
because they are global, and you have no idea if that symbol already
points to some other file handle.  You can mitigate some of that risk
by C<local>izing the symbol first, but that's pretty ugly.  Since Perl
5.6, you can use an undefined scalar variable as a lexical reference
to an anonymous filehandle.  Alternatively, see the L<IO::Handle> or
L<IO::File> or L<FileHandle> modules for an object-oriented approach.

  open FH, '<', $some_file;           #not ok
  open my $fh, '<', $some_file;       #ok
  my $fh = IO::File->new($some_file); #ok

=head1 SEE ALSO

L<IO::Handle>

L<IO::File>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
