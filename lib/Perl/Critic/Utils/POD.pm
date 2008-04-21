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

# TODO: non-fatal generic?
use Perl::Critic::Exception::Fatal::Generic qw< throw_generic >;
use Perl::Critic::Exception::IO qw< throw_io >;
use Perl::Critic::Utils qw< :characters >;

use base 'Exporter';

our $VERSION = '1.083_001';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw(
    get_pod_section_from_file
    get_pod_section_from_filehandle
    trim_pod_section
    get_module_abstract_from_file
    get_module_abstract_from_filehandle
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
} // end get_pod_section_from_filehandle()

#-----------------------------------------------------------------------------

sub trim_pod_section {
    my ($pod) = @_;

    $pod =~ s< \A =head1 \b [^\n]* \n $ ><>xms;
    $pod =~ s< \A \s+ ><>xms;
    $pod =~ s< \s+ \z ><>xms;

    return $pod;
}

#-----------------------------------------------------------------------------

sub get_module_abstract_from_file {
    my ($file_name) = @_;

    open my $file_handle, '<', $file_name
        or throw_io
            message     => qq<Could not open "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    my $module_abstract = get_module_abstract_from_filehandle( $file_handle );

    close $file_handle
        or throw_io
            message     => qq<Could not close "$file_name": $ERRNO>,
            file_name   => $file_name,
            errno       => $ERRNO;

    return $module_abstract;
}

#-----------------------------------------------------------------------------

sub get_module_abstract_from_filehandle { ## no critic (RequireFinalReturn)
    my ($file_handle) = @_;

    my $name_section = get_pod_section_from_filehandle( $file_handle, 'NAME');
    return if not $name_section;

    $name_section = trim_pod_section($name_section);
    return if not $name_section;

    if ( $name_section =~ m< \n >xms ) {
        throw_generic
            qq<Malformed NAME section in "$name_section". >
            . q<It must be on a single line>;
    }

    if (
        $name_section =~ m<
            \A
            \s*
            [\w:]+              # Module name.
            \s+
            -                   # The required single hyphen.
            \s+
            (
                \S              # At least one non-whitespace.
                (?: .* \S)?     # Everything up to the last non-whitespace.
            )
            \s*
            \z
        >xms
    ) {
        my $module_abstract = $1;
        return $module_abstract;
    }

    if (
        $name_section =~ m<
            \A
            \s*
            [\w:]+              # Module name.
            (?: \s* - )?        # The single hyphen is now optional.
            \s*
            \z
        >xms
    ) {
        return;
    }

    throw_generic qq<Malformed NAME section in "$name_section".>;
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


    my $see_also_content = trim_pod_section($see_also);


    # "Utility functions for dealing with POD."
    my $module_abstract =
        get_module_abstract_from_file('Perl/Critic/Utils/POD.pm');

    my $module_abstract =
        get_module_abstract_from_filehandle($file_handle);


=head1 DESCRIPTION

Provides means of accessing chunks of POD.


=head1 IMPORTABLE SUBROUTINES

=over

=item C<get_pod_section_from_file( $file_name, $section_name )>

Retrieves the specified section of POD (i.e. something marked by
C<=head1>) from the file.  This is uninterpreted; escapes are not
processed and any sub-sections will be present.  E.g. if the content
contains "CZ<><$x>", the return value will contain "CZ<><$x>".

Returns nothing if no such section is found.

Throws a L<Perl::Critic::Exception::IO> if there's a problem with the
file.


=item C<get_pod_section_from_filehandle( $file_handle, $section_name )>

Does the same as C<get_pod_section_from_file()>, but with a file
handle.


=item C<trim_pod_section( $pod_section )>

Returns a copy of the parameter, with any starting C<=item1 BLAH>
removed and all leading and trailing whitespace (including newlines)
removed after that.

For example, using one of the C<get_pod_section_from_*> functions to
get the "NAME" section of this module and then calling
C<trim_pod_section()> on the result would give you
"Perl::Critic::Utils::POD - Utility functions for dealing with POD.".


=item C<get_module_abstract_from_file( $file_name )>

Attempts to parse the "NAME" section of the specified file and get the
abstract of the module from that.  If it succeeds, it returns the
abstract.  If it fails, either because there is no "NAME" section or
there is no abstract after the module name, returns nothing.  If it
looks like there's a malformed abstract, throws a
L<Perl::Critic::Exception::Fatal::Generic>.

Example "well formed" "NAME" sections without abstracts:

    Some::Module

    Some::Other::Module -

Example "NAME" sections that will result in an exception:

    Some::Bad::Module This has no hyphen.

    Some::Mean::Module -- This has double hyphens.

    Some::Nasty::Module - This one attempts to
    span multiple lines.


=item C<get_module_abstract_from_filehandle( $file_handle )>

Does the same as C<get_module_abstract_from_file()>, but with a file
handle.


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
