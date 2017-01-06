package Perl::Critic::Exception::Parse;

use 5.006001;
use strict;
use warnings;

use English qw< -no_match_vars >;
use Carp qw< confess >;
use Readonly;

use Perl::Critic::Utils qw< :characters >;

our $VERSION = '1.126';

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Parse' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A problem parsing source code.',
        fields      => [ qw< file_name > ],
        alias       => 'throw_parse',
    },
);

#-----------------------------------------------------------------------------

Readonly::Array our @EXPORT_OK => qw< throw_parse >;

#-----------------------------------------------------------------------------

1;

#-----------------------------------------------------------------------------

__END__

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Parse - The code doesn't look like code.

=head1 DESCRIPTION

There was a problem with PPI parsing source code.


=head1 INTERFACE SUPPORT

This is considered to be a public class.  Any changes to its interface
will go through a deprecation cycle.


=head1 METHODS

=over

=item C<file_name()>

Returns the name of the file that the problem was found with, if available.


=back


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2008-2011 Elliot Shank.

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
