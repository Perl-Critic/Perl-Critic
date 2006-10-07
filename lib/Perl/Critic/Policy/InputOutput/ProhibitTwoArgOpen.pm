#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#--------------------------------------------------------------------------

my $STDIO_HANDLES_RX = qr/\b STD (?: IN | OUT | ERR \b)/mx;
my $desc = q{Two-argument "open" used};
my $expl = [ 207 ];

#--------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST       }
sub default_themes    { return qw(pbp danger security) }
sub applies_to       { return 'PPI::Token::Word'      }

#--------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'open';
    return if ! is_function_call($elem);
    my @args = parse_arg_list($elem);

    if ( scalar @args == 2 ) {
        # When opening STDIN, STDOUT, or STDERR, the
        # two-arg form is the only option you have.
        return if $args[1]->[0] =~ $STDIO_HANDLES_RX;
        return $self->violation( $desc, $expl, $elem );
    }
    return; #ok!
}

1;

__END__

#--------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen

=head1 DESCRIPTION

The three-argument form of C<open> (introduced in Perl 5.6) prevents
subtle bugs that occur when the filename starts with funny characters
like '>' or '<'.  The L<IO::File> module provides a nice
object-oriented interface to filehandles, which I think is more
elegant anyway.

  open( $fh, '>output.txt' );          # not ok
  open( $fh, q{>}, 'output.txt );      # ok

  use IO::File;
  my $fh = IO::File->new( 'output.txt', q{>} ); # even better!

=head1 NOTES

The only time you should use the two-argument form is when you re-open
STDIN, STDOUT, or STDERR.  But for now, this Policy doesn't provide
that loophole.

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
