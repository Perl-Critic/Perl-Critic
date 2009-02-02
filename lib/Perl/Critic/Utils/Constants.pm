##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Utils::Constants;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ hashify };

use base 'Exporter';

our $VERSION = '1.096';

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{
    $PROFILE_STRICTNESS_WARN
    $PROFILE_STRICTNESS_FATAL
    $PROFILE_STRICTNESS_QUIET
    $PROFILE_STRICTNESS_DEFAULT
    %PROFILE_STRICTNESSES
};

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    profile_strictness => [
        qw{
            $PROFILE_STRICTNESS_WARN
            $PROFILE_STRICTNESS_FATAL
            $PROFILE_STRICTNESS_QUIET
            $PROFILE_STRICTNESS_DEFAULT
            %PROFILE_STRICTNESSES
        }
    ],
);

#-----------------------------------------------------------------------------

Readonly::Scalar our $PROFILE_STRICTNESS_WARN    => 'warn';
Readonly::Scalar our $PROFILE_STRICTNESS_FATAL   => 'fatal';
Readonly::Scalar our $PROFILE_STRICTNESS_QUIET   => 'quiet';
Readonly::Scalar our $PROFILE_STRICTNESS_DEFAULT => $PROFILE_STRICTNESS_WARN;

Readonly::Hash our %PROFILE_STRICTNESSES =>
    hashify(
        $PROFILE_STRICTNESS_WARN,
        $PROFILE_STRICTNESS_FATAL,
        $PROFILE_STRICTNESS_QUIET,
    );

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Utils::Constants - Global constants.


=head1 DESCRIPTION

Defines commonly used constants for L<Perl::Critic|Perl::Critic>.


=head1 IMPORTABLE CONSTANTS

=over

=item C<$PROFILE_STRICTNESS_WARN>

=item C<$PROFILE_STRICTNESS_FATAL>

=item C<$PROFILE_STRICTNESS_QUIET>

=item C<$PROFILE_STRICTNESS_DEFAULT>

=item C<%PROFILE_STRICTNESSES>

Valid values for the L<perlcritic/"-profile-strictness"> option.
Determines whether recoverable problems found in a profile file appear
as warnings, are fatal, or are ignored.
C<$PROFILE_STRICTNESS_DEFAULT> is set to C<$PROFILE_STRICTNESS_WARN>.
Importable via the C<:profile_strictness> tag.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>


=head1 COPYRIGHT

Copyright (c) 2007-2009 Elliot Shank.  All rights reserved.

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
