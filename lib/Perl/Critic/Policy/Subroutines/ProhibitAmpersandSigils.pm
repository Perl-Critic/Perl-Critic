#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.14';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------

my $desc  = q{Subroutine called with '&' sigil};
my $expl  = [ 175 ];

#---------------------------------------------------------------------------

sub default_severity  { return $SEVERITY_LOW }
sub applies_to { return 'PPI::Token::Symbol' }

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    if ( my $psib = $elem->previous_sibling() ) {
        #Sigil is allowed if taking a reference, e.g. "\&my_sub"
        return if $psib->isa('PPI::Token::Cast') && $psib eq q{\\};
    }

    if ( $elem =~ m{\A [&] }mx ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }

    return;    #ok!
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::Subroutines::ProhibitAmpersandSigils

=head1 DESCRIPTION

Since Perl 5, the ampersand sigil is completely optional when invoking
subroutines.  And it's easily confsued with the bitwise 'and' operator.

  @result = &some_function(); #Not ok
  @result = some_function();  #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
