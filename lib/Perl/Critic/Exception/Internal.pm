##############################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
##############################################################################

package Perl::Critic::Exception::Internal;

use strict;
use warnings;

our $VERSION = 1.06;

#-----------------------------------------------------------------------------

use Exception::Class (
    'Perl::Critic::Exception::Internal' => {
        isa         => 'Perl::Critic::Exception',
        description => 'A problem with the Perl::Critic code was found, a.k.a. a bug.',
        alias       => 'throw_internal',
    },
);

#-----------------------------------------------------------------------------

use Exporter qw{ import };

our @EXPORT_OK = qw{ &throw_internal };

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

Perl::Critic::Exception::Internal - A problem with the L<Perl::Critic> implementation, i.e. a bug

=head1 DESCRIPTION

A representation of a bug found in the code of L<Perl::Critic>.

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
