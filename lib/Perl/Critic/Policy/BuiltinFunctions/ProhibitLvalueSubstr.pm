##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.20;

#----------------------------------------------------------------------------

my $desc = q{Lvalue form of "substr" used};
my $expl = [ 165 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_MEDIUM     }
sub default_themes    { return qw( unreliable pbp ) }
sub applies_to       { return 'PPI::Token::Word'   }

#----------------------------------------------------------------------------

sub violates {
    my ($self, $elem, undef) = @_;

    return if $elem ne 'substr';
    return if ! is_function_call($elem);

    my $sib = $elem;
    while ($sib = $sib->snext_sibling()) {
        if ( $sib->isa( 'PPI::Token::Operator') && $sib eq q{=} ) {
            return $self->violation( $desc, $expl, $sib );
        }
    }
    return; #ok!
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitLvalueSubstr

=head1 DESCRIPTION

Conway discourages the use of C<substr()> as an lvalue, instead
recommending that the 4-argument version of C<substr()> be used instead.

  substr($something, 1, 2) = $newvalue;     # not ok
  substr($something, 1, 2, $newvalue);      # ok

=head1 AUTHOR

Graham TerMarsch <graham@howlingfrog.com>

=head1 COPYRIGHT

Copyright (C) 2005-2006 Graham TerMarsch.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
