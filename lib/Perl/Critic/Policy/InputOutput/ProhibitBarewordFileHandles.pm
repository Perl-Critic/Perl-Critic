##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles;

use strict;
use warnings;
use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = 1.03;

#-----------------------------------------------------------------------------

my $desc = q{Bareword file handle opened};
my $expl = [ 202, 204 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                   }
sub default_severity  { return $SEVERITY_HIGHEST    }
sub default_themes    { return qw( core pbp bugs )  }
sub applies_to        { return 'PPI::Token::Word'   }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'open';
    return if ! is_function_call($elem);

    my $first_arg = ( parse_arg_list($elem) )[0];
    return if !$first_arg;
    my $first_token = $first_arg->[0];
    return if !$first_token;

    if ( $first_token->isa('PPI::Token::Word') ) {
        if ( ($first_token ne 'my') && ($first_token !~ m/^STD(IN|OUT|ERR)$/mx ) ) {
            return $self->violation( $desc, $expl, $elem );
        }
    }
    return; #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

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

There are three exceptions: STDIN, STDOUT and STDERR.  These three
standard filehandles are always package variables.

=head1 SEE ALSO

L<IO::Handle>

L<IO::File>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2005-2007 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
