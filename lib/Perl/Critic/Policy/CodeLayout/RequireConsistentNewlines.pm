package Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use PPI::Token::Whitespace;
use English qw(-no_match_vars);
use base 'Perl::Critic::Policy';

our $VERSION = '1.126';

Readonly::Scalar my $LINE_END => qr/\015{1,2}\012|[\012\015]/mxs;

#-----------------------------------------------------------------------------

Readonly::Scalar my $DESC => q{Use the same newline through the source};
Readonly::Scalar my $EXPL => q{Change your newlines to be the same throughout};

#-----------------------------------------------------------------------------

sub supported_parameters { return ()              }
sub default_severity     { return $SEVERITY_HIGH  }
sub default_themes       { return qw( core bugs ) }
sub applies_to           { return 'PPI::Document' }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, undef, $doc ) = @_;

    my $filename = $doc->filename();
    return if !$filename;

    my $fh;
    return if !open $fh, '<', $filename;
    local $RS = undef;
    my $source = <$fh>;
    close $fh or return;

    my $newline; # undef until we find the first one
    my $line = 1;
    my @v;
    while ( $source =~ m/\G([^\012\015]*)($LINE_END)/cgmxs ) {
        my $code = $1;
        my $nl = $2;
        my $col = length $code;
        $newline ||= $nl;
        if ( $nl ne $newline ) {
            my $token = PPI::Token::Whitespace->new( $nl );
            # TODO this is a terrible violation of encapsulation, but absent a
            # mechanism to override the line numbers in the violation, I do
            # not know what to do about it.
            $token->{_location} = [$line, $col, $col, $line, $filename];
            push @v, $self->violation( $DESC, $EXPL, $token );
        }
        $line++;
    }
    return @v;
}

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords GnuPG

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireConsistentNewlines - Use the same newline through the source.


=head1 AFFILIATION

This Policy is part of the core L<Perl::Critic|Perl::Critic>
distribution.


=head1 DESCRIPTION

Source code files are divided into lines with line endings of C<\r>,
C<\n> or C<\r\n>.  Mixing these different line endings causes problems
in many text editors and, notably, Module::Signature and GnuPG.


=head1 CAVEAT

This policy works outside of PPI because PPI automatically normalizes
source code to local newline conventions.  So, this will only work if
we know the filename of the source code.


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2011 Chris Dolan.

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
