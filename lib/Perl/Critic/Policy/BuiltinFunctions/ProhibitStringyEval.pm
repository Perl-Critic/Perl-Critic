##################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
##################################################################

package Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval;

use strict;
use warnings;
use Perl::Critic::Utils;
use base 'Perl::Critic::Policy';

our $VERSION = 0.21;

#----------------------------------------------------------------------------

my $desc = q{Expression form of "eval"};
my $expl = [ 161 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_HIGHEST  }
sub default_themes    { return qw( pbp danger )   }
sub applies_to       { return 'PPI::Token::Word' }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if $elem ne 'eval';
    return if ! is_function_call($elem);

    my $arg = _first_arg($elem);
    return if !$arg;
    return if $arg->isa('PPI::Structure::Block');

    return $self->violation( $desc, $expl, $elem );
}

sub _first_arg {
    my $elem = shift;

    my $arg = $elem->snext_sibling();
    while ($arg) {
        last if !$arg->isa('PPI::Structure::List') && !$arg->isa('PPI::Statement');
        $arg = $arg->schild(0);
    }
    return $arg;
}

1;

__END__

#------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::BuiltinFunctions::ProhibitStringyEval

=head1 DESCRIPTION

The string form of C<eval> is recompiled every time it is executed,
whereas the block form is only compiled once.  Also, the string form
doesn't give compile-time warnings.

  eval "print $foo";        #not ok
  eval {print $foo};        #ok

=head1 SEE ALSO

L<Perl::Critic::Policy::ControlStrucutres::RequireBlockGrep>

L<Perl::Critic::Policy::ControlStrucutres::RequireBlockMap>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
