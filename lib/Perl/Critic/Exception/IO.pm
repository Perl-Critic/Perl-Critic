package Perl::Critic::Exception::IO;

use 5.006001;
use strict;
use warnings;

use Carp qw{ confess };
use English qw(-no_match_vars);
use Readonly;

use Perl::Critic::Utils qw{ :characters };

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::IO' => {
        isa         => 'Perl::Critic::Exception',
        description => 'An input/output problem.',
        fields      => [ qw< file_name errno > ],
        alias       => 'throw_io',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_io >;

#-----------------------------------------------------------------------------

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::IO - A problem with input or output.

=head1 DESCRIPTION

The outside world can do nasty things to your poor, innocent code.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<file_name()>

Returns the name of the file that the problem was found with, if available.


=item C<errno()>

The value of C<$ERRNO>/C<$!> at the time the problem was found.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007-2011 Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut

##############################################################################
# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
