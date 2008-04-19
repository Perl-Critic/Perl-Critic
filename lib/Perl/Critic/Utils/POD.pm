##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::POD;

use strict;
use warnings;

use English qw< -no_match_vars >;

use IO::String ();
use Pod::Select ();

use Perl::Critic::Exception::IO qw< throw_io >;
use Perl::Critic::Utils qw< :characters >;

use base 'Exporter';

our $VERSION = '1.083_001';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    get_pod_section_from_file
    get_pod_section_from_filehandle
    trim_pod_section
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

#-----------------------------------------------------------------------------

sub get_pod_section_from_file {
    my ($file_name, $section_name) = @_;

    open my $file_handle, '<', $file_name
        or throw_io
            message     => qq<Could not open "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    my $content = get_pod_section_from_filehandle( $file_handle, $section_name );

    close $file_handle
        or throw_io
            message     => qq<Could not close "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    return $content;
}

#-----------------------------------------------------------------------------

sub get_pod_section_from_filehandle {
    my ($file_handle, $section_name) = @_;

    my $parser = Pod::Select->new();
    $parser->select($section_name);

    my $content = $EMPTY;
    my $content_handle = IO::String->new( \$content );

    $parser->parse_from_filehandle( $file_handle, $content_handle );

    return if $content eq $EMPTY;
    return $content;
}

#-----------------------------------------------------------------------------

sub trim_pod_section {
    my ($pod) = @_;

    $pod =~ s< \A =head1 \b [^\n]* \n $ ><>xms;
    $pod =~ s< \A \s+ ><>xms;
    $pod =~ s< \s+ \z ><>xms;

    return $pod;
}

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::POD - Utility functions for dealing with POD.


=head1 SYNOPSIS

    use Perl::Critic::Utils::POD qw< get_pod_section_from_file >;

    my $synopsis =
        get_pod_section_from_file('Perl/Critic/Utils/POD.pm', 'SYNOPSIS');

    my $see_also =
        get_pod_section_from_filehandle($file_handle, 'SEE ALSO');


=head1 DESCRIPTION

Provides means of accessing chunks of POD.


=head1 IMPORTABLE SUBS

=over

=item C<get_pod_section_from_file( $file_name, $section_name )>

Retrieves the specified section of POD (i.e. something marked by
C<=head1>) from the file.  This is uninterpreted; escapes are not
processed and any sub-sections will be present.  E.g. if the content
contains "CZ<><>", the return value will contain "CZ<><>".

Returns nothing if no such section is found.

Throws a L<Perl::Critic::Exception::IO> if there's a problem with the
file.


=item C<get_pod_section_from_filehandle( $file_handle, $section_name )>

Retrieves the specified section of POD (i.e. something marked by
C<=head1>) from the file handle.  This is uninterpreted; escapes are
not processed and any sub-sections will be present.  E.g. if the
content contains "CZ<><>", the return value will contain "CZ<><>".

Returns nothing if no such section is found.


=item C<trim_pod_section( $pod_section )>



=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2008 Elliot Shank.  All rights reserved.

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
