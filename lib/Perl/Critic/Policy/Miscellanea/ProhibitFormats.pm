#######################################################################
#      $URL$
#     $Date: 2006-02-02 18:38:30 -0800 (Thu, 02 Feb 2006) $
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Policy::Miscellanea::ProhibitFormats;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc = q{Format used};
my $expl = [ 449 ];

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM }
sub applies_to { return 'PPI::Token::Word' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    return if is_hash_key( $elem );
    return if is_method_call( $elem );
    return if is_subroutine_name( $elem );

    if ( $elem eq 'format' ) {
        return $self->violation( $desc, $expl, $elem );
    }

    return;  #ok!
}


1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Miscellanea::ProhibitFormats

=head1 DESCRIPTION

Formats are one of the oldest features of Perl.  Unfortunately, they suffer
from several limitations.  Formats are static and cannot be easily defined
at run time.  Also, formats depend on several obscure global variables.

For more modern reporting tools, consider using one of the template frameworks
like L<Template> or try the L<Perl6::Form> module.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
