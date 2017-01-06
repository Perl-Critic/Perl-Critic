package Perl::Critic::Policy::InputOutput::RequireEncodingWithUTF8Layer;

use 5.006001;
use strict;
use warnings;

use Readonly;

use version;

use Perl::Critic::Utils qw{ :severities :ppi };
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{I/O layer ":utf8" used};
Readonly::Scalar my $EXPL => q{Use ":encoding(UTF-8)" to get strict validation};

Readonly::Scalar my $THREE_ARGUMENT_OPEN => 3;
Readonly::Hash   my %RECOVER_ENCODING => (
    binmode => \&_recover_binmode_encoding,
    open => \&_recover_open_encoding,
);

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                         }
sub default_severity     { return $SEVERITY_HIGHEST          }
sub default_themes       { return qw(core bugs security) }
sub applies_to           { return 'PPI::Token::Word'         }

#-----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, $document) = @_;

    my $handler = $RECOVER_ENCODING{ $elem->content() }
        or return;  # If we don't have a handler, we're not interested.
    my $encoding = $handler->( parse_arg_list( $elem ) )
        or return;  # If we can't recover an encoding, we give up.
    return if $encoding !~ m/ (?: \A | : ) utf8 \b /smxi;   # OK

    return $self->violation( $DESC, $EXPL, $elem );
}

#-----------------------------------------------------------------------------

# my $string = _get_argument_string( $arg[1] );
#
# This subroutine returns the string from the given argument (which must
# be a reference to an array of PPI objects), _PROVIDED_ the array
# contains a single PPI::Token::Quote object. Otherwise it simply
# returns, since we're too stupid to analyze anything else.

sub _get_argument_string {
    my ( $arg ) = @_;
    ref $arg eq 'ARRAY' or return;
    return if @{ $arg } == 0 || @{ $arg } > 1;
    return $arg->[0]->string() if $arg->[0]->isa( 'PPI::Token::Quote' );
    return;
}

#-----------------------------------------------------------------------------

# my $encoding = _recover_binmode_encoding( _parse_arg_list( $elem ) );
#
# This subroutine returns the encoding specified by the given $elem,
# which _MUST_ be the 'binmode' of a binmode() call.

sub _recover_binmode_encoding {
    my ( @args ) = @_;
    return _get_argument_string( $args[1] );
}

#-----------------------------------------------------------------------------

# my $encoding = _recover_open_encoding( _parse_arg_list( $elem ) );
#
# This subroutine returns the encoding specified by the given $elem,
# which _MUST_ be the 'open' of a open() call.

sub _recover_open_encoding {
    my ( @args ) = @_;
    @args < $THREE_ARGUMENT_OPEN
        and return;
    defined( my $string = _get_argument_string( $args[1] ) )
        or return;
    $string =~ s/ [+]? (?: < | >{1,2} ) //smx;
    return $string;
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords PerlIO PerlMonks Wiki

=head1 NAME

Perl::Critic::Policy::InputOutput::RequireEncodingWithUTF8Layer - Write C<< open $fh, q{<:encoding(UTF-8)}, $filename; >> instead of C<< open $fh, q{<:utf8}, $filename; >>.

=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Use of the C<:utf8> I/O layer (as opposed to C<:encoding(UTF8)> or
C<:encoding(UTF-8)>) was suggested in the Perl documentation up to
version 5.8.8. This may be OK for output, but on input C<:utf8> does not
validate the input, leading to unexpected results.

An exploit based on this behavior of C<:utf8> is exhibited on PerlMonks
at L<http://www.perlmonks.org/?node_id=644786>. The exploit involves a
string read from an external file and sanitized with C<m/^(\w+)$/>,
where C<$1> nonetheless ends up containing shell meta-characters.

To summarize:

 open $fh, '<:utf8', 'foo.txt';             # BAD
 open $fh, '<:encoding(UTF8)', 'foo.txt';   # GOOD
 open $fh, '<:encoding(UTF-8)', 'foo.txt';  # BETTER

See the L<Encode|Encode> documentation for the difference between
C<UTF8> and C<UTF-8>. The short version is that C<UTF-8> implements the
Unicode standard, and C<UTF8> is liberalized.

For consistency's sake, this policy checks files opened for output as
well as input. For complete coverage it also checks C<binmode()> calls,
where the direction of operation can not be determined.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 NOTES

Because C<Perl::Critic> does a static analysis, this policy can not
detect cases like

 my $encoding = ':utf8';
 binmode $fh, $encoding;

where the encoding is computed.


=head1 SEE ALSO

L<PerlIO|PerlIO>

L<Encode|Encode>

C<perldoc -f binmode>

L<http://www.socialtext.net/perl5/index.cgi?the_utf8_perlio_layer>

L<http://www.perlmonks.org/?node_id=644786>

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT

Copyright (c) 2010-2011 Thomas R. Wyant, III

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
