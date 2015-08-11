package Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen;

use 5.006001;
use strict;
use warnings;

use Readonly;

use version;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $STDIO_HANDLES_RX => qr/\b STD (?: IN | OUT | ERR \b)/xms;
Readonly::Scalar my $FORK_HANDLES_RX => qr/\A (?: -[|] | [|]- ) \z/xms;
Readonly::Scalar my $DESC => q{Two-argument "open" used};
Readonly::Scalar my $EXPL => [ 207 ];

Readonly::Scalar my $MINIMUM_VERSION => version->new(5.006);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core pbp bugs security certrule) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $document) = @_;

    return if $elem->content() ne 'open';
    return if ! is_function_call($elem);

    my $version = $document->highest_explicit_perl_version();
    return if $version and $version < $MINIMUM_VERSION;

    my @args = parse_arg_list($elem);

    if ( scalar @args == 2 ) {
        # When opening STDIN, STDOUT, or STDERR, the
        # two-arg form is the only option you have.
        return if $args[1]->[0] =~ $STDIO_HANDLES_RX;
        return if $args[1]->[0]->isa( 'PPI::Token::Quote' )
               && $args[1]->[0]->string() =~ $FORK_HANDLES_RX;
        return $self->violation( $DESC, $EXPL, $elem );
    }

    return; # ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords perlipc

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitTwoArgOpen - Write C<< open $fh, q{<}, $filename; >> instead of C<< open $fh, "<$filename"; >>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

The three-argument form of C<open> (introduced in Perl 5.6) prevents
subtle bugs that occur when the filename starts with funny characters
like '>' or '<'.  The L<IO::File|IO::File> module provides a nice
object-oriented interface to filehandles, which I think is more
elegant anyway.

  open( $fh, '>output.txt' );          # not ok
  open( $fh, q{>}, 'output.txt' );     # ok

  use IO::File;
  my $fh = IO::File->new( 'output.txt', q{>} ); # even better!

It's also more explicitly clear to define the input mode of the file,
as in the difference between these two:

  open( $fh, 'foo.txt' );       # BAD: Reader must think what default mode is
  open( $fh, '<', 'foo.txt' );  # GOOD: Reader can see open mode

This policy will not complain if the file explicitly states that it is
compatible with a version of perl prior to 5.6 via an include
statement, e.g. by having C<require 5.005> in it.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

There are two cases in which you are forced to use the two-argument form of
open. When re-opening STDIN, STDOUT, or STDERR, and when doing a safe pipe
open, as described in L<perlipc|perlipc>.

=head1 SEE ALSO

L<IO::Handle|IO::Handle>

L<IO::File|IO::File>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2011 Imaginative Software Systems.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
