package Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi hashify };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.148';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Bareword file handle opened};
Readonly::Scalar my $EXPL => [ 202, 204 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs certrec ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

Readonly::Scalar my $ARRAY_REF  => ref [];
Readonly::Hash my %OPEN_FUNCS => hashify( qw( open sysopen ) );

sub violates {
    my ($self, $elem, undef) = @_;

    return if ! $OPEN_FUNCS{$elem->content()};
    return if ! is_function_call($elem);

    my $first_arg = ( parse_arg_list($elem) )[0];
    return if !$first_arg;
    my $first_token;
    # PPI can mis-parse something like open( CHECK, ... ) as a scheduled
    # block. So ...
    if ( 'PPI::Statement::Scheduled' eq ref $first_arg ) {
        # If PPI PR #247 is accepted, the following should be unnecessary.
        # We get here because when parse_arg_list() gets confused it
        # just returns the statement object.
        $first_token = $first_arg->schild( 0 );
    } elsif ( $ARRAY_REF eq ref $first_arg ) {
        # This is the normal path through the code.
        $first_token = $first_arg->[0];
    } else {
        # This is purely defensive.
        return;
    }
    return if !$first_token;

    if ( $first_token->isa('PPI::Token::Word') ) {
        if ( ($first_token ne 'my') && ($first_token !~ m/^STD(?:IN|OUT|ERR)$/xms ) ) {
            return $self->violation( $DESC, $EXPL, $elem );
        }
    }
    return; #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles - Write C<open my $fh, q{<}, $filename;> instead of C<open FH, q{<}, $filename;>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using bareword symbols to refer to file handles is particularly evil
because they are global, and you have no idea if that symbol already
points to some other file handle.  You can mitigate some of that risk
by C<local>izing the symbol first, but that's pretty ugly.  Since Perl
5.6, you can use an undefined scalar variable as a lexical reference
to an anonymous filehandle.  Alternatively, see the
L<IO::Handle|IO::Handle> or L<IO::File|IO::File> or
L<FileHandle|FileHandle> modules for an object-oriented approach.

    open FH, '<', $some_file;           #not ok
    open my $fh, '<', $some_file;       #ok
    my $fh = IO::File->new($some_file); #ok

There are three exceptions: STDIN, STDOUT and STDERR.  These three
standard filehandles are always package variables.

This policy also applies to the C<sysopen> function as well.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<IO::Handle|IO::Handle>

L<IO::File|IO::File>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT

Copyright (c) 2005-2022 Imaginative Software Systems.  All rights reserved.

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
