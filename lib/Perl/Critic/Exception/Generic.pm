##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::Generic;

use strict;
use warnings;

our $VERSION = 1.06;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Generic' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A general problem was found.',
        alias       => 'throw_generic',
    },
);

#-----------------------------------------------------------------------------

our @EXPORT_OK = qw{ &throw_generic };

#-----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->show_trace(1);

    return $self;
}


1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Exception::Generic - A problem for which there is no specialized information

=head1 DESCRIPTION

A general problem, e.g. I/O errors and problems that may or not be bugs.

Note: the constructor invokes L<Exception::Class/"show_trace"> to
force stack-traces to be included in the standard stringification.


=head1 METHODS

Only inherited ones.


=head1 AUTHOR

Elliot Shank <perl@galumph.com>

=head1 COPYRIGHT

Copyright (c) 2007 Elliot Shank.  All rights reserved.

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
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
