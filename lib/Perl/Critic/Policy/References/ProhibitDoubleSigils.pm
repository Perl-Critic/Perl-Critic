#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::References::ProhibitDoubleSigils;

use strict;
use warnings;
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.13_05';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

my $desc = q{Double-sigil dereference};
my $expl = [ 228 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW }
sub applies_to { return 'PPI::Token::Cast' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;
    return if $elem eq q{\\};

    my $sib = $elem->snext_sibling || return;
    if ( ! $sib->isa('PPI::Structure::Block') ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $elem, $sev );
    }
    return; #ok!
}

1;

__END__

#----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::References::ProhibitDoubleSigils

=head1 DESCRIPTION

When dereferencing a reference, put braces around the reference to
separate the sigils.  Especially for newbies, the braces eliminate any
potential confusion about the relative precedence of the sigils.

  push @$array_ref, 'foo', 'bar', 'baz';      #not ok
  push @{ $array_ref }, 'foo', 'bar', 'baz';  #ok

  foreach ( keys %$hash_ref ){}               #not ok
  foreach ( keys %{ $hash_ref } ){}           #ok

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
