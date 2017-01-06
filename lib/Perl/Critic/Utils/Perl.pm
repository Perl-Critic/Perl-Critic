package Perl::Critic::Utils::Perl;

use 5.006001;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    symbol_without_sigil
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub symbol_without_sigil {
    my ($symbol) = @_;

    (my $without_sigil = $symbol) =~ s< \A [\$@%*&] ><>xms;

    return $without_sigil;
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::Perl - Utility functions for dealing with Perl language issues.


=head1 SYNOPSIS

    use Perl::Critic::Utils::Perl qw< :all >;

    my $name = symbol_without_sigil('$foo');    # $name is "foo".


=head1 DESCRIPTION

This handles various issues with Perl, the language, that aren't necessarily
L<PPI|PPI> related.


=head1 INTERFACE SUPPORT

This is considered to be a public module.  Any changes to its
interface will go through a deprecation cycle.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<symbol_without_sigil( $symbol )>

Returns the name of the specified symbol with any sigil at the front.
The parameter can be a vanilla Perl string or a L<PPI::Element|PPI::Element>.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

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
