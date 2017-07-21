package Perl::Critic::Policy::InputOutput::ProhibitBarewordDirHandles;

use 5.010001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :ppi };
use parent 'Perl::Critic::Policy';

our $VERSION = '1.150';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Bareword dir handle opened};
Readonly::Scalar my $EXPL => [ 202, 204 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                  }
sub default_severity     { return $SEVERITY_HIGHEST   }
sub default_themes       { return qw( core pbp bugs certrec ) }
sub applies_to           { return 'PPI::Token::Word'  }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem->content() ne 'opendir';
    return if ! is_function_call($elem);

    my $first_arg = ( parse_arg_list($elem) )[0];
    return if !$first_arg;
    my $token = $first_arg->[0];
    return if !$token;

    if ( $token->isa('PPI::Token::Word') && $token eq 'local' ) {  # handle local *DH
        $token = $first_arg->[1]; # the token that follows local in the first argument
        return if !$token;
    }
    if ( $token->isa('PPI::Token::Cast') && $token eq q{\\} ) {    # handle \*DH
        $token = $first_arg->[1]; # the token that follows \ in the first argument
        return if !$token;
    }

    if ( $token->isa('PPI::Token::Symbol') ) {
        return $self->violation($DESC, $EXPL, $elem) if $token =~ m/^[*]/xms;
    } elsif ( $token->isa('PPI::Token::Word') ) {
        return $self->violation($DESC, $EXPL, $elem) if $token !~ m/^(?:my|our)$/xms;
    }

    return; #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Perl7

=head1 NAME

Perl::Critic::Policy::InputOutput::ProhibitBarewordDirHandles - Write C<opendir my $dh, $dirname;> instead of C<opendir DH, $dirname;>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Using bareword symbols to refer to directory handles is particularly evil
because they are global, and you have no idea if that symbol already
points to some other file or directory handle.  You can mitigate some of that risk
by C<local>izing the symbol first, but that's pretty ugly.  Since Perl
5.6, you can use an undefined scalar variable as a lexical reference
to an anonymous file handle or directory handle.  Alternatively, see the
L<IO::Handle|IO::Handle> or L<IO::Dir|IO::Dir>
modules for an object-oriented approach.

    opendir DH, $some_dir;            #not ok
    opendir *DH, $some_dir;           #not ok
    opendir \*DH, $some_dir;          #not ok
    opendir local *DH, $some_dir;     #not ok
    opendir $dh, $some_dir;           #ok
    opendir my $dh, $some_dir;        #ok
    opendir our $dh, $some_dir;       #ok
    opendir local $dh, $some_dir;     #ok
    my $dh = IO::Dir->new($some_dir); #ok

And Perl7 will probably drop support for bareword filehandles.

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 SEE ALSO

L<Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles::Perl::Critic::Policy::InputOutput::ProhibitBarewordFileHandles>

L<IO::Handle|IO::Handle>

L<IO::Dir|IO::Dir>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>,
C<github.com/pali>, C<github.com/raforg>

=head1 COPYRIGHT

Copyright (c) 2005-2011, 2021 Imaginative Software Systems.  All rights reserved.

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
